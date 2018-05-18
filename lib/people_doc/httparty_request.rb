# frozen_string_literal: true

require 'httparty'
require 'people_doc/response_handlers'

module PeopleDoc
  class HTTPartyRequest
    def initialize(base_url, logger, response_handlers = [])
      @base_url = base_url
      @logger = logger
      @response_handlers = response_handlers
    end

    def get(headers, resource)
      url = "#{@base_url}/#{resource}"

      @logger.debug("GET request Url: #{url}")
      @logger.debug("-- Headers: #{headers}")

      raises_unless_success do
        HTTParty
          .get(url, headers: headers)
      end.parsed_response
    end

    def perform_request(headers, resource, payload)
      http_method = __callee__
      url = "#{@base_url}/#{resource}"

      @logger.debug("#{http_method.upcase} request Url: #{url}")
      @logger.debug("-- Headers: #{headers}")
      @logger.debug("-- Payload: #{payload}")

      raises_unless_success do
        HTTParty
          .send(http_method.to_sym, url, body: payload, headers: headers)
      end.parsed_response
    end
    alias_method :put, :perform_request
    alias_method :post, :perform_request

    def post_file(headers, resource, payload)
      http_method = 'post'
      url = "#{@base_url}/#{resource}"

      @logger.debug("#{http_method.upcase} request Url: #{url} (POST file)")
      @logger.debug("-- Headers: #{headers}")
      @logger.debug("-- Payload: #{payload}")

      raises_unless_success do
        HTTParty.post(url, body: payload, headers: headers)
      end.parsed_response
    end

    protected

    def raises_unless_success
      httparty = yield

      @response_handlers.each_value do |handler_type|
        handler_type.new(httparty).call
      end

      httparty
    end
  end
end
