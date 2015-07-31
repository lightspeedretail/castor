require 'fileutils'
require 'optparse'

module Castor
  class CLI
    attr_reader :options, :data_dir

    def initialize
      cli_parser

      @data_dir = @options['data_dir'].nil? ? '/tmp' : @options['data_dir']
      @lock_file = "#{@data_dir}/castor.#{@options['instance_name']}.#{@options['log_type']}.lock"

      pre_flight
    end

    def cli_parser # rubocop:disable Metrics/MethodLength
      @options = {}

      @cli_parser = OptionParser.new do |opts|
        opts.banner = 'Usage: castor [options]'
        opts.separator ''
        opts.separator 'Required options:'

        opts.on('-n INSTANCE_NAME', 'Instance name') do |name|
          @options['instance_name'] = name
        end

        opts.on('-t LOG_TYPE', String, %w(error general slowquery), 'Log type (error, general, slowquery)') do |log|
          @options['log_type'] = log
        end

        opts.separator ''
        opts.separator 'Other options:'

        opts.on('-a', 'Configure temporary IAM role credentials') do |aws|
          @options['aws'] = aws
        end

        opts.on('-d DATA_DIR', String, 'Data directory') do |data|
          @options['data_dir'] = data
        end

        opts.on('-D', 'Enable debugging') do |debug|
          @options['debug'] = debug
        end

        opts.on_tail('-h', '--help', 'Help message') do
          puts opts
          exit
        end
      end

      @cli_parser.parse!
    end

    def pre_flight
      if @options.empty?
        puts @cli_parser
        exit(1)
      else
        FileUtils.mkdir_p(@data_dir) unless Dir.exist?(@data_dir)
        unless @options['aws']
          puts @cli_parser unless @options['log_type']
          puts @cli_parser unless @options['instance_name']
        end
      end
    end

    def lock
      FileUtils.touch(@lock_file)
    end

    def locked?
      fail 'Found a lock. Exiting.' if File.exist?(@lock_file)
    end

    def unlock
      FileUtils.rm(@lock_file) if File.exist?(@lock_file)
    end
  end
end
