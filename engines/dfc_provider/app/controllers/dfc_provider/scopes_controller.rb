# frozen_string_literal: true

module DfcProvider
  class ScopesController < DfcProvider::ApplicationController
    before_action :check_enterprise

    def create
      # TODO
      # platform_id = JSON.parse(request.body).fetch("portalId")
      # Create scope entry.

      response = { message: "Scope association added successfully" }
      render json: response.to_json, status: :created
    end

    def show
      response = {
        '@id': enterprise_scope_url(params[:enterprise_id], params[:id]),
        description: "Scopes granted to the following platforms.",
        portals: [], # TODO: list scopes
      }
      render json: response.to_json
    end

    def destroy
      # TODO
      # platform_id = JSON.parse(request.body).fetch("portalId")
      # Destroy scope entry.

      response = { message: "Scope association removed successfully" }
      render json: response.to_json
    end
  end
end
