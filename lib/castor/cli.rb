require_relative 'config'
require_relative 'logging'
require_relative 'utils'
require_relative 'rds'
require_relative 'version'
require 'aws-sdk'
require 'fileutils'

module Castor
  class CLI
    include Logging
    include RDS
    include Utils

    def initialize
      config

      @data_dir = @config[:data_directory]
      @debug = @config[:debug]
      @instance = @config[:instance]
      @log_type = @config[:log_type]
      @db_type = @config[:db_type]
      @lock_file = "#{@data_dir}/castor.#{@instance}.#{@log_type}.lock"
      @size = log_file_size(@log_type, @instance)
      @state_file = "#{@data_dir}/castor.#{@instance}.#{@log_type}.state.json"
      @state = File.exist?(@state_file) && File.size(@state_file) > 0 ? JSON.parse(File.read(@state_file)) : {}

      pre_flight
      run
    end

    def config
      cli = Castor::Config.new

      if ARGV.empty?
        puts cli.opt_parser
        exit(1)
      end

      cli.banner = 'Usage: castor (options)'
      cli.parse_options
      @config = cli.config

      aws_config = { region: @config[:region] }
      aws_config[:profile] = @config[:profile] if @config[:profile]
      aws_config[:credentials] = Aws::Credentials.new(@config[:access_key], @config[:secret_key]) if @config[:access_key]
      Aws.config.update(aws_config)
    end

    def pre_flight
      FileUtils.mkdir_p(@data_dir) unless Dir.exist?(@data_dir)
    end

    def run
      version if @config[:version]
      debug("castor v#{Castor::VERSION}") if @debug
      debug("Processing '#{@log_type}' logs for '#{@instance}'") if @debug

      exit if @size == 0
      lock
      marker

      # Need to be called twice if rotated. The first run
      # will process the logs from the last log file. The
      # second will process the current file. Then we
      # reset the marker to be sure we process the entire
      # current file.
      if rotated?
        debug('Rotation detected') if @debug
        processing
        @marker = 0
        write_state
        # Once we're done processing the remainder of the
        # last log file, exit. We'll start fresh on the
        # next run.
        exit
      end

      debug('Normal processing') if @debug
      processing
      write_state

    ensure
      unlock
    end
  end
end
