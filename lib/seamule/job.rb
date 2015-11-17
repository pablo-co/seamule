require 'json'

module SeaMule
  class Job
    attr_reader :id

    attr_reader :callback_class_name

    attr_reader :meta

    attr_reader :queue

    attr_reader :payload

    attr_accessor :result

    def initialize(queue, content)
      @queue = queue
      @payload = content['payload']
      @meta = content['meta']
      @id = content['id']
      @callback_class_name = content['class']
    end

    def self.create(queue, klass, payload, meta)
      SeaMule.validate(klass, queue)
      puts payload.inspect
      SeaMule.push(queue, class: klass.to_s, payload: payload, meta: meta, id: SecureRandom.hex)
    end

    def self.destroy(queue, klass: nil, payload: nil, id: nil)
      coder = SeaMule.coder
      redis = SeaMule.backend.store
      klass = klass.to_s

      destroyed_count = process_queue(queue, coder, redis, klass, payload, id) do |decoded, new_queue, temp_queue, requeue_queue|
        redis.del(temp_queue).to_i
      end

      destroyed_count.inject(0, :+)
    end

    def self.queued(queue, klass: nil, payload: nil, id: nil)
      coder = SeaMule.coder
      redis = SeaMule.backend.store
      klass = klass.to_s

      jobs = process_queue(queue, coder, redis, klass, payload, id) do |decoded, _new_queue, temp_queue, requeue_queue|
        redis.rpoplpush(temp_queue, requeue_queue)
        new(queue, decoded)
      end

      jobs
    end

    def self.reserve(queue)
      if payload = SeaMule.pop(queue)
        new(queue, payload)
      end
    end

    def perform
      object = callback_class.new
      object.perform(id, meta, payload, result)
    end

    def callback_class
      @callback_class ||= callback_class_name.to_s.constantize
    end

    def to_h
      {
          :queue => queue,
          :run_at => Time.now.utc.iso8601,
          :payload => payload
      }
    end

    def recreate
      self.class.create(queue, callback_class, payload, meta)
    end

    def inspect
      "(Job{#{@queue}} | #{@callback_class_name} | #{@meta.inspect} | #{@payload.inspect})"
    end


    def ==(other)
      queue == other.queue &&
          callback_class == other.callback_class &&
          args == other.args
    end

    protected

    def self.process_queue(queue, coder, redis, klass, payload, id)
      return_array = []
      new_queue = "queue:#{queue}"
      temp_queue = "queue:#{queue}:temp:#{Time.now.to_i}"
      requeue_queue = "#{temp_queue}:requeue"

      while string = redis.rpoplpush(new_queue, temp_queue)
        decoded = coder.decode(string)
        if decoded['id'] == id || (decoded['class'] == klass && (payload.empty? || decoded['payload'] == payload))
          return_array.unshift(yield decoded, new_queue, temp_queue, requeue_queue)
        else
          redis.rpoplpush(temp_queue, requeue_queue)
        end
      end
      push_queue(redis, requeue_queue, new_queue)

      return_array
    end

    def self.push_queue(redis, requeue_queue, queue)
      loop { redis.rpoplpush(requeue_queue, queue) or break }
    end

  end
end