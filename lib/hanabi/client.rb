module Hanabi
  class Client
    def initialize(options)
      Hanabi.setup(options)
      @subs = {}
      @periodics = []
    end

    def start
      host = Hanabi.config.host
      port = Hanabi.config.port

      # puts "starting"
      AMQP.start("amqp:://#{host}:#{port}") do |connection|

        # puts "started"
        @channel = AMQP::Channel.new(connection)
        @channel.on_error do |ch, channel_close|
          raise "Channel-level exception: #{channel_close.reply_text}"
        end
        # puts "fanout"
        @exchange = @channel.fanout('hanabi')
        # puts "queue"
        @channel.queue(inv.name, auto_delete: true).bind(@exchange).subscribe do |raw|
          payload = Hanabi.parse(raw)
          # puts "received: #{payload.inspect}"
          puts "recieved: #{payload.name}"
          if @subs[payload.name]
            @subs[payload.name].call(payload)
          end
        end

        @periodics.each do |p|
          EventMachine.add_periodic_timer(p[:timer]) do
            b = p[:block]
            instance_eval &b
          end
        end

        # puts "initialized"
        Signal.trap("INT") { puts "stopping"; connection.close { EventMachine.stop } }
        pub name: 'hanabi.joined', host: inv.name
      end
    end

    def subscribe(name, &block)
      @subs[name] = block
    end

    def periodic(timer, &block)
      @periodics << {timer: timer, block: block}
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
      @exchange.publish(msg(data))
    end
  end
end
