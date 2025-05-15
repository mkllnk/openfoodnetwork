# frozen_string_literal: true

# Authorisations of a user allowing a platform to access to data.
class DfcPermission < ApplicationRecord
  # Issue: https://git.startinblox.com/projets/projets-clients/open-food-network/data-permissioning-module/-/issues/35
  # Example: https://data-server.cqcm.startinblox.com/scopes
  SCOPES = [
    {
      'dfc-t:scope': "ReadEnterprise",
      'dfc-t:name': "Read enterprise data",
      'dfc-t:hasDescription':
        "This scope allows portals to access the associated producers enterprise data",
    },
    {
      'dfc-t:scope': "ReadProducts",
      'dfc-t:name': "Read enterprise products",
      'dfc-t:hasDescription':
        "This scope allows portals to access the associated producers enterprise products",
    },
  ].freeze
  SCOPE_KEYS = SCOPES.pluck('dfc-t:scope').freeze

  belongs_to :user, class_name: "Spree::User"
  belongs_to :enterprise

  validates :grantee, presence: true
  validates :scope, presence: true, inclusion: { in: SCOPE_KEYS }
end
