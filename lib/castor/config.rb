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
      :description => 'Log type to fetch/parse (PostgreSQL only has "error")',
      :required => true,
      :in => %w(general slowquery error)

    option :profile,
      :short => '-p PROFILE',
      :long => '--profile PROFILE',
      :description => 'AWS profile to use in ~/.aws/credentials'

    option :access_key,
      :short => '-a access_key',
      :long => '--access-key access_key',
      :description => 'AWS access key ID. Should be used along with --secret-key'

    option :secret_key,
      :short => '-s secret_key',
      :long => '--secret-key secret_key',
      :description => 'AWS secret access key. Should be used along with --access-key'

    option :region,
      :short => '-r REGION',
      :long => '--region REGION',
      :default => 'us-east-1',
      :description => 'AWS region (default: us-east-1)'

    option :version,
      :short => '-v',
      :long => '--version',
      :description => 'Print version'

    option :db_type,
      :long => '--db-type (mysql|postgres)',
      :default => "mysql",
      :description => 'Database type: mysql (default) or postgres'
  end
end
