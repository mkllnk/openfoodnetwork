# frozen_string_literal: true

require "stripe/oauth"

RSpec.describe StripeAccount do
  describe "deauthorize_and_destroy", :vcr, :stripe_version do
    let!(:enterprise) { create(:enterprise) }
    let(:stripe_user_id) { ENV.fetch("STRIPE_ACCOUNT", nil) }

    let!(:stripe_account) {
      create(:stripe_account, enterprise:, stripe_user_id:)
    }

    context("when the Stripe API disconnect fails") do
      let(:stripe_user_id) { ENV.fetch("STRIPE_ACCOUNT", nil) }

      before { Stripe.client_id = "bogus_client_id" }

      it "destroys the record and notifies Bugsnag" do
        # returns status 401
        # and receives Bugsnag notification
        expect(Bugsnag).to(receive(:notify))
        expect {
          stripe_account.deauthorize_and_destroy
        }
          .to(change { StripeAccount.where(stripe_user_id:).count }.from(1).to(0))
      end
    end

    context("when the Stripe API disconnect succeeds") do
      let!(:connected_account) do
        Stripe::Account.create(
          {
            type: "standard",
            country: "AU",
            email: "jumping.jack@example.com"
          }
        )
      end

      let(:stripe_user_id) { connected_account.id }

      before { Stripe.client_id = ENV.fetch("STRIPE_CLIENT_ID", nil) }

      it "destroys the record" do
        # returns status 200
        # and does not receive Bugsnag notification
        expect(Bugsnag).not_to(receive(:notify))
        expect {
          stripe_account.deauthorize_and_destroy
        }
          .to(
            change {
              StripeAccount.where(stripe_user_id: connected_account.id).count
            }
              .from(1)
              .to(0)
          )
      end
    end

    context("if the account is also associated with another Enterprise") do
      let!(:enterprise2) { create(:enterprise) }
      let(:stripe_user_id) { ENV.fetch("STRIPE_ACCOUNT", nil) }

      before do
        create(:stripe_account, enterprise: enterprise2, stripe_user_id:)
      end

      it "doesn't make a Stripe API disconnection request " do
        expect(Stripe::OAuth).not_to(receive(:deauthorize))
        stripe_account.deauthorize_and_destroy
        expect(StripeAccount.all).not_to(include(stripe_account))
      end
    end
  end
end
