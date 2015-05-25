require 'hanabi/ext/deep_struct'
require 'yaml'

module Hanabi
  class Inventory
    class << self
      def load(file)
        file = File.expand_path(file)
        @instance = DeepStruct.new(YAML.load_file(file))
      end
      
      def instance
        raise 'not loaded' unless @instance
        @instance
      end
    end
  end
end
