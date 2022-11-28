require "vcr"

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true
  config.hook_into :webmock
  config.cassette_library_dir = "spec/fixtures/vcr/cassettes"

  %w[X-Merchant-Key X-Merchant-Token].each do |header|
    config.filter_sensitive_data("<#{header}>") do |interaction|
      interaction.request.headers[header]&.first
    end
  end
end
