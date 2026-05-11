# frozen_string_literal: true

module PaypalHelper
  # Initial request to confirm the payment can be placed (before redirecting to paypal)
  def stub_paypal_response(options)
    paypal_response = instance_double(PayPal::SDK::Merchant::DataTypes::SetExpressCheckoutResponseType)
    expect(paypal_response).to(receive(:success?).and_return(options[:success]))
    allow(paypal_response).to(receive(:errors).and_return([]))

    paypal_provider = instance_double(::PayPal::SDK::Merchant::API)
    expect(paypal_provider).to(receive(:build_set_express_checkout).and_return(nil))
    expect(paypal_provider).to(receive(:set_express_checkout).and_return(paypal_response))
    allow(paypal_provider).to(receive(:express_checkout_url).and_return(options[:redirect]))

    allow_any_instance_of(PaymentGateways::PaypalController).to(
      receive(:provider).and_return(paypal_provider)
    )
  end

  # Additional request to re-confirm the payment, when the order is finalised.
  def stub_paypal_confirm
    stub_request(:post, "https://api-3t.sandbox.paypal.com/2.0/")
      .with(body: /GetExpressCheckoutDetailsReq/)
      .to_return(status: 200, body: mock_get_express_checkout_details_response)
    stub_request(:post, "https://api-3t.sandbox.paypal.com/2.0/")
      .with(body: /DoExpressCheckoutPaymentReq/)
      .to_return(status: 200, body: mock_do_express_checkout_payment)
  end

  private

  def mock_get_express_checkout_details_response
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
      <SOAP-ENV:Envelope
        xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
        xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
        xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
        xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
        xmlns:xs=\"http://www.w3.org/2001/XMLSchema\"
        xmlns:cc=\"urn:ebay:apis:CoreComponentTypes\"
        xmlns:wsu=\"http://schemas.xmlsoap.org/ws/2002/07/utility\"
        xmlns:saml=\"urn:oasis:names:tc:SAML:1.0:assertion\"
        xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\"
        xmlns:wsse=\"http://schemas.xmlsoap.org/ws/2002/12/secext\"
        xmlns:ed=\"urn:ebay:apis:EnhancedDataTypes\"
        xmlns:ebl=\"urn:ebay:apis:eBLBaseComponents\"
        xmlns:ns=\"urn:ebay:api:PayPalAPI\"
      >
        <SOAP-ENV:Body id=\"_0\">
          <GetExpressCheckoutDetailsResponse xmlns=\"urn:ebay:api:PayPalAPI\">
            <Timestamp xmlns=\"urn:ebay:apis:eBLBaseComponents\">2026-04-08T05:49:41Z</Timestamp>
            <Ack xmlns=\"urn:ebay:apis:eBLBaseComponents\">Success</Ack>
          </GetExpressCheckoutDetailsResponse>
        </SOAP-ENV:Body>
      </SOAP-ENV:Envelope>"
  end

  # rubocop:disable Metrics/MethodLength
  def mock_do_express_checkout_payment
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
      <SOAP-ENV:Envelope
        xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
        xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
        xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
        xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
        xmlns:xs=\"http://www.w3.org/2001/XMLSchema\"
        xmlns:cc=\"urn:ebay:apis:CoreComponentTypes\"
        xmlns:wsu=\"http://schemas.xmlsoap.org/ws/2002/07/utility\"
        xmlns:saml=\"urn:oasis:names:tc:SAML:1.0:assertion\"
        xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\"
        xmlns:wsse=\"http://schemas.xmlsoap.org/ws/2002/12/secext\"
        xmlns:ed=\"urn:ebay:apis:EnhancedDataTypes\"
        xmlns:ebl=\"urn:ebay:apis:eBLBaseComponents\"
        xmlns:ns=\"urn:ebay:api:PayPalAPI\"
      >
        <SOAP-ENV:Body id=\"_0\">
          <DoExpressCheckoutPaymentResponse xmlns=\"urn:ebay:api:PayPalAPI\">
            <Timestamp xmlns=\"urn:ebay:apis:eBLBaseComponents\">2026-04-08T02:10:58Z</Timestamp>
            <Ack xmlns=\"urn:ebay:apis:eBLBaseComponents\">Success</Ack>
            <Version xmlns=\"urn:ebay:apis:eBLBaseComponents\">117.0</Version>
            <DoExpressCheckoutPaymentResponseDetails
              xmlns=\"urn:ebay:apis:eBLBaseComponents\"
              xsi:type=\"ebl:DoExpressCheckoutPaymentResponseDetailsType\"
            >
              <PaymentInfo xsi:type=\"ebl:PaymentInfoType\">
                <TransactionID>11111111111111112</TransactionID>
              </PaymentInfo>
            </DoExpressCheckoutPaymentResponseDetails>
          </DoExpressCheckoutPaymentResponse>
        </SOAP-ENV:Body>
      </SOAP-ENV:Envelope>"
  end
end
