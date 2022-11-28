require "base64"
require "logger"
require "ed25519"
require_relative "../http/json/client"

class Nubank
  class RequestVerifier
    # https://docs.nupaybusiness.com.br/en/checkout/merchants/openapi/#operation/SigningKeysGet
    def self.fetch_public_key(base_url:, logger: Logger.new(STDOUT))
      client = HTTP::JSON::Client.new(logger: logger)
      response = client.get("#{base_url}/security/request-signing-keys")

      Base64.strict_decode64(response.body.fetch(:publicKey))
    end

    def initialize(public_key:)
      @public_key = public_key
      @verify_key = Ed25519::VerifyKey.new(@public_key)
    end

    def valid?(signature:, path:, timestamp:, body:, method: "POST")
      signature = Base64.strict_decode64(signature)
      message = "#{method}#{path}#{timestamp}#{body}"

      @verify_key.verify(signature, message)
    rescue Ed25519::VerifyError
      false
    end
  end
end
