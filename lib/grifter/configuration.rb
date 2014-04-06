require 'tcfg/tcfg_base'

module Grifter
  module Configuration

    DEFAULT_CONFIG_FILE = 'grifter.yml'

    def grifter_configuration
      init_config
      @grifter_configuration.tcfg
    end

    def grifter_config_file filename
      @grifter_config_file = filename
      init_config
    end

    private

    #ensure the configuration is resolved and ready to use
    #
    # @param force_refresh [Boolean] if false and configuration has been initialized it will not be re-initialized
    def init_config
      if !@grifter_configuration
        @grifter_configuration = TCFG::Base.new

        default_services = @grifter_configuration.tcfg_fetch 'services'
        default_services ||= {}
        @grifter_configuration.tcfg_set 'services', default_services

        @grifter_configuration.tcfg_set_env_var_prefix 'GRIFTER_'
      end

      if @grifter_config_file
        #if a config file was specified, we assume it exists
        @grifter_configuration.tcfg_config_file @grifter_config_file

      elsif File.exist? DEFAULT_CONFIG_FILE
        #if a config file was not specific, it is optional that it exist
        @grifter_configuration.tcfg_config_file DEFAULT_CONFIG_FILE
      end

      normalize_services_config @grifter_configuration

      @grifter_configuration.tcfg_reset

      nil
    end

    def normalize_services_config cfg
      services = cfg['services']
      services.each_pair do |svc, svc_cfg|
        #add the name
        svc_cfg['name'] = svc

        unless svc_cfg.has_key? :url
          raise ConfigurationError.new "url for service '#{svc_cfg['name']}' is not defined"
        end

        unless svc_cfg['url'] =~ URI::ABS_URI
          raise ConfigurationError.new "url for service '#{svc_cfg['name']}' is not a proper absolute URL: #{svc_cfg['url']}"
        end

        parsed = URI.parse svc_cfg['url']

        svc_cfg['base_uri'] ||= parsed.path

        svc_cfg['faraday_url'] = "#{parsed.scheme}://#{parsed.host}:#{parsed.port}"
      end

      cfg.tcfg_set 'services', services
    end

  end

  class ConfigurationError < StandardError;end
end
