require_relative 'cli'
require_relative 'fetcher'
require_relative 'parser'
require 'deep_merge'
require 'json'

module Castor
  class Core
    def initialize # rubocop:disable Metrics/MethodLength
      @cli = Castor::CLI.new
      @options = @cli.options
      @region = @options['region'] || 'us-east-1'
      @fetcher = Castor::Fetcher.new(@options, @region)
      @log_type = @options['log_type']
      @iam_profile_name = @options['iam_profile_name']
      @instance_name = @options['instance_name']
      @data_dir = @cli.data_dir
      @state_file = "#{@data_dir}/castor.#{@options['instance_name']}.#{@options['log_type']}.state.json"
      @state = File.exist?(@state_file) && File.size(@state_file) > 0 ? JSON.parse(File.read(@state_file)) : {}
      @parser = Castor::Parser.new(@options)
    end

    def run # rubocop:disable Metrics/MethodLength
      puts "BEGIN #{Time.now}" if @options['debug']

      auth
      # Exit if we only want to configure AWS
      exit if @options['aws'] && @options.count == 1
      exit if @options['aws'] && @options['iam_profile_name'] && @options.count == 2

      @size = @fetcher.file_size(@log_type, @instance_name)
      abort('File is empty. Exiting.') if @size == 0
      @cli.lock unless @cli.locked?

      marker?

      # Need to be called twice if rotated. The first run
      # will process the logs from the last log file. The
      # second will process the current file. Then we
      # reset the marker to be sure we process the entire
      # current file.
      if rotated?
        puts 'ROTATION DETECTED' if @options['debug']
        processing
        @marker = 0
        write_state
        # Once we're done processing the remainder of the
        # last log file, exit. We'll start fresh on the
        # next run.
        exit
      end
      puts 'NORMAL PROCESSING' if @options['debug']
      processing
    ensure
      puts "last_marker: #{@marker}" if @options['debug']
      puts "END #{Time.now}" if @options['debug']
      write_state
      @cli.unlock
    end

    def auth
      mode = @options['aws'] ? 'aws' : 'local'
      profile = @options['iam_profile_name'] ? @options['iam_profile_name'] : 'aws-rds-readonly-download-logs-role'
      Castor::AWS::Auth.new(mode, profile)
    end

    def marker?
      if File.exist?(@state_file)
        if @state[@instance_name] && @state[@instance_name][@log_type]
          @marker = @state[@instance_name][@log_type]['last_marker'].nil? ? 0 : @state[@instance_name][@log_type]['last_marker']
        else
          @marker = 0
        end
      else
        @marker = 0
      end
    end

    def processing # rubocop:disable Metrics/MethodLength
      data_pending = true
      log_file = rotated? ? @fetcher.previous_log_file(@instance_name, @log_type) : "#{@log_type}/mysql-#{@log_type}.log"

      while data_pending
        results = @fetcher.fetch(log_file, @instance_name, @marker, 1000)
        @marker = results['marker']
        data_pending = results['additional_data_pending']
        data = results['log_file_data']

        if data.nil?
          abort('No new logs to process. Exiting.')
        else
          @parser.slowquery(data.split("\n"), @instance_name) if @log_type == 'slowquery'
          @parser.general(data.split("\n"), @instance_name) if @log_type == 'general'
          @parser.error(data.split("\n"), @instance_name) if @log_type == 'error'
        end
      end
    end

    def rotated?
      @size < @state[@instance_name][@log_type]['last_size'] if @state[@instance_name] && @state[@instance_name][@log_type] && @state[@instance_name][@log_type]['last_size']
    end

    def write_state # rubocop:disable Metrics/MethodLength
      current = File.exist?(@state_file) ? JSON.parse(File.read(@state_file)) : {}
      data = { @instance_name =>
        { @log_type =>
          {
            'last_marker' => @marker,
            'last_size' => @size,
            'last_timestamp' => @parser.timestamp
          }
        }
      }
      File.write(@state_file, JSON.pretty_generate(data.deep_merge(current)).concat("\n"))
    end
  end
end
