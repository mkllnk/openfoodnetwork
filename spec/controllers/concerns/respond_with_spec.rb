# frozen_string_literal: true

RSpec.describe RespondWith do
  subject { ActionController::Base.new.extend(RespondWith) }

  it "tells developers how to use it" do
    expect { subject.respond_with(nil) }
      .to(raise_error(/you need to declare the formats/))
  end
end
