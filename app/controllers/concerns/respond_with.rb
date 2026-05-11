# frozen_string_literal: true

require "spree/responder"

module RespondWith
  extend ActiveSupport::Concern

  def respond_with(*resources, &)
    if self.class.mimes_for_respond_to.empty?
      raise(
        "In order to use respond_with, first you need to declare the formats your " \
          "controller responds to in the class level"
      )
    end

    return unless (collector = retrieve_collector_from_mimes(&))

    options = resources.size == 1 ? {} : resources.extract_options!

    # Fix spree issues #3531 and #2210 (patch provided by leiyangyou)
    if (defined_response = collector.response) &&
        !ApplicationController.spree_responders[self.class.to_s.to_sym].try(:[], action_name.to_sym)

      defined_response.call
    else
      # The action name is needed for processing
      options[:action_name] = action_name.to_sym
      # If responder is not specified then pass in Spree::Responder
      (options.delete(:responder) || Spree::Responder).call(self, resources, options)
    end
  end

  private

  def retrieve_collector_from_mimes(mimes = nil, &block)
    mimes ||= collect_mimes_from_class_level
    collector = ActionController::Base::Collector.new(mimes, request.variant)
    block.call(collector) if block_given?
    format = collector.negotiate_format(request)

    raise ActionController::UnknownFormat unless format

    _process_format(format)
    collector
  end
end
