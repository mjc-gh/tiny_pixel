# frozen_string_literal: true

class AggregationJob < ApplicationJob
  queue_as :aggregation

  def perform(lookback_hours: AggregationService::LOOKBACK_HOURS)
    AggregationService.aggregate_all_sites(lookback_hours: lookback_hours)
  end
end
