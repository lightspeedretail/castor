module Castor
  module Logging
    require 'logger'

    def logger(output = STDOUT)
      logger = Logger.new(output)
      logger.formatter = proc do |severity, timestamp, _program, message|
        "[#{timestamp.strftime('%Y-%m-%d %H:%M:%S.%L')}] #{severity}: #{message}\n"
      end
      logger
    end

    def debug(msg)
      logger.debug(msg)
    end

    def info(msg)
      logger.info(msg)
    end

    def warning(msg)
      logger.warn(msg)
    end

    def error(msg, exit = true)
      logger(STDERR).error(msg)
      exit(1) if exit
    end
  end
end
