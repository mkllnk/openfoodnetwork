# frozen_string_literal: true

require "yaml"

RSpec.describe "Flatpickr date format strings in locale files" do
  def locale_files
    Rails.root.glob("config/locales/*.yml")
  end

  def date_picker_formats(file)
    yaml = YAML.safe_load_file(file, permitted_classes: [Symbol])
    return {} unless yaml

    root = yaml.values.first
    return {} unless root.is_a?(Hash)

    date_picker = root.dig("spree", "date_picker")
    return {} unless date_picker.is_a?(Hash)

    {
      date: date_picker["flatpickr_date_format"],
      datetime: date_picker["flatpickr_datetime_format"]
    }.compact
  end

  it "locale files are present" do
    expect(locale_files).not_to(be_empty)
  end

  shared_examples("valid flatpickr format") do |format_key|
    it "#{format_key} is a valid flatpickr format string in all locales" do
      # Valid flatpickr format token characters (single-character tokens and common separators).
      # See: https://flatpickr.js.org/formatting/
      # Tokens: Z D F G H J K M S U W Y d h i j l m n s u w y
      # Separators: . - / : (space) — Escape: \ (makes the next character literal)
      valid_format_regex = %r{\A[ZDFGHJKMSUWYdhijlmnsuwy.\-/: \\]+\z}

      # Known locales with incorrect (translator-provided) format strings.
      # These should be fixed in Transifex and removed as they are corrected.
      # See: https://github.com/openfoodfoundation/openfoodnetwork/issues/13360
      known_broken_locales = %w[cy el eu ko pa sr tr uk]

      invalid = []

      locale_files.each do |file|
        locale_code = File.basename(file, ".yml")
        if known_broken_locales.include?(locale_code)
          pending("locale is known to have a broken date/time format")
        end

        formats = date_picker_formats(file)
        format = formats[format_key]
        next unless format

        invalid << "#{locale_code}: '#{format}'" unless format.match?(valid_format_regex)
      end

      expect(invalid)
        .to(
          be_empty,
          "Invalid #{format_key} found in locale files:\n" \
            "#{invalid.join("\n")}\n\n" \
            "Flatpickr format strings use single-character tokens (e.g. Y=year, m=month).\n" \
            "They must not be translated. Valid tokens: ZDFGHJKMSUWYdhijlmnsuwy\n" \
            "Valid separators: . - / : space\n" \
            "See: https://flatpickr.js.org/formatting/"
        )
    end
  end

  include_examples("valid flatpickr format", :date)
  include_examples("valid flatpickr format", :datetime)

  describe "Finnish locale specifically" do
    it "has valid flatpickr_date_format" do
      formats = date_picker_formats(Rails.root.join("config/locales/fi.yml"))
      expect(formats[:date]).to(eq("d.m.Y"))
    end

    it "has valid flatpickr_datetime_format" do
      formats = date_picker_formats(Rails.root.join("config/locales/fi.yml"))
      expect(formats[:datetime]).to(eq("d.m.Y H:i"))
    end
  end
end
