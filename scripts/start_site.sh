#!/bin/bash

echo "🔄 Starting Flask app behind Gunicorn..."

# Go to your project directory
cd ~/novaribb || {
  echo "❌ Project folder not found!"
  exit 1
}

# Activate virtual environment
if [ -f ~/flaskenv/bin/activate ]; then
  source ~/flaskenv/bin/activate
else
  echo "❌ Virtual environment not found at ~/flaskenv"
  exit 1
fi

# Kill existing Gunicorn process on port 8000
PORT=8000
PID=$(lsof -t -i:$PORT)
if [ -n "$PID" ]; then
  echo "⚠️ Port $PORT is in use by PID(s): $PID"
  fuser -k ${PORT}/tcp
fi

# Start Gunicorn with 2 workers in the background
echo "🚀 Launching Gunicorn with 2 workers..."
nohup gunicorn -w 2 -b 127.0.0.1:$PORT main:app > gunicorn.log 2>&1 &

# Restart NGINX to ensure proxy is live
echo "🔄 Restarting NGINX..."
sudo systemctl restart nginx

echo "✅ Site is now live at: https://novari.duckdns.org"

