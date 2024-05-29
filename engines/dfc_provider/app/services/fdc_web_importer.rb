# frozen_string_literal: true

# Fetch resources from the FDC API
#
class FdcWebImporter < WebImporter
  # The user to authenticate requests with.
  def initialize(user)
    super(user)
    @web = FdcRequest.new(user)
  end
end
