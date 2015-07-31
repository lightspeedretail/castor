require 'date'
require 'json'

module Castor
  class Parser
    attr_reader :timestamp, :database

    def initialize(options)
      @options = options
    end

    def error(logs, instance_name) # rubocop:disable Metrics/MethodLength
      logs.each do |line|
        puts line.inspect if @options['debug']

        next if line.chomp("\n").empty?

        parts = line.split
        @timestamp = DateTime.parse([parts[0], parts[1]].join(' ')).to_time.to_i

        log = {}
        log['rds_instance'] = instance_name
        log['rds_log_type'] = 'error'

        if parts[0] =~ /\d\d\d\d-\d\d-\d\d/
          log['timestamp'] = @timestamp
          log['message'] = parts[3..-1].join(' ')
        else
          log['timestamp'] = Time.new.to_i
          log['message'] = line.chomp("\n")
        end
        puts JSON.generate(log)

        puts '' if @options['debug']
      end
    end

    def general(logs, instance_name) # rubocop:disable Metrics/MethodLength
      logs.each do |line|
        puts line.inspect if @options['debug']

        parts = line.split
        @timestamp = DateTime.parse([parts[0], parts[1]].join(' ')).to_time.to_i if parts[1] =~ /\d\d\:\d\d\:\d\d/

        # Some logs have 2 extra fields at the beginning. Date
        # and time. This is used to determine if those fields
        # are present or not.
        parts[1] =~ /\d\d\:\d\d\:\d\d/ ? i = 2 : i = 0

        log = {}
        log['rds_instance'] = instance_name
        log['rds_log_type'] = 'general'
        if parts[0] =~ /(rdsdbbin|Tcp|Time)/
          log['message'] = line.chomp("\n")
        else
          log['connection_id'] = i == 2 ? parts[2] : parts[0]
          log['query_type'] = i == 2 ? parts[3].downcase : parts[1].downcase
          log['query'] = parts[i + 2..-1].join(' ')
        end
        log['timestamp'] = @timestamp
        puts JSON.generate(log)

        puts '' if @options['debug']
      end
    end

    def slowquery(logs, instance_name) # rubocop:disable Metrics/MethodLength
      logs.slice_before(/# User@Host/).each do |slice|
        puts slice.inspect if @options['debug']

        # We expect the first line of a slice to be a User@Host line.
        # Skip if it's not, which means we're starting to process in the
        # middle of a transaction.
        next unless slice[0] =~ /^# User@Host/

        # Normalize logs. Those lines are removed as they
        # are useless for slow queries.
        slice.pop if slice.last =~ /# Time/
        next if slice[0] =~ /rdsdbbin/

        # Extract the database
        if slice[2] =~ /^use/
          @database = slice[2].split[1].chomp(';')
          slice.slice!(2) if slice[2] =~ /^use/
        end

        # Normalized logs should have at least 4 lines. When
        # we init, we might have less as we jump in the middle
        # of a transaction. So we're skipping those incomplete logs.
        next unless slice.count == 4

        @timestamp = slice[2].split('=')[1].chomp(';')
        if slice.count >= 4
          slice_0 = slice[0].split
          slice_1 = slice[1].split

          log = {}
          log['rds_instance'] = instance_name
          log['rds_log_type'] = 'slowquery'
          log['database'] = @database
          log['connection_id'] = slice_0.last
          log['who'] = slice_0[2..4].join
          log['query_time'] = slice_1[2]
          log['lock_time'] = slice_1[4]
          log['rows_sent'] = slice_1[6]
          log['rows_examined'] = slice_1[8]
          log['query'] = slice[3].chomp(";\n")
          log['timestamp'] = @timestamp
          puts JSON.generate(log)
        end
        puts '' if @options['debug']
      end
    end
  end
end
