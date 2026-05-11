# frozen_string_literal: true

class CopySubjectOnSemanticLinks < ActiveRecord::Migration[7.0]
  def up
    execute(
      <<~SQL
        UPDATE semantic_links SET
          subject_id   = variant_id,
          subject_type = 'Spree::Variant'
      SQL
        .squish
    )
  end
end
