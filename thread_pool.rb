#!/usr/bin/env ruby

module ThreadPool
  class Worker
    attr_accessor :queue, :thread
    def initialize(queue, mutex, cond)
      @mutex = mutex
      @cond = cond
      self.queue = queue
      self.thread = start_worker_thread
    end

    def start_worker_thread
      Thread.new do
        loop do
          queue.pop.call
          @mutex.synchronize do
            if queue.empty?
              @cond.signal
            end
          end
        end
      end
    end
  end

  class Pool
    attr_accessor :num_workers, :queue, :workers

    def initialize(num_workers)
      self.queue = Queue.new
      self.num_workers = num_workers
      @empty_mutex = Mutex.new
      @empty_cond = ConditionVariable.new

      self.workers = num_workers.times.map do
        ThreadPool::Worker.new(queue, @empty_mutex, @empty_cond)
      end
    end

    def queue_size
      queue.size
    end

    def add_task(&block)
      queue.push(block)
    end

    def wait
      @empty_mutex.synchronize do
        return if queue.empty?
        @empty_cond.wait(@empty_mutex)
      end
    end
  end
end
