# frozen_string_literal: true
module PeopleDoc
  module ResponseHandlers
    class BaseHandler
      def initialize(httparty)
        @httparty = httparty
      end
    end

    class HandleBadRequest < BaseHandler
      def call
        fail BadRequest.new(@httparty.body, @httparty.parsed_response) \
          if @httparty.code == 400
      end
    end

    class HandleNotFound < BaseHandler
      def call
        fail NotFound.new(@httparty.body) if @httparty.code == 404
      end
    end

    class HandleUnauthorized < BaseHandler
      def call
        fail Unauthorized.new(@httparty.body) \
          if [401, 403].include?(@httparty.code)
      end
    end

    class HandleUnprocessableEntity < BaseHandler
      def call
        return unless @httparty.code == 422

        message = format(
          '%<code>s: %<message>s',
          code: @httparty.parsed_response['code'],
          message: @httparty.parsed_response['message']
        )
        message += "\r\n\r\n"
        message += @httparty
                   .parsed_response['errors']
                   .map { |error| "#{error['field']} - #{error['message']}" }
                   .join("\r\n")

        fail UnprocessableEntity.new(message, @httparty.parsed_response)
      end
    end

    class HandleUnknownFailure < BaseHandler
      def call
        fail HTTParty::Error.new(
          "Code #{@httparty.code} - #{@httparty.body}"
        ) unless @httparty.response.is_a?(Net::HTTPSuccess)
      end
    end

    module V1
      class HandleBadRequest < PeopleDoc::ResponseHandlers::BaseHandler
        def call
          return unless @httparty.code == 400

          message = if @httparty.parsed_response['errors']
                      ErrorsResponse.new(@httparty).call
                    elsif @httparty.parsed_response['message']
                      MessageResponse.new(@httparty).call
                    else
                      @httparty.body
                    end

          fail BadRequest.new(message, @httparty.parsed_response)
        end

        class ErrorsResponse
          def initialize(response)
            @response = response
          end

          def call
            @response
              .parsed_response['errors']
              .map { |error| error['msg'] }
              .join("\r\n")
          end
        end

        class MessageResponse
          def initialize(response)
            @response = response
          end

          def call
            @response.parsed_response['message']
          end
        end
      end
    end

    module V2
      class HandleBadRequest < PeopleDoc::ResponseHandlers::BaseHandler
        def call
          return unless @httparty.code == 400

          message = @httparty.parsed_response['error_description']

          fail BadRequest.new(message, @httparty.parsed_response)
        end
      end

      class HandleUnauthorized < BaseHandler
        def call
          return unless @httparty.code == 401

          message = if @httparty.parsed_response['error']
                      format(
                        '%<error>s: %<description>s',
                        error: @httparty.parsed_response['error'],
                        description: @httparty
                                     .parsed_response['error_description']
                      )
                    elsif @httparty.parsed_response['code']
                      format(
                        '%<code>s: %<message>s',
                        code: @httparty.parsed_response['code'],
                        message: @httparty.parsed_response['message']
                      )
                    else
                      @httparty.body
                    end

          fail Unauthorized.new(message)
        end
      end
    end
  end
end
