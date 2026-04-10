# twilio-sms-cli

Uses the official [Twilio CLI](https://www.twilio.com/docs/twilio-cli) (`twilio`) plus a custom `twilio-threads` script for conversation threading.

## Account Info

- Your Twilio number(s) are stored in `$TWILIO_FROM_NUMBER` (set in your shell profile or tool `.env`).
- CLI profile stored in `~/.twilio-cli/config.json` (includes Account SID + API key).

## Send & Receive Messages

```bash
# Send an SMS
twilio api:core:messages:create \
  --from "$TWILIO_FROM_NUMBER" --to "+15557654321" --body "Hello" -o json

# Send MMS (with media)
twilio api:core:messages:create \
  --from "$TWILIO_FROM_NUMBER" --to "+15557654321" --body "Check this out" \
  --media-url "https://example.com/image.jpg" -o json

# List recent messages
twilio api:core:messages:list --limit 20 -o json

# List messages from a specific number
twilio api:core:messages:list --from "$TWILIO_FROM_NUMBER" --limit 20 -o json

# List messages after a date
twilio api:core:messages:list --date-sent-after "2025-01-01" --limit 50 -o json

# Get a single message by SID
twilio api:core:messages:fetch --sid SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX -o json
```

## Conversation Threads

Twilio has no native threading. `twilio-threads` fetches inbound + outbound messages and groups them by conversation partner.

```bash
# All threads for default number (reads $TWILIO_FROM_NUMBER)
twilio-threads

# Threads for a specific number
twilio-threads --number +15551234567

# Single conversation with a partner
twilio-threads --partner "+15557654321"

# Messages since a date
twilio-threads --since "2025-06-01"

# Limit messages fetched per direction (default: 200)
twilio-threads --limit 50
```

## Tips

- Always use `-o json` for machine-readable output.
- Use `--limit N` to control how many results are returned.
- Run `twilio <command> --help` to see all available flags for any command.
