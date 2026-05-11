# frozen_string_literal: true

require_relative "../../db/migrate/20240510033206_sanitize_enterprise_long_description"

RSpec.describe SanitizeEnterpriseLongDescription do
  describe "#up" do
    let!(:enterprise_nil_desc) { create(:enterprise, long_description: nil) }
    let!(:enterprise_empty_desc) { create(:enterprise, long_description: "") }
    let!(:enterprise_normal) { create(:enterprise, long_description: normal_desc) }
    let!(:enterprise_bad) {
      # The attribute is sanitised at assignment. So we need to inject into the
      # database differently:
      create(:enterprise).tap do |enterprise|
        enterprise.update_columns(long_description: bad_desc)
      end
    }
    let(:normal_desc) {
      <<~HTML
        <p>𝐂𝐎̛𝐌 𝐓𝐀̂́𝐌 𝐂𝐇𝐔́ 𝐁𝐄́ is now available in Melbourne, everyone. 😂<br>
        <>>> The story is this is a person who loves to eat...</p>
      HTML
        .squish
    }
    let(:normal_desc_sanitised) {
      <<~HTML
        <p>𝐂𝐎̛𝐌 𝐓𝐀̂́𝐌 𝐂𝐇𝐔́ 𝐁𝐄́ is now available in Melbourne, everyone. 😂<br>
        &lt;&gt;&gt;&gt; The story is this is a person who loves to eat...</p>
      HTML
        .squish
    }
    let(:bad_desc) {
      <<~HTML
        <p data-controller="load->payMe">Fred Farmer is a certified organic
        <script>alert("Gotcha!")</script>...</p>
      HTML
        .squish
    }
    let(:bad_desc_sanitised) {
      "<p>Fred Farmer is a certified organic alert(\"Gotcha!\")...</p>"
    }

    it "sanitises the long description" do
      expect { subject.up }.to(
        change {
          enterprise_bad.reload.attributes["long_description"]
        }
          .from(bad_desc)
          .to(bad_desc_sanitised)
      )

      expect(enterprise_nil_desc.reload.long_description).to(eq(nil))
      expect(enterprise_empty_desc.reload.long_description).to(eq(""))
      expect(enterprise_normal.reload.attributes["long_description"])
        .to(eq(normal_desc_sanitised))
    end
  end
end
