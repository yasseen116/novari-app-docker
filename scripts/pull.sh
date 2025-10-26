#!/bin/bash

cd ~/novaribb  # or wherever your project lives

echo "🔄 Pulling latest changes from GitHub..."
git pull origin main

echo "🛑 Killing existing Gunicorn processes..."
pkill gunicorn

echo "🚀 Starting the server using start_server.sh..."
./start_site_demon.sh

echo "✅ Project updated and server restarted."
