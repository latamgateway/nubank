class Nubank
  class Payment
    class New < Struct.new(
      :payment_id,
      :reference_id,
      :status,
      :payment_url,
      keyword_init: true,
    )
      def self.from_hash(hash)
        new(
          payment_id: hash.fetch(:pspReferenceId),
          reference_id: hash.fetch(:referenceId),
          status: hash.fetch(:status).to_sym,
          payment_url: hash[:paymentUrl],
        )
      end
    end
  end
end
