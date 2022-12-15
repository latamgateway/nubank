require "json"
require_relative "../client"
require_relative "../response"

class Nubank
  module HTTP
    module JSON
      class Client < Client
        def get(...)
          deserialize(super)
        end

        def post(url, headers: {}, body: nil)
          deserialize(
            super(
              url,
              headers: headers.merge("Content-Type" => "application/json"),
              body: body&.to_json,
            ),
          )
        end

        private

        def deserialize(response)
          response.body =
            ::JSON.parse(
              response.body.force_encoding("UTF-8"),
              symbolize_names: true,
            )

          response
        end
      end
    end
  end
end
