require_relative "../json/client"
require_relative "../../nubank/error"

module HTTP
  module Nubank
    class Client < JSON::Client
      attr_reader :merchant_key

      def initialize(merchant_key:, merchant_token:, **kargs)
        super(**kargs)

        @merchant_key = merchant_key
        @merchant_token = merchant_token

        @authentication_headers = {
          "X-Merchant-Key" => @merchant_key,
          "X-Merchant-Token" => @merchant_token,
        }
      end

      def get(url, headers: {})
        super(url, headers: headers.merge(@authentication_headers))
      end

      def post(url, headers: {}, body: nil)
        super(url, headers: headers.merge(@authentication_headers), body: body)
      end

      private

      def request(...)
        response = super
        raise ::Nubank::Error, response.to_json unless response.successful?
        response
      end
    end
  end
end
