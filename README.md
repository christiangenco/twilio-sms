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
