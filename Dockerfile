FROM python:3.9-slim

WORKDIR /app

# Install system dependencies + netcat (for wait-for-db.sh)
RUN apt-get update && apt-get install -y \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create uploads directory if it doesn't exist
RUN mkdir -p uploads

# Expose port
EXPOSE 8001

# Default command (Gunicorn in production)
CMD ["gunicorn", "-w", "4", "-k", "gthread", "-b", "0.0.0.0:8001", "--threads", "2", "--timeout", "120", "main:app"]

