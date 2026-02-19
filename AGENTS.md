# twilio-sms

```
cd ~/tools/twilio-sms
bundle exec ruby sms.rb <command> [options]
```

## Commands

```
list     [--from NUMBER] [--to NUMBER] [--since DATE] [--until DATE] [--limit N]
get      --sid SID
threads  [--my-number NUMBER] [--partner NUMBER] [--since DATE] [--limit N]
send     --to NUMBER [--body TEXT] [--from NUMBER] [--messaging-service SID] [--media-url URL ...]
numbers  [--limit N]
```

## Examples

```bash
bundle exec ruby sms.rb list --limit 5
bundle exec ruby sms.rb list --from "+15551234567" --since "2025-01-01"
bundle exec ruby sms.rb get --sid SM1234567890abcdef
bundle exec ruby sms.rb threads --partner "+15559876543"
bundle exec ruby sms.rb send --to "+15559876543" --body "Hello"
bundle exec ruby sms.rb send --to "+15559876543" --media-url "https://example.com/img.jpg"
bundle exec ruby sms.rb numbers
```

## Notes

- `send` is the only mutating command
- `--media-url` can be repeated (max 10)
- `--messaging-service` or `TWILIO_MESSAGING_SERVICE_SID` preferred for A2P 10DLC
- `threads` defaults `--my-number` to `TWILIO_DEFAULT_NUMBER`
- Output: JSON `{ok, data}` or `{ok, error, code}`
