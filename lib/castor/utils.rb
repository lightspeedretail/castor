require_relative 'parser'
require_relative 'rds'
require_relative 'version'
require 'deep_merge'
require 'json'

module Castor
  module Utils
    include Parser
    include RDS

    def lock
      FileUtils.touch(@lock_file) unless locked?
    end

    def locked?
      File.exist?(@lock_file) ? true : false
    end

    def marker
      if File.exist?(@state_file)
        if @state[@instance] && @state[@instance][@log_type]
          @marker = @state[@instance][@log_type]['last_marker'].nil? ? 0 : @state[@instance][@log_type]['last_marker']
        else
          @marker = 0
        end
      else
        @marker = 0
      end
    end

    def processing
      data_pending = true
      log_file = (rotated? || @db_type == "postgres") ? previous_log_file(@log_type, @instance) : "#{@log_type}/mysql-#{@log_type}.log"

      while data_pending
        results = fetch(log_file, @instance, @marker, 1000)
        @marker = results['marker']
        data_pending = results['additional_data_pending']
        data = results['log_file_data']

        unless data.nil? # rubocop:disable Style/Next
          slowquery(data.split("\n"), @instance) if @log_type == 'slowquery'
          general(data.split("\n"), @instance) if @log_type == 'general'
          error(data.split("\n"), @instance) if @log_type == 'error'
        end
      end
    end

    def rotated?
      @size < @state[@instance][@log_type]['last_size'] ? true : false
    rescue
      # set to false if we can't determine the condition above i.e.
      # @state[@instance] is empty
      false
    end

    def unlock
      FileUtils.rm(@lock_file) if File.exist?(@lock_file)
    end

    def version
      puts "castor v#{Castor::VERSION}"
      exit
    end

    def write_state
      current = File.exist?(@state_file) && File.size(@state_file) > 0 ? JSON.parse(File.read(@state_file)) : {}
      data = { @instance =>
        { @log_type =>
          {
            'last_marker' => @marker,
            'last_size' => @size,
            'last_timestamp' => @timestamp
          }
        }
      }
      File.write(@state_file, JSON.pretty_generate(data.deep_merge(current)).concat("\n"))
    end
  end
end
