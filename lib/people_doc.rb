# frozen_string_literal: true
# $LOAD_PATH.unshift File.dirname(__FILE__)

require 'people_doc/version'
require 'people_doc/httparty_request'
require 'logger'

module PeopleDoc
  RESPONSE_HANDLERS = {
    bad_request: ResponseHandlers::HandleBadRequest,
    not_found: ResponseHandlers::HandleNotFound,
    unauthorized: ResponseHandlers::HandleUnauthorized,
    unprocessable_entity: ResponseHandlers::HandleUnprocessableEntity,
    unknown: ResponseHandlers::HandleUnknownFailure
  }.freeze

  class BaseError < StandardError
    attr_reader :response

    def initialize(message = nil, response = nil)
      super(message)

      @response = response
    end
  end
  class BadRequest < BaseError; end
  class NotFound < BaseError; end
  class Unauthorized < BaseError; end
  class UnprocessableEntity < BadRequest; end
  class Token
    attr_accessor :access_token, :token_type, :expires_in

    def initialize(access_token, token_type, expires_in)
      @access_token = access_token
      @token_type = token_type
      @expires_in = expires_in
    end
  end

  module V1
    class << self
      attr_accessor :api_key,
                    :base_url,
                    :logger

      ##
      # Configures default PeopleDoc REST APIv1 settings.
      #
      # @example configuring the client defaults
      #   PeopleDoc::V1.configure do |config|
      #     config.api_key = 'api_key'
      #     config.base_url = 'https://api.staging.us.people-doc.com'
      #     config.logger = Logger.new(STDOUT)
      #   end
      #
      # @example using the client
      #   client = PeopleDoc::V1::Client.new
      def configure
        yield self
        true
      end
    end

    ##
    # PeopleDoc REST API v1 Client
    class Client
      def initialize(options = {})
        options = default_options.merge(options)

        @api_key = options.fetch(:api_key)
        @base_url = options.fetch(:base_url)
        @logger = options.fetch(:logger, Logger.new(STDOUT))
        @request = HTTPartyRequest.new(@base_url, @logger, response_handlers)
      end

      ##
      # Get a resource
      # Makes a request for a resource from PeopleDoc and returns the response
      # as a raw {Hash}.
      #
      # @param [String] the resource endpoint
      # @return [Hash] response data
      def get(resource)
        @request
          .get(base_headers, "api/v1/#{resource}")
      rescue NotFound
        nil
      end

      ##
      # POST a resource
      # Makes a request to post new or existing resource details to PeopleDoc.
      #
      # @param [String] the resource endpoint
      # @param [Hash] payload data
      # @return [Hash] response data
      def post(resource, payload)
        @request.post(
          base_headers,
          "api/v1/#{resource}/",
          payload.to_json
        )
      end

      ##
      # POST a file
      # ...
      #
      # @param [String] the resource endpoint
      # @param [...] file
      # @param [Hash] payload data
      # @return [Hash] response data
      def post_file(resource, file, payload)
        @request.post_file(
          base_headers.merge(
            'Content-Type' => 'multipart/form-data'
          ),
          "api/v1/#{resource}/",
          file: file,
          data: payload.to_json
        )
      end

      protected

      def base_headers
        {
          'Accept' => 'application/json',
          'X-API-KEY' => @api_key,
          'Content-Type' => 'application/json',
          'Host' => uri.host,
          'User-Agent' => 'PeopleDoc::V1::Client'
        }
      end

      ##
      # Default options
      # A {Hash} of default options populate by attributes set during
      # configuration.
      #
      # @return [Hash] containing the default options
      def default_options
        {
          api_key: PeopleDoc::V1.api_key,
          base_url: PeopleDoc::V1.base_url,
          logger: PeopleDoc::V1.logger
        }
      end

      def response_handlers
        RESPONSE_HANDLERS.merge(
          bad_request: PeopleDoc::ResponseHandlers::V1::HandleBadRequest
        )
      end

      def uri
        @uri ||= URI.parse(@base_url)
      end
    end
  end

  module V2
    class << self
      attr_accessor :application_id,
                    :application_secret,
                    :base_url,
                    :client_id,
                    :logger

      ##
      # Configures default PeopleDoc REST APIv1 settings.
      #
      # @example configuring the client defaults
      #   PeopleDoc::V2.configure do |config|
      #     config.application_id = 'application_id'
      #     config.application_secret = 'application_secret'
      #     config.base_url = 'https://apis.staging.us.people-doc.com'
      #     config.client_id = 'client_id'
      #     config.logger = Logger.new(STDOUT)
      #   end
      #
      # @example using the client
      #   client = PeopleDoc::V2::Client.new
      def configure
        yield self
        true
      end
    end

    ##
    # PeopleDoc REST API v2 Client
    class Client
      def initialize(options = {})
        options = default_options.merge(options)

        @application_id = options.fetch(:application_id)
        @application_secret = options.fetch(:application_secret)
        @base_url = options.fetch(:base_url)
        @client_id = options.fetch(:client_id)
        @logger = options.fetch(:logger, Logger.new(STDOUT))
        @request = HTTPartyRequest.new(@base_url, @logger, response_handlers)
      end

      def encoded_credentials
        EncodedCredentials.new(@application_id, @application_secret).call
      end

      ##
      # OAuth token
      # Performs authentication using client credentials against the
      # PeopleDoc Api.
      #
      # @return [Token] token details
      def token
        return @token if @token

        payload = {
          client_id: @client_id,
          grant_type: 'client_credentials',
          scope: 'client'
        }
        headers = {
          'Accept' => 'application/json',
          'Authorization' => "Basic #{encoded_credentials}",
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Host' => uri.host,
          'User-Agent' => 'PeopleDoc::V2::Client'
        }

        response = @request.post(headers, 'api/v2/client/tokens', payload)

        @token = Token.new(
          *response.values_at('access_token', 'token_type', 'expires_in')
        )
      end

      ##
      # Get a resource
      # Makes a request for a resource from PeopleDoc and returns the response
      # as a raw {Hash}.
      #
      # @param [String] the resource endpoint
      # @return [Hash] response data
      def get(resource)
        @request
          .get(base_headers, "api/v2/client/#{resource}")
      rescue NotFound
        nil
      end

      ##
      # POST a file
      # ...
      #
      # @param [String] the resource endpoint
      # @param [...] file
      # @param [Hash] payload data
      # @return [Hash] response data
      def post_file(resource, file, payload = nil)
        @request.post_file(
          base_headers.merge(
            'Content-Type' => 'multipart/form-data'
          ),
          "api/v2/#{resource}",
          file: file,
          data: payload ? payload.to_json : nil
        )
      end

      ##
      # PUT a resource
      # Makes a request to PUT new or existing resource details to PeopleDoc.
      #
      # @param [String] the resource endpoint
      # @param [Hash] payload data
      # @return [Hash] response data
      def put(resource, payload)
        @request.put(
          base_headers,
          "api/v2/client/#{resource}",
          payload.to_json
        )
      end

      protected

      def base_headers
        {
          'Accept' => 'application/json',
          'Authorization' => "Bearer #{token.access_token}",
          'Content-Type' => 'application/json',
          'Host' => uri.host,
          'User-Agent' => 'PeopleDoc::V2::Client'
        }
      end

      ##
      # Default options
      # A {Hash} of default options populate by attributes set during
      # configuration.
      #
      # @return [Hash] containing the default options
      def default_options
        {
          application_id: PeopleDoc::V2.application_id,
          application_secret: PeopleDoc::V2.application_secret,
          base_url: PeopleDoc::V2.base_url,
          client_id: PeopleDoc::V2.client_id,
          logger: PeopleDoc::V2.logger
        }
      end

      def response_handlers
        RESPONSE_HANDLERS.merge(
          bad_request: PeopleDoc::ResponseHandlers::V2::HandleBadRequest,
          unauthorized: PeopleDoc::ResponseHandlers::V2::HandleUnauthorized
        )
      end

      def uri
        @uri ||= URI.parse(@base_url)
      end
    end

    class EncodedCredentials
      def initialize(application_id, application_secret)
        @application_id = application_id
        @application_secret = application_secret
      end

      def call
        Base64.strict_encode64("#{@application_id}:#{@application_secret}")
      end
    end
  end
end
