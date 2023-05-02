# frozen_string_literal: true

class SessionChannel < ApplicationCable::Channel
  class << self
    def for_request(request)
      "session:#{request.session.id}"
    end
  end

  def subscribed
    return reject if session_id.nil?

    stream_from "session:#{session_id}"
  end
end
