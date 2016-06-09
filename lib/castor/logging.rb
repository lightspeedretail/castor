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
      logger(STDERR).debug(msg)
    end
  end
end
