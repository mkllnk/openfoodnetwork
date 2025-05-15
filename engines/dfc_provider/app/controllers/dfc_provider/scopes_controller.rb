# frozen_string_literal: true

module DfcProvider
  class ScopesController < DfcProvider::ApplicationController
    before_action :check_enterprise

    def create
      grantee = JSON.parse(request.body.read).fetch("portalId")
      DfcPermission.create!(
        user: current_user,
        enterprise: current_enterprise,
        scope: params[:id],
        grantee:,
      )

      response = { message: "Scope association added successfully" }
      render json: response.to_json, status: :created
    end

    def show
      grantees = DfcPermission.where(
        user: current_user,
        enterprise: current_enterprise,
        scope: params[:id],
      ).pluck(:grantee)

      response = {
        '@id': enterprise_scope_url(params[:enterprise_id], params[:id]),
        description: "Scopes granted to the following platforms.",
        portals: grantees,
      }
      render json: response.to_json
    end

    def destroy
      grantee = JSON.parse(request.body.read).fetch("portalId")

      DfcPermission.where(
        user: current_user,
        enterprise: current_enterprise,
        scope: params[:id],
        grantee:,
      ).delete_all

      response = { message: "Scope association removed successfully" }
      render json: response.to_json
    end
  end
end
