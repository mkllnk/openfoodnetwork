# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rails::Configuration do
  let(:config) { Rails.configuration }

  describe "open_food_network" do
    let(:subject) { config.open_food_network }

    it "loads app specific settings per domain" do
      expect(subject[:open_id_servers])
        .to include "https://login.lescommuns.org/auth/realms/data-food-consortium"
    end
  end
end
