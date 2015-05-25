require 'json'
require 'hanabi/ext/deep_struct'

module Hanabi
  class Message < DeepStruct
    class << self
      def parse(str)
        new(JSON.parse(str))
      end
    end

    def to_s
      to_h.to_json
    end
  end
end
