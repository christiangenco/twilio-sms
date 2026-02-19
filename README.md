# twilio-sms

CLI for sending and receiving SMS/MMS via Twilio. Outputs JSON for easy parsing.

## Setup

```bash
bundle install
```

Create `.env`:

```
TWILIO_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_TOKEN=your_auth_token
TWILIO_DEFAULT_NUMBER=+15551234567
TWILIO_MESSAGING_SERVICE_SID=MGxxxxxxxx  # optional, for A2P 10DLC
```

## Usage

```bash
# List recent messages
bundle exec ruby sms.rb list --limit 10
bundle exec ruby sms.rb list --from "+15551234567" --since "2025-01-01"

# Get a single message (with media info)
bundle exec ruby sms.rb get --sid SMxxxxxxxx

# View conversation threads
bundle exec ruby sms.rb threads
bundle exec ruby sms.rb threads --partner "+15559876543" --since "2025-06-01"

# Send a message
bundle exec ruby sms.rb send --to "+15559876543" --body "Hello!"
bundle exec ruby sms.rb send --to "+15559876543" --body "Check this out" --media-url "https://example.com/image.jpg"

# List account phone numbers
bundle exec ruby sms.rb numbers
```

All output is single-line JSON with `{ok: true, data: ...}` or `{ok: false, error: ...}`.
