# frozen_string_literal: true

# Fetch resources from the web and import them
#
# The importer keeps references to all imported objects and updates them
# progressively with each retrieved document.
#
# We may want to integrate this with the parent class.
class WebImporter < DataFoodConsortium::Connector::Importer
  # The user to authenticate requests with.
  def initialize(user)
    super()
    @web = DfcRequest.new(user)
    @subjects = {}
  end

  # Override:
  # - not resetting @subjects
  # - fetching the json from a URL
  def import(url)
    json = @web.call(url)
    graph = parse_rdf(json)
    build_missing_subjects(graph)
    apply_statements(graph)

    if @subjects.size > 1
      @subjects.values
    else
      @subjects.values.first
    end
  end

  # Replacement of build_subjects
  def build_missing_subjects(graph)
    graph.query({ predicate: RDF.type }).each do |statement|
      @subjects[statement.subject] ||= build_subject(statement)
    end
  end
end
