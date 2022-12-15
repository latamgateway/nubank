class Nubank
  class Payment
    class New < Struct.new(
      :payment_id,
      :reference_id,
      :status,
      keyword_init: true,
    )
      def self.from_hash(hash)
        new(
          payment_id: hash.fetch(:pspReferenceId),
          reference_id: hash.fetch(:referenceId),
          status: hash.fetch(:status).to_sym,
        )
      end
    end
  end
end
