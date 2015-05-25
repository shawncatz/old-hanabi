require 'hanabi'
require 'thor'

module Hanabi
  class Command < Thor
    class_option :config, desc: 'override config location', default: '/etc/hanabi/config.yml'
    class_option :inventory, desc: 'override inventory location', default: '/etc/hanabi/inventory.yml'

    desc 'send TYPE COMMAND', 'send command to clients'
    #TODO: headers should be used to manage filters
    # http://rubyamqp.info/articles/working_with_exchanges/#toc_27
    option :filter, desc: 'filters for role, organization, environment, etc'

    def send(command)
      Hanabi.setup(options)
      Hanabi.message({name: 'hanabi.command', command: command}, options)
    end

    desc 'stop', 'stop listening'

    def stop
      Hanabi.setup(options)
      Hanabi.message({name: 'hanabi.control', command: 'stop'}, options)
    end

    desc 'listen', 'connect to rabbit and listen for events'

    def listen
      client = Hanabi::Client.new(options)
      client.periodic(2) do
        pub name: 'hanabi.ping', host: inv.name, inventory: inv.to_h
      end
      client.subscribe('hanabi.message') do |payload|
        puts "subscribed: #{payload.inspect}"
      end
      client.start
    end

    desc 'server', 'connect to rabbit and act as server for reporting'

    def server
      @hosts = {}
      client = Hanabi::Client.new(options)
      client.subscribe('hanabi.message') do |payload|
        puts "subscribed: #{payload.inspect}"
      end
      client.subscribe('hanabi.ping') do |payload|
        puts "ping: #{payload.host}"
        @hosts[payload.host] = Time.now.to_i
      end
      client.subscribe('hanabi.command') do |payload|
        puts "command: #{payload.inspect}"
        case payload.command
          when 'report'
            puts "hosts:"
            @hosts.each do |host, time|
              puts "- %15s %s" % [time, host]
            end
        end
      end
      client.subscribe('hanabi.joined') do |payload|
        puts "joined: #{payload.host}"
      end
      client.start

      # Hanabi.setup(options)
      # host = Hanabi.config.host
      # port = Hanabi.config.port
      # AMQP.start("amqp:://#{host}:#{port}") do |connection|
      #   @hosts = {}
      #   channel = AMQP::Channel.new(connection)
      #   exchange = channel.fanout('hanabi')
      #   control = channel.queue('hanabi.control', auto_delete: false).bind(exchange)
      #   ping = channel.queue('hanabi.ping', auto_delete: false).bind(exchange)
      #   report = channel.queue('hanabi.report', auto_delete: false).bind(exchange)
      #
      #   ping.subscribe do |metadata, payload|
      #     p = Hanabi::Message.parse(payload)
      #     puts "recieved ping from #{p.name}"
      #     @hosts[p.name] = Time.now.to_i
      #   end
      #
      #   report.subscribe do |metadata, payload|
      #     p = Hanabi::Message.parse(payload)
      #     puts "report: #{p.type}"
      #     case p.type
      #       when 'hosts'
      #         @hosts.each do |h, t|
      #           puts ' - %12d %s' % [t, h]
      #         end
      #       else
      #         puts 'unknown report type'
      #     end
      #   end
      #
      #   control.subscribe do |metadata, payload|
      #     p = Hanabi::Message.parse(payload)
      #     cmd = p.command
      #     if cmd == 'stop'
      #       connection.close {
      #         EventMachine.stop { exit }
      #       }
      #     else
      #       puts "unknown control command: #{cmd}"
      #     end
      #   end
      #
      #   Hanabi.message('hanabi.control', {command: 'server', server: Hanabi.inventory.name})
      # end
    end
  end
end
