require 'dotenv/load'
require 'twilio-ruby'

module TwilioClient
  def self.client
    account_sid = ENV.fetch('TWILIO_SID') { raise "Missing TWILIO_SID" }
    auth_token  = ENV.fetch('TWILIO_TOKEN') { raise "Missing TWILIO_TOKEN" }
    Twilio::REST::Client.new(account_sid, auth_token)
  end

  def self.default_number
    ENV['TWILIO_DEFAULT_NUMBER']
  end
end
