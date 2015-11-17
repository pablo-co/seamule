module SeaMule
  class EncodeException < StandardError; end

  class DecodeException < StandardError; end

  class Encoder
    def encode(object)
      raise EncodeException
    end

    def dump(object)
      encode(object)
    end

    def decode(object)
      raise DecodeException
    end

    def load(object)
      decode(object)
    end
  end
end