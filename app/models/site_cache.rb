# frozen_string_literal: true

class SiteCache
  STORE = ActiveSupport::Cache::MemoryStore.new(expires_in: 5.minutes, size: 1.megabyte.to_i)

  class << self
    delegate :clear, to: :store

    def [](property_id)
      STORE.fetch "site:#{property_id}" do
        Site.find_by(property_id:)
      end
    end

    def invalidate(property_id)
      STORE.delete("site:#{property_id}")
    end

    private

    def store
      STORE
    end
  end
end
