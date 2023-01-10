require "time"

class Nubank
  class Refund
    class Status < Struct.new(
      :payment_id,
      :refund_id,
      :refund_transaction_id,
      :status,
      :due_time,
      :error,
      keyword_init: true,
    )
      class Error < Struct.new(:type, :message, :code, keyword_init: true)
        def self.from_hash(hash)
          new(
            type: hash.fetch(:type),
            message: hash.fetch(:message),
            code: hash[:code],
          )
        end
      end

      def self.from_hash(hash)
        new(
          payment_id: hash.fetch(:pspReferenceId),
          refund_id: hash.fetch(:refundId),
          refund_transaction_id: hash.fetch(:transactionRefundId),
          status: hash.fetch(:status).to_sym,
          due_time: Time.parse(hash.fetch(:dueDate)),
          error: hash.key?(:error) ? Error.from_hash(hash[:error]) : nil,
        )
      end
    end
  end
end
