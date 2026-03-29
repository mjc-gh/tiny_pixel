# frozen_string_literal: true

class SaltCyclingJob < ApplicationJob
  queue_as :default

  def perform
    Site.cycle_stale_salts!
  end
end
