require 'hanabi/version'
require 'hanabi/client'
require 'hanabi/config'
require 'hanabi/inventory'
require 'hanabi/message'

require 'amqp'

module Hanabi
  class << self
    def setup(options)
      config = options[:config]
      inventory = options[:inventory]
      Hanabi::Config.load(config)
      Hanabi::Inventory.load(inventory)
    end

    def config
      Hanabi::Config.instance
    end

    def inventory
      Hanabi::Inventory.instance
    end

    def parse(data)
      Hanabi::Message.parse(data)
    end

    def message(data, options={})
      msg = Hanabi::Message.new(data).to_s
      host = options[:host] || config.host || '127.0.0.1'
      port = options[:port] || config.port || 5672
      AMQP.start("amqp:://#{host}:#{port}") do |connection|
        channel = AMQP::Channel.new(connection)
        exchange = channel.fanout('hanabi')
        exchange.publish(msg, nowait: false) do
          connection.close { EventMachine.stop { } }
        end
      end
    end
  end
end
