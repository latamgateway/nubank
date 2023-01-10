require "logger"

Dir.glob("**/*.rb", base: __dir__).each { |path| require_relative path }

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
            value: Float(value),
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
  def fetch_qrcode(
    payment_id:,
    payment_method: "pix",
    payment_methods: fetch_payment_methods
  )
    available =
      payment_methods
        .fetch(:paymentMethods)
        .any? do |method|
          method.fetch(:type) == payment_method && method.fetch(:hasQRCode)
        end

    unless available
      raise Error::QRCodeUnavailable,
            "QR code is unavailable for #{payment_method.inspect}!"
    end

    fetch_schema_url(
      url: payment_methods.fetch(:schemas).fetch(:qrCodeContent),
      payment_id: payment_id,
      payment_method: payment_method,
    )
  end

  # https://docs.nupaybusiness.com.br/en/checkout/merchants/openapi/#operation/PaymentMethodsGet
  def fetch_app_link(
    payment_id:,
    payment_method: "nupay",
    payment_methods: fetch_payment_methods
  )
    available =
      payment_methods
        .fetch(:paymentMethods)
        .any? do |method|
          method.fetch(:type) == payment_method && method.fetch(:hasAppLink)
        end

    unless available
      raise Error::AppLinkUnavailable,
            "AppLink is unavailable for #{payment_method.inspect}!"
    end

    fetch_schema_url(
      url: payment_methods.fetch(:schemas).fetch(:appLink),
      payment_id: payment_id,
      payment_method: payment_method,
    )
  end

  def fetch_payment_methods
    @nubank_client.get(relative("/checkouts/payment-methods")).body
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
            value: Float(value),
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

  def fetch_schema_url(url:, payment_id:, payment_method:)
    uri = URI.parse(url)

    uri.query =
      URI.encode_www_form(
        pspReferenceId: payment_id,
        paymentMethodType: payment_method,
      )

    response = @http_client.get(uri)

    response.body
  end
end
