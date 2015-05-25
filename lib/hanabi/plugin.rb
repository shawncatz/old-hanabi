module Hanabi
  module Plugin
    class Base
      def initialize

      end

      protected

      def channel
        Hanabi.channel
      end

      def queue
        Hanabi.queue
      end

      def exchange
        Hanabi.exchange
      end
    end
  end
end