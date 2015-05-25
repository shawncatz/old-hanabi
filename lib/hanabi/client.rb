module Hanabi
  class Client
    def initialize(options)
      Hanabi.setup(options)
      @subscriptions = {}
      @periodics = []
    end

    def start
      host = Hanabi.config.host
      port = Hanabi.config.port

      periodic(10) do
        pub name: 'hanabi.host.heartbeat', host: inv.name, inventory: inv.to_h
      end

      begin
        log.info "starting AMQP #{AMQP::VERSION} connection"
        AMQP.start("amqp:://#{host}:#{port}") do |connection|
          @channel = AMQP::Channel.new(connection)
          @channel.on_error do |ch, channel_close|
            raise "Channel-level exception: #{channel_close.reply_text}"
          end
          @exchange = @channel.fanout('hanabi')

          log.debug 'connecting to queue'
          @channel.queue("hanabi.host.#{inv.name}", auto_delete: true).bind(@exchange).subscribe do |raw|
            payload = Hanabi.parse(raw)
            log.debug "received: #{payload.name}"
            if @subscriptions[payload.name]
              @subscriptions[payload.name].call(payload)
            end
          end

          @periodics.each do |p|
            EventMachine.add_periodic_timer(p[:timer]) do
              b = p[:block]
              instance_eval &b
            end
          end

          # puts "initialized"
          pub name: 'hanabi.host.connected', host: inv.name
          stopper = Proc.new do
            puts 'stopping'
            connection.close { EventMachine.stop }
          end
          Signal.trap("INT", stopper)
          Signal.trap("TERM", stopper)
        end
      rescue => e
        log.error e.message
        log.debug e.backtrace
      end
    end

    def subscribe(name, &block)
      @subscriptions[name] = block
    end

    def periodic(timer, &block)
      @periodics << {timer: timer, block: block}
    end

    def log
      Hanabi.log
    end

    def inv
      Hanabi.inventory
    end

    def cfg
      Hanabi.config
    end

    def msg(data)
      Hanabi::Message.new(data).to_s
    end

    def pub(data)
      if block_given?
        @exchange.publish(msg(data)) do
          yield
        end
      else
        @exchange.publish(msg(data))
      end
    end
  end
end
