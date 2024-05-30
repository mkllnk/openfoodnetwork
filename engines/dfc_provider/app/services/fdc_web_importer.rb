# frozen_string_literal: true

# Fetch resources from the FDC API
#
class FdcWebImporter < WebImporter
  # The user to authenticate requests with.
  def initialize(user)
    super(user)
    @web = FdcRequest.new(user)
  end

  # Extract DFC data out of FDC message.
  # Then to the same as the original importer.
  def import(url, field)
    fdc_json = @web.call(url)
    json = JSON.parse(fdc_json)[field]

    # The rest of the method is copied from the original:
    graph = parse_rdf(json)
    build_missing_subjects(graph)
    apply_statements(graph)

    @subjects.values
  end
end
