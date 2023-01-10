require "securerandom"
require "pp"
require_relative "../lib/nubank"
require_relative "../lib/nubank/shopper"
require_relative "../lib/nubank/phone"
require_relative "../lib/nubank/item"

RSpec.describe Nubank do
  let(:random) { Random.new(seed) }

  let(:value) { 12.34 }
  let(:refund_value) { value }

  let(:nubank) do
    Nubank.new(
      base_url: ENV.fetch("NUBANK_BASE_URL"),
      merchant_key: ENV.fetch("NUBANK_MERCHANT_KEY"),
      merchant_token: ENV.fetch("NUBANK_MERCHANT_TOKEN"),
      logger: Logger.new(File::NULL),
    )
  end

  let(:shopper) do
    Nubank::Shopper.new(
      first_name: "John",
      last_name: "Doe",
      document: "12345678810",
      email: "john.doe@example.com",
      phone: Nubank::Phone.new(country: "55", number: "21987654321"),
    )
  end

  let(:items) do
    [
      Nubank::Item.new(
        id: "1",
        value: value,
        quantity: 1,
        description: "A dozen eggs",
      ),
    ]
  end

  let(:create_payment) do
    lambda do |reference_id: random.uuid|
      nubank.create_payment(
        reference_id: reference_id,
        value: value,
        shopper: shopper,
        items: items,
        callback_url: "https://example.com/webhooks",
      )
    end
  end

  # NOTE: The payment must be authorized (manually in the sandbox)
  # and settled (automatically after the `delayToSettlement` period).
  let(:create_refund) do
    lambda do |refund_id: random.uuid|
      nubank.refund_payment(
        payment_id: payment.payment_id,
        refund_id: refund_id,
        value: refund_value,
        max_days_to_compose: 7,
      )
    end
  end

  context "payments" do
    let(:seed) { 100 }
    let(:payment) { VCR.use_cassette(:create_payment) { create_payment.call } }

    describe :create_payment do
      it "creates the payment" do
        expect(payment.pretty_inspect).to match_snapshot(:create_payment)
      end

      context "with duplicate reference ID" do
        let(:seed) { 2430 }
        let(:reference_id) { random.uuid }

        it "raises an error" do
          expect {
            VCR.use_cassette(:duplicate_payment) do
              2.times { create_payment.call(reference_id: reference_id) }
            end
          }.to raise_error(Nubank::Error)
        end
      end
    end

    describe :fetch_payment do
      it "returns the payment information" do
        info =
          VCR.use_cassette(:fetch_payment) do
            nubank.fetch_payment(payment_id: payment.payment_id)
          end

        expect(info.pretty_inspect).to match_snapshot(:fetch_payment)
      end
    end

    describe :fetch_qrcode do
      it "returns the QR code" do
        qrcode =
          VCR.use_cassette(:fetch_qrcode) do
            nubank.fetch_qrcode(payment_id: payment.payment_id)
          end

        expect(qrcode).to match_snapshot(:fetch_qrcode)
      end

      context "when QR code is unavailable" do
        it "raises an error" do
          expect {
            VCR.use_cassette(:qrcode_unavailable) do
              nubank.fetch_qrcode(
                payment_id: payment.payment_id,
                payment_method: "nupay",
              )
            end
          }.to raise_error(Nubank::Error::QRCodeUnavailable)
        end
      end
    end

    describe :fetch_app_link do
      it "returns the AppLink" do
        qrcode =
          VCR.use_cassette(:fetch_app_link) do
            nubank.fetch_app_link(payment_id: payment.payment_id)
          end

        expect(qrcode).to match_snapshot(:fetch_app_link)
      end

      context "when AppLink is unavailable" do
        it "raises an error" do
          expect {
            VCR.use_cassette(:app_link_unavailable) do
              nubank.fetch_app_link(
                payment_id: payment.payment_id,
                payment_method: "pix",
              )
            end
          }.to raise_error(Nubank::Error::AppLinkUnavailable)
        end
      end
    end
  end

  context "refunds" do
    let(:seed) { 2684 }

    let(:payment) do
      VCR.use_cassette(:payment_for_refund) { create_payment.call }
    end

    let(:refund) { VCR.use_cassette(:refund_payment) { create_refund.call } }

    describe :refund_payment do
      it "creates the refund" do
        expect(refund.pretty_inspect).to match_snapshot(:refund_payment)
      end

      context "with duplicate refund ID" do
        let(:seed) { 1433 }
        let(:refund_id) { random.uuid }

        let(:payment) do
          VCR.use_cassette(:payment_for_duplicate_refund) do
            create_payment.call
          end
        end

        it "raises an error" do
          expect {
            VCR.use_cassette(:duplicate_refund) do
              2.times { create_refund.call(refund_id: refund_id) }
            end
          }.to raise_error(Nubank::Error)
        end
      end

      context "with overvalue" do
        let(:seed) { 2293 }
        let(:refund_value) { value + 1 }

        let(:payment) do
          VCR.use_cassette(:payment_for_overvalue_refund) do
            create_payment.call
          end
        end

        it "raises an error" do
          expect {
            VCR.use_cassette(:overvalue_refund) { create_refund.call }
          }.to raise_error(Nubank::Error)
        end
      end
    end

    describe :fetch_refund do
      it "returns the refund information" do
        info =
          VCR.use_cassette(:fetch_refund) do
            nubank.fetch_refund(
              refund_id: refund.refund_id,
              payment_id: payment.payment_id,
            )
          end

        expect(info.pretty_inspect).to match_snapshot(:fetch_refund)
      end
    end
  end
end
