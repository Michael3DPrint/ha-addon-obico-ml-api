#!/bin/sh
# Start the official Obico ML API. Refuses to run without a token of 16+ chars,
# because upstream silently disables authentication when the token is empty.
set -eu

OPTIONS=/data/options.json
TOKEN=$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1])).get("ml_api_token",""))' "$OPTIONS")

if [ "${#TOKEN}" -lt 16 ]; then
    echo "ERROR: set 'ml_api_token' (at least 16 characters) in the add-on configuration." >&2
    exit 1
fi

export ML_API_TOKEN="$TOKEN"
cd /app
exec gunicorn --bind 0.0.0.0:3333 --workers 1 --timeout 120 wsgi
