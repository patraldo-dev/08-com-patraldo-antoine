#!/bin/bash
# Generate ElevenLabs API payloads for all 3 languages
# Outputs: en_dialogue.json, es_dialogue.json, fr_dialogue.json

# English (StarryEyedLady)
cat > en_dialogue.json <<'EOF'
[
  {
    "text": "He's so dreamy.",
    "voice_id": "T7eLpgAAhoXHlrNajG8v",
    "start_time": 10.0,
    "duration": 3.5,
    "stability": 0.75,
    "similarity_boost": 0.75,
    "style": 0.0,
    "use_speaker_boost": true
  },
  {
    "text": "I wish he were mine. He doesn't even see me.",
    "voice_id": "T7eLpgAAhoXHlrNajG8v",
    "start_time": 21.0,
    "duration": 6.0,
    "stability": 0.65,
    "similarity_boost": 0.85,
    "style": 0.2,
    "use_speaker_boost": true
  },
  {
    "text": "Wait, who's that?",
    "voice_id": "T7eLpgAAhoXHlrNajG8v",
    "start_time": 47.5,
    "duration": 3.0,
    "stability": 0.85,
    "similarity_boost": 0.9,
    "style": 0.0,
    "use_speaker_boost": true
  }
]
EOF

# Mexican Spanish (StarryEyedLady_ES)
cat > es_dialogue.json <<'EOF'
[
  {
    "text": "Es tan guapo.",
    "voice_id": "jAAHNNqlbAX9iWjJPEtE",
    "start_time": 10.0,
    "duration": 3.2,
    "stability": 0.7,
    "similarity_boost": 0.8,
    "style": 0.1,
    "use_speaker_boost": true
  },
  {
    "text": "Ojalá fuera mío. Ni siquiera me ve.",
    "voice_id": "jAAHNNqlbAX9iWjJPEtE",
    "start_time": 21.0,
    "duration": 6.5,
    "stability": 0.6,
    "similarity_boost": 0.85,
    "style": 0.3,
    "use_speaker_boost": true
  },
  {
    "text": "Espera, ¿quién es esa?",
    "voice_id": "jAAHNNqlbAX9iWjJPEtE",
    "start_time": 47.5,
    "duration": 3.3,
    "stability": 0.8,
    "similarity_boost": 0.9,
    "style": 0.1,
    "use_speaker_boost": true
  }
]
EOF

# Canadian French (StarryEyedLady_FR)
cat > fr_dialogue.json <<'EOF'
[
  {
    "text": "Il est tellement charmant.",
    "voice_id": "rCmVtv8cYU60uhlsOo1M",
    "start_time": 10.0,
    "duration": 3.8,
    "stability": 0.75,
    "similarity_boost": 0.75,
    "style": 0.0,
    "use_speaker_boost": true
  },
  {
    "text": "J'aimerais tellement qu'il soit à moi. Il ne me voit même pas.",
    "voice_id": "rCmVtv8cYU60uhlsOo1M",
    "start_time": 21.0,
    "duration": 6.2,
    "stability": 0.65,
    "similarity_boost": 0.8,
    "style": 0.25,
    "use_speaker_boost": true
  },
  {
    "text": "Attends, qui est-ce?",
    "voice_id": "rCmVtv8cYU60uhlsOo1M",
    "start_time": 47.5,
    "duration": 2.8,
    "stability": 0.85,
    "similarity_boost": 0.9,
    "style": 0.05,
    "use_speaker_boost": true
  }
]
EOF

echo "✅ Generated trilingual dialogue files:"
echo "   - en_dialogue.json (English)"
echo "   - es_dialogue.json (Mexican Spanish)"
echo "   - fr_dialogue.json (Canadian French)"
echo
echo "➡️  Next steps:"
echo "1. Pick voices in ElevenLabs for each language:"
echo "   • English:      https://elevenlabs.io/app/voice-library?category=premade"
echo "   • Mexican Spanish: search 'Mexican Spanish' voices"
echo "   • Canadian French: search 'Canadian French' or 'Québécois' voices"
echo "2. Replace placeholders in JSON files:"
echo "   • EN_VOICE_ID_PLACEHOLDER → actual English voice ID"
echo "   • ES_VOICE_ID_PLACEHOLDER → actual Mexican Spanish voice ID"
echo "   • FR_VOICE_ID_PLACEHOLDER → actual Canadian French voice ID"
echo "3. Run your API calls (example for English):"
echo "   curl -X POST 'https://api.elevenlabs.io/v1/text-to-speech/ANY_VOICE' \\"
echo "        -H 'xi-api-key: YOUR_API_KEY' \\"
echo "        -H 'Content-Type: application/json' \\"
echo "        -d '@en_dialogue.json' --output star_en.mp3"
