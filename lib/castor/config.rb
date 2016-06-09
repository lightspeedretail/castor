require 'mixlib/cli'

module Castor
  class Config
    include Mixlib::CLI

    # rubocop:disable Style/AlignParameters
    option :data_directory,
      :short => '-d DATA_DIRECTORY',
      :long => '--data-directory DATA_DIRECTORY',
      :description => 'Data directory (default: /tmp/castor)',
      :default => '/tmp/castor'

    option :debug,
      :short => '-D',
      :long => '--debug',
      :description => 'Debugging mode (default: false)',
      :default => false

    option :instance,
      :short => '-i INSTANCE',
      :long => '--instance INSTANCE',
      :description => 'RDS instance name',
      :required => true

    option :log_type,
      :short => '-t LOG_TYPE',
      :long => '--type LOG_TYPE',
      :description => 'Log type to fetch/parse (general, slowquery, error)',
      :required => true,
      :in => %w(general slowquery error)

    option :profile,
      :short => '-p PROFILE',
      :long => '--profile PROFILE',
      :description => 'AWS profile to use in ~/.aws/credentials'

    option :region,
      :short => '-r REGION',
      :long => '--region REGION',
      :default => 'us-east-1',
      :description => 'AWS region (default: us-east-1)'
  end
end
