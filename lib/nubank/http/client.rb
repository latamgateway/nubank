require "logger"
require "curb"
require_relative "response"

class Nubank
  module HTTP
    class Client
      attr_accessor :logger

      def initialize(
        logger: Logger.new(STDOUT),
        encoding_types: %i[gzip deflate br],
        verbose: false
      )
        @logger = logger
        @encoding_types = encoding_types
        @verbose = verbose

        @curl = Curl::Easy.new
      end

      def get(url, headers: {})
        request(method: :get, url: url, headers: headers)
      end

      def post(url, headers: {}, body: nil)
        request(method: :post, url: url, headers: headers, body: body)
      end

      private

      def request(method:, url:, headers: {}, body: nil)
        @logger.debug("#{method.upcase}:\s#{url.inspect}")
        @logger.debug("request.headers:\s#{headers.inspect}") if headers.any?
        @logger.debug("request.body:\s#{body.inspect}") if body

        @curl.encoding = @encoding_types.join(",\s")
        @curl.verbose = @verbose

        @curl.url = url.to_s
        @curl.headers = headers
        @curl.post_body = body if body

        @curl.public_send(method)

        response =
          Response.new(
            status: @curl.response_code,
            headers: parse_headers(@curl.header_str),
            body: @curl.body_str,
          )

        # We need to call reset because of a bug in webmock.
        # https://github.com/bblimke/webmock/issues/703
        @curl.reset

        @logger.debug("response:\s#{response.inspect}")

        response
      end

      # https://www.rfc-editor.org/rfc/rfc9110.html#name-header-fields
      def parse_headers(header_str)
        header_str
          .split("\r\n")
          .drop(1)
          .map { |line| line.split(/:\s*/, 2) }
          .reduce({}) do |headers, (header, value)|
            header = header.downcase.to_sym

            if headers.key?(header)
              headers[header] << "," << value
            else
              headers[header] = value
            end

            headers
          end
      end
    end
  end
end
