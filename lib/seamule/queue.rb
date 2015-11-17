require 'redis'

module SeaMule
  class Queue
    attr_reader :name, :redis_name

    def initialize(name, redis)
      super()
      @name = name
      @redis_name = "queue:#{@name}"
      @redis = redis
      @redis.sadd(:queues, @name)
    end

    def push(object)
      begin
        encoded_object = SeaMule.encode(object)
      rescue SeaMule::EncodeException => e
        SeaMule.logger.error "Invalid UTF-8 character in job: #{e.message}"
        return
      end

      @redis.rpush(@redis_name, encoded_object)
    end

    alias :<< :push

    def pop(id = nil)
      SeaMule.decode(@redis.lpop(@redis_name))
    end

    def length
      @redis.llen(@redis_name)
    end

    alias :size :length

    def empty?
      size == 0
    end
  end
end