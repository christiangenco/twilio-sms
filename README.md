# twilio-sms

Thin wrapper around the official [Twilio CLI](https://www.twilio.com/docs/twilio-cli) with a custom `twilio-threads` script for conversation threading (which Twilio doesn't support natively).

## Setup

```bash
brew tap twilio/brew && brew install twilio
twilio profiles:create YOUR_ACCOUNT_SID --auth-token YOUR_AUTH_TOKEN -p default
twilio profiles:use default
```

## Usage

All standard Twilio operations use the official CLI directly (see `AGENTS.md` for examples). The only custom script is:

### twilio-threads

Groups inbound + outbound messages into conversation threads by partner number.

```bash
twilio-threads                                    # All threads for default number
twilio-threads --number +18172032087              # Different Twilio number
twilio-threads --partner "+1234567890"            # Single conversation
twilio-threads --since "2025-06-01" --limit 100   # Date filter + limit
```

Outputs JSON with threads sorted by most recent message.

## Phone Numbers

```bash
# List owned numbers
twilio api:core:incoming-phone-numbers:list -o json

# Search available numbers to buy
twilio api:core:available-phone-numbers:local:list --country-code US --area-code 817 -o json

# Buy a number
twilio api:core:incoming-phone-numbers:create --phone-number "+1XXXXXXXXXX" -o json

# Release (delete) a number
twilio api:core:incoming-phone-numbers:remove --sid PNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

## Configure Webhooks

```bash
# Set SMS webhook URL on a number
twilio api:core:incoming-phone-numbers:update \
  --sid PNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX \
  --sms-url "https://example.com/sms" \
  --sms-method POST -o json

# Set voice webhook URL on a number
twilio api:core:incoming-phone-numbers:update \
  --sid PNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX \
  --voice-url "https://example.com/voice" \
  --voice-method POST -o json
```

## Messaging Services

```bash
# List messaging services
twilio api:messaging:v1:services:list -o json

# Send via messaging service (for A2P 10DLC compliance)
twilio api:core:messages:create \
  --messaging-service-sid MGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX \
  --to "+1234567890" --body "Hello" -o json
```

## Account & Billing

```bash
# Account info
twilio api:core:accounts:fetch -o json

# Usage records (billing)
twilio api:core:usage:records:list --category sms -o json
```
