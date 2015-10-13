require_relative 'aws'
require 'aws-sdk'
require 'json'

module Castor
  class Fetcher
    def initialize(options, region)
      @aws = Castor::AWS.new
      @rds = Aws::RDS::Client.new(:region => region)
      @options = options
    end

    def file_size(log_type, instance_name)
      sleep_duration = 5
      files_info = @rds.describe_db_log_files(db_instance_identifier: instance_name)
      file = files_info['describe_db_log_files'].detect { |log| log['log_file_name'] == "#{log_type}/mysql-#{log_type}.log" }
      file['size']
    rescue Aws::RDS::Errors::Throttling
      sleep(sleep_duration)
      sleep_duration += 5
      retry
    end

    def fetch(log_file, instance_name, marker, lines) # rubocop:disable Metrics/MethodLength
      sleep_duration = 5
      puts "file: #{log_file}, instance: #{instance_name}, marker: #{marker}" if @options['debug']
      @rds.download_db_log_file_portion(
        db_instance_identifier: instance_name,
        log_file_name: log_file,
        number_of_lines: lines,
        marker: "#{marker}"
      )
    rescue Aws::RDS::Errors::Throttling
      sleep(sleep_duration)
      sleep_duration += 5
      retry
    end

    def previous_log_file(instance_name, log_type)
      sleep_duration = 5
      log_files = @rds.describe_db_log_files(db_instance_identifier: instance_name)
      log_files = log_files['describe_db_log_files'].select { |log| log['log_file_name'] =~ %r{#{log_type}\/mysql-#{log_type}.log.} }
      sorted = log_files.sort_by { |hash| -hash['last_written'] }
      sorted.first['log_file_name']
    rescue Aws::RDS::Errors::Throttling
      sleep(sleep_duration)
      sleep_duration += 5
      retry
    end
  end
end
