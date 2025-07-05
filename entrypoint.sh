#!/bin/bash
set -e

# === Wait for MySQL to be available ===
echo "🛠 Waiting for database connection at ${MOODLE_DATABASE_HOST}:${MOODLE_DATABASE_PORT_NUMBER}..."
until php -r '
$mysqli = new mysqli(
  getenv("MOODLE_DATABASE_HOST"),
  getenv("MOODLE_DATABASE_USER"),
  getenv("MOODLE_DATABASE_PASSWORD"),
  getenv("MOODLE_DATABASE_NAME"),
  (int)getenv("MOODLE_DATABASE_PORT_NUMBER")
);
if ($mysqli->connect_errno) {
  exit(1);
}
'
do
  echo "⏳ Database not ready, retrying in 3s..."
  sleep 3
done

echo "🛠 Patching Apache to listen on 8080..."
sed -i 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf
sed -i 's/^<VirtualHost \*:80>/<VirtualHost *:8080>/' /etc/apache2/sites-enabled/000-default.conf

# Ensure moodledata folder exists and is writable
echo "📁 Ensuring moodledata exists and is writable..."
mkdir -p /var/www/moodledata
chown -R www-data:www-data /var/www/moodledata
chmod -R 777 /var/www/moodledata

# 1) Run CLI installer if this is first launch
if [ ! -f /var/www/html/config.php ]; then
  echo "🚀 Running Moodle CLI installer…"
  php admin/cli/install.php \
    --lang=en \
    --wwwroot="$MOODLE_WWWROOT" \
    --dataroot="/var/www/moodledata" \
    --dbtype="$MOODLE_DATABASE_TYPE" \
    --dbname="$MOODLE_DATABASE_NAME" \
    --dbuser="$MOODLE_DATABASE_USER" \
    --dbpass="$MOODLE_DATABASE_PASSWORD" \
    --dbhost="$MOODLE_DATABASE_HOST" \
    --dbport="$MOODLE_DATABASE_PORT_NUMBER" \
    --fullname="$MOODLE_SITE_NAME" \
    --shortname="$MOODLE_SITE_NAME" \
    --adminuser="$MOODLE_USERNAME" \
    --adminpass="$MOODLE_PASSWORD" \
    --adminemail="$MOODLE_EMAIL" \
    --agree-license --non-interactive
  echo "✅ Installer done. Generated config.php"
else
  echo "✅ config.php found, skipping install."
fi

# 2) Start Apache in the foreground
echo "🌀 Starting Apache…"
exec apache2-foreground
