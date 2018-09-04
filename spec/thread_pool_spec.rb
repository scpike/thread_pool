require 'spec_helper'
require 'thread_pool'

RSpec.describe "ThreadPool" do
  it "initializes with number of threads" do
    pool = ThreadPool::Pool.new(10)
    expect(pool.num_workers).to eq(10)
  end

  it "adds tasks to a pool" do
    pool = ThreadPool::Pool.new(1)
    pool.add_task { sleep(0.01) }
    expect(pool.queue_size).to eq(1)
  end

  it "does work in one thread" do
    pool = ThreadPool::Pool.new(1)
    x = []
    y = []
    10.times.with_index do |i|
      y[i] = i
      pool.add_task { x[i] = i }
    end
    pool.wait
    expect(x).to eq(y)
  end

  it "does work in a bunch of threads" do
    pool = ThreadPool::Pool.new(20)
    x = []
    y = []
    100.times.with_index do |i|
      y[i] = i
      pool.add_task { x[i] = i }
    end
    pool.wait
    expect(x).to eq(y)
  end

  it "does work and waits for queue to empty" do
    pool = ThreadPool::Pool.new(3)
    x = []
    y = []
    5.times.with_index do |i|
      y[i] = i
      pool.add_task do
        sleep(1) if i == 3
        x[i] = i
      end
    end
    pool.wait
    expect(x).to eq(y)
  end

  it "does work in a few threads" do
    pool = ThreadPool::Pool.new(1)
    x = 0
    pool.add_task { x += 1 }
    pool.wait
    expect(x).to eq(1)
  end
end
