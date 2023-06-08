require "time"

class Nubank
  class Refund
    class New < Struct.new(
      :payment_id,
      :refund_id,
      :status,
      :due_time,
      keyword_init: true,
    )
      def self.from_hash(hash)
        new(
          payment_id: hash.fetch(:pspReferenceId),
          refund_id: hash.fetch(:refundId),
          status: hash.fetch(:status).to_sym,
          # The sandbox is returning a null value but the docs say that it is required and of type string.
          due_time: hash[:dueDate] ? Time.parse(hash.fetch(:dueDate)) : hash[:dueDate],
        )
      end
    end
  end
end
