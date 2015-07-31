require 'fileutils'
require 'json'
require 'mixlib/shellout'
require 'net/http'

module Castor
  class AWS
    def initialize
      url = 'https://github.com/aws/aws-cli'
      fail "AWS CLI isn't functional. Please see: #{url}" unless system('which aws > /dev/null 2>&1')
    end

    def run(cmd)
      cli = Mixlib::ShellOut.new(cmd)
      cli.run_command
      cli.error!
      cli.stdout
    end

    class Auth
      def initialize(mode)
        @dir = "#{ENV['HOME']}/.aws"
        write_config if mode == 'aws'
      end

      def write_config
        Dir.mkdir(@dir, 0700) unless Dir.exist?(@dir)
        config
        credentials
      end

      def config
        region = JSON.parse(Net::HTTP.get(URI('http://169.254.169.254/latest/dynamic/instance-identity/document')))['region']
        config = "[default]\nregion=#{region}\noutput=json\n"

        file = "#{@dir}/config"
        File.write(file, config)
        FileUtils.chmod(0600, file)
      end

      def credentials
        credentials = JSON.parse(Net::HTTP.get(URI('http://169.254.169.254/latest/meta-data/iam/security-credentials/aws-rds-readonly-download-logs-role')))
        access = credentials['AccessKeyId']
        secret = credentials['SecretAccessKey']
        token = credentials['Token']
        config = "[default]\naws_access_key_id=#{access}\naws_secret_access_key=#{secret}\naws_session_token=#{token}\n"

        file = "#{@dir}/credentials"
        File.write(file, config)
        FileUtils.chmod(0600, file)
      end
    end
  end
end
