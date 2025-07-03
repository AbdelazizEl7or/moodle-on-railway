#!/bin/bash
set -e

# === Static configuration (hardcoded values) ===
MOODLE_WWWROOT="https://theme.magicmoodle.com"
MOODLE_DATABASE_TYPE="mysqli"
MOODLE_DATABASE_HOST="turntable.proxy.rlwy.net"
MOODLE_DATABASE_PORT_NUMBER="48014"
MOODLE_DATABASE_NAME="railway"
MOODLE_DATABASE_USER="root"
MOODLE_DATABASE_PASSWORD="WXnHQtLLhrfFVcTmXzqkSJDeLSvbuTPP"
MOODLE_SITE_NAME="Magic Moodle"
MOODLE_USERNAME="admin"
MOODLE_PASSWORD="Admin123!"
MOODLE_EMAIL="admin@example.com"

# === Patch Apache to listen on 8080 for Railway/Render ===
echo "🛠 Patching Apache to listen on 8080..."
sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf
sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8080>/g' /etc/apache2/sites-enabled/000-default.conf

echo "📁 Ensuring moodledata exists and is writable..."
if [ ! -d "/var/www/moodledata" ]; then
  mkdir -p /var/www/moodledata
fi
chown -R www-data:www-data /var/www/moodledata
chmod -R 777 /var/www/moodledata

# 1) If config.php is missing, run the CLI installer once
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
fi

# 2) Hand off to Apache (foreground)
echo "🌀 Starting Apache…"
exec apache2-foreground
