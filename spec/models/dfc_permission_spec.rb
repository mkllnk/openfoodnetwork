# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DfcPermission do
  it { is_expected.to belong_to :user }
  it { is_expected.to belong_to :enterprise }
  it { is_expected.to validate_presence_of :grantee }
  it { is_expected.to validate_presence_of :scope }
  it {
    is_expected.to validate_inclusion_of(:scope)
      .in_array(%w[ReadEnterprise ReadProducts ReadOrders])
  }
end
