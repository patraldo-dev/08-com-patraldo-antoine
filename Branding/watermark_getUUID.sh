curl -X POST "https://api.cloudflare.com/client/v4/accounts/$/477082f5c9678c608889bd8f03f7b807stream/watermarks" \
  -H "Authorization: Bearer $"BPTFxeofyZo9eBpeE0kljHCdIY4NS6bQzzbI19N9 \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://yourdomain.com/path/to/watermark.png",
    "name": "My Studio Logo",
    "opacity": 0.5,
    "padding": 0.05,
    "scale": 0.15,
    "position": "lowerRight"
  }'

