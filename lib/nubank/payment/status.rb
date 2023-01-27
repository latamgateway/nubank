class Nubank
  class Payment
    class Status < Struct.new(
      :payment_id,
      :reference_id,
      :status,
      :value,
      :currency,
      :timestamp,
      :refunds,
      keyword_init: true,
    )
      def self.from_hash(hash)
        new(
          payment_id: hash.fetch(:pspReferenceId),
          reference_id: hash.fetch(:referenceId),
          status: hash.fetch(:status).to_sym,
          value: hash.fetch(:amount).fetch(:value),
          currency: hash.fetch(:amount).fetch(:currency).to_sym,
          timestamp: hash.fetch(:timestamp),
          refunds:
            hash
              .fetch(:refunds, [])
              .map do |refund|
                Refund::Status.from_hash(
                  **hash.slice(:pspReferenceId),
                  **refund,
                )
              end,
        )
      end
    end
  end
end
