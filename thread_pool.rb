#!/usr/bin/env ruby

module ThreadPool
  class Worker
    attr_accessor :queue, :thread, :working
    def initialize(queue, mutex, cond)
      @parent_mutex = mutex
      @cond = cond
      self.working = false
      @my_mutex = Mutex.new
      @my_cond = ConditionVariable.new
      self.queue = queue
      self.thread = start_worker_thread
    end

    def shutdown
      @my_mutex.synchronize do
        @shutdown = true
      end
    end

    def start_worker_thread
      Thread.new do
        loop do
          task = queue.pop
          @my_mutex.synchronize do
            self.working = true
            task.call
            self.working = false
            break if @shutdown
          end
          @parent_mutex.synchronize do
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

    def join_workers
      workers.each { |w| w.thread.join }
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
        workers.each { |w| w.shutdown }
      end
    end
  end
end
