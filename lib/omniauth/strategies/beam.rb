require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    #
    class Beam < OmniAuth::Strategies::OAuth2
      BLANK_PARAMS  = [nil, ''].freeze
      DEFAULT_SCOPE = 'user:details:self'.freeze
      RAW_INFO_URL  = '/api/v1/users/current'.freeze
      SOCIAL_KEYS   = %w(facebook discord player twitter youtube).freeze

      option :name, 'beam'

      option :client_options,
             site:          'https://beam.pro',
             authorize_url: '/oauth/authorize',
             token_url:     '/api/v1/oauth/token'

      option :access_token_options,
             header_format: 'OAuth %s',
             param_name:    'access_token'

      option :authorize_options, [:scope]

      uid { raw_info['id'] }

      info do
        {
          name:        raw_info['username'],
          email:       raw_info['email'],
          description: raw_info['bio'],
          image:       raw_info['avatarUrl'],
          social:      social_info,
          urls:        urls_info
        }
      end

      def access_token_options
        options.access_token_options.each_with_object({}) do |(key, val), hsh|
          hsh[key.to_sym] = val
          hsh
        end
      end

      def authorize_params
        super.tap do |params|
          options[:authorize_options].each do |key|
            val = request.params[key.to_s]
            params[key] = val unless BLANK_PARAMS.include? val
          end
        end
      end

      def build_access_token
        super.tap do |token|
          token.options.merge! access_token_options
        end
      end

      def callback_url
        return options[:redirect_url] if options.key? :redirect_url
        full_host + script_name + callback_path
      end

      def raw_info
        @raw_info ||= access_token.get(RAW_INFO_URL).parsed
      end

      def social_info
        raw_social = raw_info['social']
        SOCIAL_KEYS.each_with_object({}) do |key, hsh|
          hsh[key.to_sym] = raw_social[key] if raw_social.key? key
          hsh
        end
      end

      def urls_info
        {
          Beam: "http://beam.pro/#{raw_info['channel']['token']}"
        }
      end
    end # Beam
  end # Strategies
end # OmniAuth
