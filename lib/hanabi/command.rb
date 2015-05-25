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
    def send(type, command)
      Hanabi.setup(options)
      Hanabi.message({name: "hanabi.#{type}", command: command}, options)
    end

    desc 'stop', 'stop listening'
    def stop
      Hanabi.setup(options)
      Hanabi.message({name: 'hanabi.control', command: 'stop'}, options)
    end

    desc 'listen', 'connect to rabbit and listen for events'
    def listen
      client = Hanabi::Client.new(options)

      client.subscribe('hanabi.message') do |payload|
        Hanabi.log.info "subscribed: #{payload.inspect}"
      end

      client.start
    end

    desc 'server', 'connect to rabbit and act as server for reporting'
    def server
      @hosts = {}
      client = Hanabi::Client.new(options)

      client.subscribe('hanabi.message') do |payload|
        Hanabi.log.info "subscribed: #{payload.inspect}"
      end

      client.subscribe('hanabi.command') do |payload|
        Hanabi.log.debug "command: #{payload.inspect}"
        case payload.command
          when 'report'
            Hanabi.log.info "hosts:"
            @hosts.each do |host, time|
              Hanabi.log.info "- %15s %s" % [time, host]
            end
          else
            Hanabi.log.error "unknown command: #{payload.command}"
        end
      end

      client.subscribe('hanabi.host.heartbeat') do |payload|
        Hanabi.log.info "heartbeat: #{payload.host}"
        @hosts[payload.host] = Time.now.to_i
      end

      client.subscribe('hanabi.host.connected') do |payload|
        Hanabi.log.info "connected: #{payload.host}"
      end

      client.start
    end
  end
end
