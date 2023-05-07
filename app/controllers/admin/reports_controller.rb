# frozen_string_literal: true

module Admin
  class ReportsController < Spree::Admin::BaseController
    include ActiveStorage::SetCurrent
    include ReportsActions
    helper ReportsHelper

    before_action :authorize_report, only: [:show]

    # Define model class for Can? permissions
    def model_class
      Admin::ReportsController
    end

    def index
      @reports = reports.select do |report_type, _description|
        can? report_type, :report
      end
    end

    def show
      @report = report_class.new(spree_current_user, params, render: render_data?)

      @background_reports = OpenFoodNetwork::FeatureToggle
                              .enabled?(:background_reports, spree_current_user)

      if @background_reports && request.post?
        return background(report_format)
      end

      if params[:report_format].present?
        export_report
      else
        show_report
      end
    rescue Timeout::Error
      render_timeout_error
    end

    private

    def export_report
      send_data @report.render_as(report_format), filename: report_filename
    end

    def show_report
      assign_view_data
      @table = @report.render_as(:html) if render_data?
      render "show"
    end

    def assign_view_data
      @report_type = report_type
      @report_subtypes = report_subtypes
      @report_subtype = report_subtype
      @report_title = report_title
      @rendering_options = rendering_options
      @data = Reporting::FrontendData.new(spree_current_user)
    end

    def render_data?
      request.post?
    end

    def background(format)
      @blob = ReportBlob.create_for_upload_later!(report_filename)

      ReportJob.perform_later(
        report_class, spree_current_user, params, format, @blob, ScopedChannel.for_id(params[:uuid])
      )

      render cable_ready: cable_car.
        inner_html(
          selector: "#report-table",
          html: render_to_string(partial: "admin/reports/loading")
        ).scroll_into_view(
          selector: "#report-table",
          block: "start"
        )
    end

    def render_timeout_error
      assign_view_data
      if @blob
        @error = ".report_taking_longer_html"
        @error_url = @blob.expiring_service_url
      else
        @error = ".report_taking_longer"
        @error_url = ""
      end
      render "show"
    end
  end
end
