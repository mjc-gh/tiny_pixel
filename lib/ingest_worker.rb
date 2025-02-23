# frozen_string_literal: true

class IngestWorker
  include Singleton

  def initialize
    @queue = Concurrent::LockFreeQueue.new
    @task = Concurrent::TimerTask.new(execution_interval: 15) do
      message = @queue.pop

      p message
    end

    # @task.add_observer IngestWorkerObserver
  end

  def push(request)
    @queue.push request.raw_body

    nil
  end

  attr_reader :queue

  # delegate :execute, :shutdown, to: @task
end
