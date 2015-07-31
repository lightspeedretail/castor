require_relative 'aws'
require 'json'

module Castor
  class Fetcher
    def initialize(options)
      @aws = Castor::AWS.new
      @options = options
    end

    def file_size(log_type, instance_name)
      files_info = JSON.parse(@aws.run("aws rds describe-db-log-files --db-instance-identifier #{instance_name}"))
      file = files_info['DescribeDBLogFiles'].detect { |log| log['LogFileName'] == "#{log_type}/mysql-#{log_type}.log" }
      file['Size']
    end

    def fetch(log_file, instance_name, marker, lines)
      puts "file: #{log_file}, instance: #{instance_name}, marker: #{marker}" if @options['debug']
      @aws.run("aws rds download-db-log-file-portion --db-instance-identifier #{instance_name} --output json --log-file-name #{log_file} --number-of-lines #{lines} --marker #{marker}")
    end

    def previous_log_file(instance_name, log_type)
      log_files = JSON.parse(@aws.run("aws rds describe-db-log-files --db-instance-identifier #{instance_name}"))
      log_files = log_files['DescribeDBLogFiles'].select { |log| log['LogFileName'] =~ %r{#{log_type}\/mysql-#{log_type}.log.} }
      sorted = log_files.sort_by { |hash| -hash['LastWritten'] }
      sorted.first['LogFileName']
    end
  end
end
