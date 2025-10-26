#!/bin/bash
set -e

# Create virtual environment if not exists
if [ ! -d "flaskenv" ]; then
    python3 -m venv flaskenv
fi

# Activate virtual environment
source flaskenv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt

# Print next steps
cat << EOF

[INFO] Dependencies installed!

Next steps:
1. Set environment variables (see README.md):
   export SECRET_KEY=your_secret_key
   export SQLALCHEMY_DATABASE_URI=your_db_uri
   export FLASK_APP=main.py
   export FLASK_ENV=production
2. Initialize your database if not done:
   mysql -u <user> -p < db/novari_06.sql
3. To run the app:
   source flaskenv/bin/activate
   flask run --host 0.0.0.0 --port 5000

Or use the provided start_site_demon.sh for Gunicorn/nginx setup.
EOF 