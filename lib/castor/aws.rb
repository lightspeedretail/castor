require 'fileutils'
require 'json'
require 'net/http'

module Castor
  class AWS
    def run(cmd)
      cli = Mixlib::ShellOut.new(cmd)
      cli.run_command
      cli.error!
      cli.stdout
    end

    class Auth
      def initialize(mode, iam_profile)
        @dir = "#{ENV['HOME']}/.aws"
        @iam_profile_name = iam_profile
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
        credentials = JSON.parse(Net::HTTP.get(URI("http://169.254.169.254/latest/meta-data/iam/security-credentials/#{@iam_profile_name}")))
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
