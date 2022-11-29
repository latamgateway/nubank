require "logger"
require_relative "nubank/version"
require_relative "http/nubank/client"
require_relative "http/client"
require_relative "nubank/payment/new"
require_relative "nubank/payment/status"
require_relative "nubank/refund/new"
require_relative "nubank/refund/status"
require_relative "nubank/error/qrcode_unavailable"

class Nubank
  attr_accessor :logger

  def initialize(
    base_url:,
    merchant_key:,
    merchant_token:,
    logger: Logger.new(STDOUT)
  )
    @base_url = base_url
    @merchant_key = merchant_key
    @merchant_token = merchant_token
    @logger = logger

    @nubank_client =
      HTTP::Nubank::Client.new(
        merchant_key: @merchant_key,
        merchant_token: @merchant_token,
        logger: @logger,
      )

    @http_client = HTTP::Client.new(logger: @logger)
  end

  # https://docs.nupaybusiness.com.br/en/checkout/merchants/openapi/#operation/PaymentsPost
  def create_payment(
    reference_id:,
    value:,
    shopper:,
    items:,
    callback_url:,
    merchant_reference_id: reference_id,
    currency: "BRL",
    auto_cancel_delay_in_minutes: 30,
    settlement_delay_in_minutes: 1
  )
    response =
      @nubank_client.post(
        relative("/checkouts/payments"),
        body: {
          merchantOrderReference: merchant_reference_id,
          referenceId: reference_id,
          amount: {
            value: value,
            currency: currency,
          },
          shopper: {
            firstName: shopper.first_name,
            lastName: shopper.last_name,
            document: shopper.document,
            documentType: shopper.document_type,
            email: shopper.email,
            phone: shopper.phone.to_h,
          },
          items: items.map(&:to_h),
          callbackUrl: callback_url,
          delayToAutoCancel: auto_cancel_delay_in_minutes,
          delayToSettlement: settlement_delay_in_minutes,
        },
      )

    Payment::New.from_hash(response.body)
  end

  # https://docs.nupaybusiness.com.br/en/checkout/merchants/openapi/#operation/PaymentMethodsGet
  def fetch_qrcode(payment_id:, payment_method: "pix")
    response = @nubank_client.get(relative("/checkouts/payment-methods"))

    available =
      response
        .body
        .fetch(:paymentMethods)
        .any? do |method|
          method.fetch(:type) == payment_method && method.fetch(:hasQRCode)
        end

    unless available
      raise Error::QRCodeUnavailable,
            "QR code is unavailable for #{payment_method.inspect}!"
    end

    url = URI.parse(response.body.fetch(:schemas).fetch(:qrCodeContent))

    url.query =
      URI.encode_www_form(
        pspReferenceId: payment_id,
        paymentMethodType: payment_method,
      )

    response = @http_client.get(url)

    response.body
  end

  # https://docs.nupaybusiness.com.br/en/checkout/merchants/openapi/#operation/PaymentsStatusByPspReferenceIdGet
  def fetch_payment(payment_id:)
    response =
      @nubank_client.get(relative("/checkouts/payments/#{payment_id}/status"))

    Payment::Status.from_hash(response.body)
  end

  # https://docs.nupaybusiness.com.br/en/checkout/merchants/openapi/#operation/PaymentsRefundByPspReferenceIdPost
  def refund_payment(
    payment_id:,
    refund_id:,
    value:,
    max_days_to_compose:,
    currency: "BRL"
  )
    response =
      @nubank_client.post(
        relative("/checkouts/payments/#{payment_id}/refunds"),
        body: {
          transactionRefundId: refund_id,
          amount: {
            value: value,
            currency: currency,
          },
          delayToCompose: max_days_to_compose,
        },
      )

    Refund::New.from_hash(response.body)
  end

  # https://docs.nupaybusiness.com.br/en/checkout/merchants/openapi/#operation/PaymentsRefundByIdGet
  def fetch_refund(refund_id:, payment_id:)
    response =
      @nubank_client.get(
        relative("/checkouts/payments/#{payment_id}/refunds/#{refund_id}"),
      )

    Refund::Status.from_hash(response.body)
  end

  private

  def relative(url)
    "#{@base_url}#{url}"
  end
end
