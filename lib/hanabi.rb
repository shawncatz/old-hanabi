require 'hanabi/version'
require 'hanabi/client'
require 'hanabi/config'
require 'hanabi/inventory'
require 'hanabi/log'
require 'hanabi/message'

require 'amqp'

module Hanabi
  class << self
    def setup(options)
      config_file = options[:config]
      inventory_file = options[:inventory]
      Hanabi::Config.load(config_file)
      Hanabi::Inventory.load(inventory_file)
      @config = Hanabi::Config.instance
      @inventory = Hanabi::Inventory.instance

      @log = Hanabi::Log.new(:info, STDOUT)
      @log.debug('setup complete')
      @setup = true
    end

    def log
      @log
    end

    def config
      @config
    end

    def inventory
      @inventory
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
