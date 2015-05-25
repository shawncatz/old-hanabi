require 'logger'

module Hanabi
  class Log
    LEVELS = {
        debug: Logger::DEBUG,
        info: Logger::INFO,
        warn: Logger::WARN,
        error: Logger::ERROR,
        fatal: Logger::FATAL,
        unknown: Logger::UNKNOWN,
    }
    def initialize(level, stdout)
      @logger = Logger.new(stdout)
      @logger.level = LEVELS[level.to_sym]
    end
    def level
      @logger.level
    end
    def level=(level)
      @logger.level = LEVELS[level]
    end
    LEVELS.keys.each do |k|
      define_method k, ->(msg) { @logger.send(k, msg) }
    end
  end
end
