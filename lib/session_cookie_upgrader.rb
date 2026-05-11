# frozen_string_literal: true

# Create a new cookie without a domain (dot prefix), making it 'host-only'
# A new cookie name is required, because it seems you can't update the domain of an existing cookie.
# Attributes must exactly match the current cookies.
class SessionCookieUpgrader
  def initialize(app, options = {})
    @app = app
    @options = options
  end

  def call(env)
    request = ::Rack::Request.new(env)
    cookies = request.cookies
    old_key = @options[:old_key]
    new_key = @options[:new_key]
    attrs = @options[:attrs]

    # Set the session id for this request from the old session cookie (if present)
    # This must be done before @app.call(env) or a new session will be initialized
    cookies[new_key] = cookies[old_key] if cookies[old_key]

    status, headers, body = @app.call(env)

    if cookies[old_key]
      # Create new session cookie with pre-existing session id
      Rack::Utils.set_cookie_header!(
        headers,
        new_key,
        {value: cookies[old_key], path: "/", domain: nil, **attrs}
      )

      # Delete old session cookie.
      Rack::Utils.delete_cookie_header!(headers, old_key, domain: ".#{@options[:domain]}", **attrs)
    end

    [status, headers, body]
  end
end
