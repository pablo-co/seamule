require 'redis-namespace'

module SeaMule
  class Backend
    attr_reader :store

    attr_reader :logger

    def initialize(store, logger)
      @store = store
      @logger = logger
    end

    def self.connect(server)
      case server
        when String
          redis = connect_to(server)
          Redis::Namespace.new(:seamule, redis: redis)
        when Hash
          Redis::Namespace.new(:seamule, redis: Redis.new(server))
        else
          raise ArgumentError, "Invalid Server: #{server.inspect}"
      end
    end

    def self.connect_to(server)
      Redis.connect(url: server, :thread_safe => true)
    end

    MAX_RECONNECT_ATTEMPTS = 3

    def reconnect
      store.client.reconnect
    rescue Redis::BaseConnectionError
      tries ||= 0
      if (tries += 1) < MAX_RECONNECT_ATTEMPTS
        logger.info "Error reconnecting to Redis; retrying"
        Kernel.sleep(tries)
        retry
      else
        logger.info "Error reconnecting to Redis; quitting"
        raise ConnectionError
      end
    end
  end
end