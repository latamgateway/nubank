require "time"

class Nubank
  class Refund
    class Status < Struct.new(
      :payment_id,
      :refund_id,
      :refund_transaction_id,
      :status,
      :due_time,
      keyword_init: true,
    )
      def self.from_hash(hash)
        new(
          payment_id: hash.fetch(:pspReferenceId),
          refund_id: hash.fetch(:refundId),
          refund_transaction_id: hash.fetch(:transactionRefundId),
          status: hash.fetch(:status).to_sym,
          due_time: Time.parse(hash.fetch(:dueDate)),
        )
      end
    end
  end
end
