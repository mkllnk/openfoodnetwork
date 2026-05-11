# frozen_string_literal: true

# This is meant to be used with request spec, it allows interacting with session.
# Inspired from: https://stackoverflow.com/questions/75655990/set-session-in-rspec-with-rails-7-api
# Usage:
#  describe "your test" do
#   include_context "session helper"
#
#   before { session_hash[:order_id] = order.id }
#
#   it "does something involving session" do
#     ...
#   end
# end
#
shared_context("session helper") do
  let(:session_hash) { {} }

  before do
    session_double = instance_double(
      ActionDispatch::Request::Session,
      enabled?: true,
      loaded?: false
    )

    allow(session_double).to(receive(:[])) do |key|
      session_hash[key]
    end

    allow(session_double).to(receive(:[]=)) do |key, value|
      session_hash[key] = value
    end

    allow(session_double).to(receive(:delete)) do |key|
      session_hash.delete(key)
    end

    allow(session_double).to(receive(:clear)) do |_key|
      session_hash.clear
    end

    allow(session_double).to(receive(:fetch)) do |key|
      session_hash.fetch(key)
    end

    allow(session_double).to(receive(:key?)) do |key|
      session_hash.key?(key)
    end

    allow_any_instance_of(ActionDispatch::Request).to(receive(:session).and_return(session_double))
  end
end
