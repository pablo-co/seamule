require 'redis'
require 'mono_logger'

require 'seamule/version'
require 'seamule/backend'
require 'seamule/encoder'
require 'seamule/json_encoder'
require 'seamule/job'
require 'seamule/server'
require 'seamule/queue'

require 'forwardable'

module SeaMule
  extend Forwardable
  extend self

  QUEUES = %w(pending active done).freeze

  DEFAULT_QUEUE = QUEUES.first.freeze

  attr_reader :redis

  attr_writer :coder

  attr_accessor :logger

  def encode(object)
    coder.encode(object)
  end

  def decode(object)
    coder.decode(object)
  end

  def backend
    @backend ||= Backend.new(@redis, SeaMule.logger)
  end

  def redis=(server)
    @redis = Backend.connect(server) unless server.nil?
    @backend = Backend.new(@redis, SeaMule.logger)
    create_queues
    @redis
  end

  def create_queues
    @queues = {}
    QUEUES.each do |queue_name|
      @queues[queue_name] = SeaMule::Queue.new(queue_name, @redis)
    end
  end

  def redis_id
    @redis_id
  end

  def coder
    @coder ||= JsonEncoder.new
  end

  def to_s
    "Resque Backend connected to #{redis_id}"
  end

  def push(queue, item)
    queue(queue) << item
  end

  def pop(queue, id = nil)
    queue(queue).pop(id)
  end

  def pop_and_push(from_queue, to_queue)
    job = pop(from_queue)
    push(to_queue, job) if job
    job
  end

  def size(queue)
    queue(queue).size
  end

  def queues
    Array(backend.store.smembers(:queues))
  end

  def remove_queue(queue)
    queue(queue).destroy
    @queues.delete(queue.to_s)
  end

  def queue(name)
    @queues[name.to_s]
  end

  def enqueue(klass, payload, meta = nil)
    enqueue_to(queue_from_class(klass), klass, payload, meta)
  end

  def enqueue_to(queue, klass, payload, meta)
    validate(klass, queue)
    Job.create(queue, klass, payload, meta)
  end

  def dequeue(klass, *args)
    Job.destroy(queue_from_class(klass), klass, *args)
  end

  def queued(klass, *args)
    Job.queued(queue_from_class(klass), klass, *args)
  end

  def queue_from_class(klass)
    DEFAULT_QUEUE
  end

  def validate(klass, queue = nil)
    queue ||= queue_from_class(klass)

    unless queue
      raise NoQueueError.new("Jobs must be placed onto a queue. No queue could be inferred for class #{klass}")
    end

    if klass.to_s.empty?
      raise NoClassError.new("Jobs must be given a class.")
    end
  end

  def info
    {
        :pending => pending_queues,
        :processed => Stat[:processed],
        :failed => failed_job_count,
        :servers => [redis_id]
    }
  end

  def pending_queues
    queues.inject(0) { |m, k| m + size(k) }
  end

  def keys
    backend.store.keys('*')
  end
end

SeaMule.logger = MonoLogger.new(STDOUT)