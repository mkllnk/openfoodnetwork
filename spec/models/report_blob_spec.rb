# frozen_string_literal: false

require 'spec_helper'

RSpec.describe ReportBlob, type: :model do
  it "preserves UTF-8 content" do
    content = "This works. ✓"

    expect do
      blob = ReportBlob.create!("customers.html", content)
      content = blob.result
    end.not_to change { content.encoding }.from(Encoding::UTF_8)
  end

  it "can be created first and filled later" do
    expect(blob.checksum).to eq ""
  end
end
