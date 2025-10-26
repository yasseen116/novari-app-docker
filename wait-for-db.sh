#!/bin/sh
set -e

echo "Waiting for MySQL to start..."
until nc -z novari-db 3306; do
  sleep 2
done

echo "MySQL is up! Starting the app..."
exec "$@"

