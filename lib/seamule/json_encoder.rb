require 'seamule/encoder'
require 'multi_json'

module SeaMule
  class JsonEncoder < Encoder

    def encode(object)
      JSON.dump(object)
    end

    def decode(object)
      return unless object

      begin
        JSON.load(object)
      rescue ::JSON::JSONError => e
        raise SeaMule::DecodeException, e.message, e.backtrace
      end
    end
  end
end