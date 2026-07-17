require 'aws-sdk-ssm'

class EnvironmentParameters
  @cache = {}

  def self.lookup(key)
    key_str = key.to_s
    return @cache[key_str] if @cache.key?(key_str)

    value = if development? || Sinatra::Base.test?
      ENV[key_str.upcase]
    else
      ssm_value = fetch_from_ssm(key_str)
      ssm_value || ENV[key_str.upcase]
    end

    @cache[key_str] = value
  end

  def self.[](key)
    lookup(key)
  end

  def self.fetch_from_ssm(key)
    ssm_client.get_parameter(
      name: "#{Constants::SSM_PREFIX}/#{key}",
      with_decryption: true
    ).parameter.value
  rescue Aws::SSM::Errors::ParameterNotFound
    nil
  end

  def self.ssm_client
    @ssm_client ||= Aws::SSM::Client.new(region: ENV['AWS_REGION'] || 'us-east-1')
  end
end
