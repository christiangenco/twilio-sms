#!/usr/bin/env ruby
# tools/twilio/sms.rb
#
# Purpose:
#   Twilio SMS/MMS CLI with CRUD operations. Outputs compact JSON for LLM parsing.
#
# Usage:
#   bundle exec ruby tools/twilio/sms.rb <command> [options]
#
# Commands:
#   list     - List messages (--from, --to, --since, --until, --limit)
#   get      - Get single message (--sid)
#   threads  - List conversation threads (--my-number, --partner, --since, --limit)
#   send     - Send SMS/MMS (--to, --body, --from, --messaging-service, --media-url)
#   numbers  - List phone numbers owned by account
#
# Environment:
#   - TWILIO_SID: Twilio Account SID
#   - TWILIO_TOKEN: Twilio Auth Token
#   - TWILIO_DEFAULT_NUMBER: Default "from" number (E.164 format)
#   - TWILIO_MESSAGING_SERVICE_SID: Default messaging service SID (recommended for A2P 10DLC)
#
# Safety:
#   - send is the only mutating operation
#   - All reads are non-destructive
#
# Notes:
#   - Outputs single-line JSON to stdout
#   - Threading is computed client-side (Twilio API has no native threads)

require 'json'
require 'optparse'
require 'time'
require_relative 'lib/twilio_client'

def output(data)
  puts JSON.generate(data)
end

def success(data)
  output(ok: true, data: data)
  exit 0
end

def error(msg, code = 'ERROR', details = nil)
  output(ok: false, error: msg, code: code, details: details)
  exit 1
end

def extract_message(m)
  {
    sid: m.sid,
    from: m.from,
    to: m.to,
    body: m.body,
    status: m.status,
    direction: m.direction,
    date_sent: m.date_sent&.iso8601,
    date_created: m.date_created&.iso8601,
    num_media: m.num_media.to_i,
    price: m.price,
    error_code: m.error_code,
    error_message: m.error_message
  }
end

def parse_time(str)
  return nil unless str

  Time.parse(str)
rescue ArgumentError
  nil
end

begin
  client = TwilioClient.client
  default_number = TwilioClient.default_number
  command = ARGV.shift
  options = {}

  case command
  when 'list'
    OptionParser.new do |opts|
      opts.on('--from NUMBER') { |v| options[:from] = v }
      opts.on('--to NUMBER') { |v| options[:to] = v }
      opts.on('--since DATE') { |v| options[:since] = v }
      opts.on('--until DATE') { |v| options[:until] = v }
      opts.on('--limit N', Integer) { |v| options[:limit] = v }
    end.parse!

    params = { limit: options[:limit] || 50 }
    params[:from] = options[:from] if options[:from]
    params[:to] = options[:to] if options[:to]
    params[:date_sent_after] = parse_time(options[:since]) if options[:since]
    params[:date_sent_before] = parse_time(options[:until]) if options[:until]

    messages = client.messages.list(**params).map { |m| extract_message(m) }
    success(messages: messages)

  when 'get'
    OptionParser.new do |opts|
      opts.on('--sid SID') { |v| options[:sid] = v }
    end.parse!

    error('Missing --sid', 'USAGE') unless options[:sid]

    m = client.messages(options[:sid]).fetch
    result = extract_message(m)

    if m.num_media.to_i > 0
      media_list = client.messages(options[:sid]).media.list
      result[:media] = media_list.map do |media|
        {
          sid: media.sid,
          content_type: media.content_type,
          uri: "https://api.twilio.com#{media.uri.sub('.json', '')}"
        }
      end
    end

    success(result)

  when 'threads'
    OptionParser.new do |opts|
      opts.on('--my-number NUMBER') { |v| options[:my_number] = v }
      opts.on('--partner NUMBER') { |v| options[:partner] = v }
      opts.on('--since DATE') { |v| options[:since] = v }
      opts.on('--limit N', Integer) { |v| options[:limit] = v }
    end.parse!

    my_number = options[:my_number] || default_number
    error('Missing --my-number or TWILIO_DEFAULT_NUMBER', 'USAGE') unless my_number

    limit = options[:limit] || 200
    since = parse_time(options[:since])

    outgoing_params = { from: my_number, limit: limit }
    incoming_params = { to: my_number, limit: limit }
    outgoing_params[:date_sent_after] = since if since
    incoming_params[:date_sent_after] = since if since

    outgoing = client.messages.list(**outgoing_params)
    incoming = client.messages.list(**incoming_params)

    all_messages = (outgoing + incoming).sort_by { |m| m.date_sent || m.date_created }

    threads = Hash.new { |h, k| h[k] = [] }
    all_messages.each do |m|
      other = m.direction&.start_with?('inbound') ? m.from : m.to
      next if options[:partner] && other != options[:partner]

      threads[other] << extract_message(m)
    end

    result = threads.map do |participant, msgs|
      { participant: participant, message_count: msgs.size, messages: msgs }
    end.sort_by { |t| t[:messages].last&.dig(:date_sent) || '' }.reverse

    success(my_number: my_number, threads: result)

  when 'send'
    media_urls = []
    OptionParser.new do |opts|
      opts.on('--to NUMBER') { |v| options[:to] = v }
      opts.on('--body TEXT') { |v| options[:body] = v }
      opts.on('--from NUMBER') { |v| options[:from] = v }
      opts.on('--messaging-service SID') { |v| options[:messaging_service] = v }
      opts.on('--media-url URL') { |v| media_urls << v }
    end.parse!

    error('Missing --to', 'USAGE') unless options[:to]
    error('Missing --body or --media-url', 'USAGE') if !options[:body] && media_urls.empty?
    error('Max 10 media URLs allowed', 'VALIDATION') if media_urls.size > 10

    # Prefer messaging service (for A2P 10DLC compliance), fall back to from number
    messaging_service_sid = options[:messaging_service] || ENV['TWILIO_MESSAGING_SERVICE_SID']
    from_number = options[:from] || default_number

    unless messaging_service_sid || from_number
      error('Missing --from, --messaging-service, TWILIO_DEFAULT_NUMBER, or TWILIO_MESSAGING_SERVICE_SID',
            'USAGE')
    end

    params = { to: options[:to] }
    if messaging_service_sid && !options[:from]
      # Use messaging service if available and --from not explicitly set
      params[:messaging_service_sid] = messaging_service_sid
    else
      params[:from] = from_number
    end
    params[:body] = options[:body] if options[:body]
    params[:media_url] = media_urls unless media_urls.empty?

    m = client.messages.create(**params)
    success(extract_message(m))

  when 'numbers'
    OptionParser.new do |opts|
      opts.on('--limit N', Integer) { |v| options[:limit] = v }
    end.parse!

    numbers = client.incoming_phone_numbers.list(limit: options[:limit] || 100)
    result = numbers.map do |n|
      {
        sid: n.sid,
        phone_number: n.phone_number,
        friendly_name: n.friendly_name,
        sms_enabled: n.capabilities['sms'],
        mms_enabled: n.capabilities['mms'],
        voice_enabled: n.capabilities['voice']
      }
    end

    success(numbers: result)

  else
    error("Unknown command: #{command}", 'USAGE',
          'Commands: list, get, threads, send, numbers')
  end
rescue Twilio::REST::RestError => e
  error(e.message, e.code.to_s, e.details)
rescue StandardError => e
  error(e.message, 'ERROR', e.backtrace.first(3).join("\n"))
end
