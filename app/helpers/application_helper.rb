require 'digest'

module ApplicationHelper
  TWILIO_ACCOUNT_SID = ENV['TWILIO_ACCOUNT_SID']
  TWILIO_AUTH_TOKEN = ENV['TWILIO_AUTH_TOKEN']
  TWILIO_PHONE_NUMBER = ENV['TWILIO_PHONE_NUMBER']
  APP_SECRET = ENV['APP_SECRET']

  # compute the verification code for a phone number
  def verification_code(phone)
    return Digest::SHA256.hexdigest(APP_SECRET + normalize_phone(phone) + APP_SECRET).to_i(16).to_s(10)[0...6]
  end

  # compute a password hash
  def password_hash(password, salt)
    return Digest::SHA256.hexdigest(salt + password + salt)
  end

  # normalize a phone number
  def normalize_phone(phone)
    phone = phone.strip.gsub(/[-+() ]/, '')
    if phone.size == 10
      phone = '1' + phone
    end
    return phone
  end

end
