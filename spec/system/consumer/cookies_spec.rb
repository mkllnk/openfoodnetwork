# frozen_string_literal: true

require "system_helper"

RSpec.describe "Cookies", caching: true do
  describe "policy page" do
    # keeps config unchanged
    around do |example|
      original_matomo_config = Spree::Config[:cookies_policy_matomo_section]
      original_matomo_url_config = Spree::Config[:matomo_url]
      example.run
      Spree::Config[:cookies_policy_matomo_section] = original_matomo_config
      Spree::Config[:matomo_url] = original_matomo_url_config
    end

    scenario("shows session_id cookies description with correct instance domain") do
      visit("/#/policies/cookies")
      expect(page).to(
        have_content("_ofn_session_id")
          .and(have_content("127.0.0.1"))
      )
    end

    context("without Matomo section configured") do
      scenario("does not show Matomo cookies details and does not show Matomo optout text") do
        Spree::Config[:cookies_policy_matomo_section] = false
        visit_cookies_policy_page
        expect(page).not_to(have_content(matomo_description_text))
        expect(page).not_to(have_content(matomo_opt_out_iframe))
      end
    end

    context("with Matomo section configured") do
      before do
        Spree::Config[:cookies_policy_matomo_section] = true
      end

      scenario("shows Matomo cookies details") do
        visit_cookies_policy_page
        expect(page).to(have_content(matomo_description_text))
      end

      context("with Matomo integration enabled") do
        scenario("shows Matomo optout iframe") do
          Spree::Config[:matomo_url] = "https://0000.innocraft.cloud/"
          visit_cookies_policy_page
          expect(page).to(have_content(matomo_opt_out_iframe))
          expect(page).to(have_selector("iframe"))
        end
      end

      context("with Matomo integration disabled") do
        scenario("does not show Matomo iframe") do
          Spree::Config[:cookies_policy_matomo_section] = true
          Spree::Config[:matomo_url] = ""
          visit_cookies_policy_page
          expect(page).not_to(have_content(matomo_opt_out_iframe))
          expect(page).not_to(have_selector("iframe"))
        end
      end
    end
  end

  def visit_cookies_policy_page
    visit("/#/policies/cookies")
  end

  def matomo_description_text
    "Matomo first party cookies to collect statistics."
  end

  def matomo_opt_out_iframe
    "Do you want to opt-out of Matomo analytics? We don’t collect any personal data, and Matomo " \
      "helps us to improve our service, but we respect your choice :-)"
  end
end
