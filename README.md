# Novari Flask Application

## Prerequisites

- Python 3.10+ and `pip`
- MariaDB or MySQL server
- (optional) nginx if using `start_site_demon.sh`

## Setup

1. **Clone the repository** and navigate into it.
2. **Create and activate a virtual environment**:
   ```bash
   python3 -m venv flaskenv
   source flaskenv/bin/activate
   ```
3. **Install dependencies** (if a `requirements.txt` is added, install from it). Currently the virtual environment directory `flaskenv/` is committed for convenience, but creating your own is recommended.

### Environment variables

Set the following variables before running the app:

- `SECRET_KEY` – Flask secret key.
- `SQLALCHEMY_DATABASE_URI` – database connection string (e.g. `mysql+mysqlconnector://user:pass@localhost/novari_06`).
- `FLASK_APP` – entry point (`main.py`).
- `FLASK_ENV` – `development` or `production`.

You can export them in your shell or store them in an `.env` file loaded by your environment manager.

### Database initialization

Create the database and tables using the provided SQL dump:

```bash
mysql -u <user> -p < db/novari_06.sql
```

Alternatively, start the app once and SQLAlchemy will create tables automatically if the database exists.

## Running the application

Activate your virtual environment and start the Flask development server:

```bash
source flaskenv/bin/activate
flask run --host 0.0.0.0 --port 5000
```

This uses the environment variables defined above. The application code also defines `app.run` in `main.py` which will run on port 80 if executed directly with `python main.py`.

## Optional helper script

The repository contains `start_site_demon.sh` which launches the app with Gunicorn and restarts nginx. The script automatically locates the project directory based on its own location, so you can run it from anywhere.

Make the script executable and run it when needed:

```bash
chmod +x start_site_demon.sh
./start_site_demon.sh
```

Run it only if you have Gunicorn, nginx and MariaDB configured locally.
