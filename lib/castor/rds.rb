require_relative 'logging'

module Castor
  module RDS
    include Logging

    def fetch(log_file, instance, marker, lines)
      sleep_duration = 5
      debug("file: #{log_file}, instance: #{instance}, marker: #{marker}") if @debug
      rds.download_db_log_file_portion(
        db_instance_identifier: instance,
        log_file_name: log_file,
        number_of_lines: lines,
        marker: marker.to_s # API expects a string
      )
    rescue Aws::RDS::Errors::Throttling
      sleep(sleep_duration)
      sleep_duration += 5
      retry
    end

    def log_file_size(log_type, instance)
      sleep_duration = 5
      files_info = rds.describe_db_log_files(db_instance_identifier: instance)
      file = files_info['describe_db_log_files'].detect { |log|
          (@db_type == "mysql" && log['log_file_name'] == "#{log_type}/mysql-#{log_type}.log") || (@db_type == "postgres" && log['log_file_name'].start_with?("#{log_type}/postgresql.log"))
       }
      file['size']
    rescue Aws::RDS::Errors::Throttling
      sleep(sleep_duration)
      sleep_duration += 5
      retry
    end

    def previous_log_file(log_type, instance)
      sleep_duration = 5
      log_files = rds.describe_db_log_files(db_instance_identifier: instance)
      log_files = log_files['describe_db_log_files'].select { |log|
          (@db_type == "mysql" && log['log_file_name'] =~ %r{#{log_type}\/mysql-#{log_type}.log.}) ||
          (@db_type == "postgres" && log['log_file_name'].start_with?("#{log_type}/postgresql.log"))
       }
      sorted = log_files.sort_by { |hash| -hash['last_written'] }
      sorted.first['log_file_name']
    rescue Aws::RDS::Errors::Throttling
      sleep(sleep_duration)
      sleep_duration += 5
      retry
    end

    def rds
      Aws::RDS::Client.new
    end
  end
end
