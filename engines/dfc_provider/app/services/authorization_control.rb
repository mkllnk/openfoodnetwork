# frozen_string_literal: true

# Authorize the user on the DFC API
#
# It controls an OICD Access token and an enterprise.
class AuthorizationControl
  PUBLIC_KEYS = {
    # Copied from: https://login.lescommuns.org/auth/realms/data-food-consortium/
    "https://login.lescommuns.org/auth/realms/data-food-consortium" => <<~KEY,
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAl68JGqAILFzoi/1+6siXXp2vylu+7mPjYKjKelTtHFYXWVkbmVptCsamHlY3jRhqSQYe6M1SKfw8D+uXrrWsWficYvpdlV44Vm7uETZOr1/XBOjpWOi1vLmBVtX6jFeqN1BxfE1PxLROAiGn+MeMg90AJKShD2c5RoNv26e20dgPhshRVFPUGru+0T1RoKyIa64z/qcTcTVD2V7KX+ANMweRODdoPAzQFGGjTnL1uUqIdUwSfHSpXYnKxXOsnPC3Mowkv8UIGWWDxS/yzhWc7sOk1NmC7pb+Cg7G8NKj+Pp9qQZnXF39Dg95ZsxJrl6fyPFvTo3zf9CPG/fUM1CkkwIDAQAB
      -----END PUBLIC KEY-----
    KEY

    # Copied from: https://kc.cqcm.startinblox.com/realms/startinblox
    "https://kc.cqcm.startinblox.com/realms/startinblox" => <<~KEY,
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqtvdb3BdHoLnNeMLaWd7nugPwdRAJJpdSySTtttEQY2/v1Q3byJ/kReSNGrUNkPVkOeDN3milgN5Apz+sNCwbtzOCulyFMmvuIOZFBqz5tcgwjZinSwpGBXpn6ehXyCET2LlcfLYAPA9axtaNg9wBLIHoxIPWpa2LcZstogyZY/yKUZXQTDqM5B5TyUkPN89xHFdq8SQuXPasbpYl7mGhZHkTDHiKZ9VK7K5tqsEZTD9dCuTGMKsthbOrlDnc9bAJ3PyKLRdib21Y1GGlTozo4Y/1q448E/DFp5rVC6jG6JFnsEnP0WVn+6qz7yxI7IfUU2YSAGgtGYaQkWtEfED0QIDAQAB
      -----END PUBLIC KEY-----
    KEY
  }.freeze

  def self.public_key(token)
    unverified_payload = JWT.decode(token, nil, false, { algorithm: "RS256" }).first
    key = PUBLIC_KEYS[unverified_payload["iss"]]
    OpenSSL::PKey::RSA.new(key)
  end

  def initialize(request)
    @request = request
  end

  def user
    oidc_user || ofn_api_user || ofn_user
  rescue JWT::DecodeError
    nil
  end

  private

  def oidc_user
    return unless access_token

    payload = decode_token

    find_ofn_user(payload) # || platform user identified by client_id
  end

  def ofn_api_user
    Spree::User.find_by(spree_api_key: ofn_api_token) if ofn_api_token.present?
  end

  def ofn_user
    @request.env['warden']&.user
  end

  def decode_token
    JWT.decode(
      access_token,
      self.class.public_key(access_token),
      true, { algorithm: "RS256" }
    ).first
  end

  def access_token
    @request.headers['Authorization'].to_s.split.last
  end

  def ofn_api_token
    @request.headers["X-Api-Token"]
  end

  def find_ofn_user(payload)
    return if payload["email"].blank?

    OidcAccount.find_by(uid: payload["email"])&.user
  end
end
