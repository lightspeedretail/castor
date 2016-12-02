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

    def get_instance_tags(instance)
      sleep_duration = 5
      debug("instance: #{instance}") if @debug
      instance_details = rds.describe_db_instances(db_instance_identifier: instance)
      # Retrieve tags
      tags = rds.list_tags_for_resource(resource_name: instance_details.db_instances[0].db_instance_arn.to_s)
      # Format them
      instance_tags = {}
      tags.tag_list.each do |tag|
        instance_tags[tag.key.to_s] = tag.value
      end
      return instance_tags
    rescue Aws::RDS::Errors::Throttling
      sleep(sleep_duration)
      sleep_duration += 5
      retry
    end

    def log_file_size(log_type, instance)
      sleep_duration = 5
      files_info = rds.describe_db_log_files(db_instance_identifier: instance)
      file = files_info['describe_db_log_files'].detect { |log| log['log_file_name'] == "#{log_type}/mysql-#{log_type}.log" }
      file['size']
    rescue Aws::RDS::Errors::Throttling
      sleep(sleep_duration)
      sleep_duration += 5
      retry
    end

    def previous_log_file(log_type, instance)
      sleep_duration = 5
      log_files = rds.describe_db_log_files(db_instance_identifier: instance)
      log_files = log_files['describe_db_log_files'].select { |log| log['log_file_name'] =~ %r{#{log_type}\/mysql-#{log_type}.log.} }
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
