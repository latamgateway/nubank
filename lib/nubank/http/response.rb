class Nubank
  module HTTP
    class Response < Struct.new(:status, :headers, :body, keyword_init: true)
      def successful?
        (200..299).include?(status)
      end
    end
  end
end
