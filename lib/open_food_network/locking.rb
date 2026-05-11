# frozen_string_literal: true

module OpenFoodNetwork::Locking
  # http://rhnh.net/2010/06/30/acts-as-list-will-break-in-production
  def with_isolation_level_serializable
    transaction do
      connection.execute("SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL SERIALIZABLE")
      yield
    end
  end
end

ActiveSupport.on_load(:active_record) { extend(OpenFoodNetwork::Locking) }
