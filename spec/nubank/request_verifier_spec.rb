require "base64"
require "json"
require "uri"
require "securerandom"
require "logger"
require_relative "../../lib/nubank/request_verifier"

RSpec.describe Nubank::RequestVerifier do
  let(:public_key) do
    VCR.use_cassette(:fetch_public_key) do
      Nubank::RequestVerifier.fetch_public_key(
        base_url: ENV.fetch("NUBANK_BASE_URL"),
        logger: Logger.new(File::NULL),
      )
    end
  end

  let(:verifier) do
    Nubank::RequestVerifier.new(public_key: public_key, clock: clock)
  end

  describe :fetch_public_key do
    it "returns the public key" do
      expect(Base64.encode64(public_key)).to match_snapshot(:public_key)
    end
  end

  describe :valid? do
    let(:request) do
      JSON.parse(
        File.read(Dir.glob("#{__dir__}/webhooks/*.json").sample),
        symbolize_names: true,
      ).dig(:log, :entries, 0, :request)
    end

    let(:headers) do
      request[:headers].to_h { |header| [header[:name].to_sym, header[:value]] }
    end

    let(:signature) { headers[:"x-spin-signature"] }
    let(:path) { URI.parse(request[:url]).path }
    let(:timestamp) { headers[:"x-spin-timestamp"] }
    let(:body) { request[:postData][:text] }
    let(:method) { request[:method] }

    let(:clock) { double(:clock, now: Time.iso8601(timestamp)) }

    let(:valid) do
      verifier.valid?(
        signature: signature,
        path: path,
        timestamp: timestamp,
        body: body,
        method: method,
      )
    end

    it "validates the request" do
      expect(valid).to be true
    end

    context "invalid signature" do
      let(:signature) { SecureRandom.base64(64) }

      it "rejects the request" do
        expect(valid).to be false
      end
    end

    context "invalid timestamp" do
      let(:clock) { double(:clock, now: Time.now - 1_000_000) }

      it "rejects the request" do
        expect(valid).to be false
      end
    end
  end
end
