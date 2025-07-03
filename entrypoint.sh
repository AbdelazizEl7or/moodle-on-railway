#!/bin/bash
set -e

# 1) If config.php is missing, run the CLI installer once
if [ ! -f /var/www/html/config.php ]; then
  echo "🚀 Running Moodle CLI installer…"

  php admin/cli/install.php \
    --lang=en \
    --wwwroot="${MOODLE_WWWROOT}" \
    --dataroot="/var/www/moodledata" \
    --dbtype="${MOODLE_DATABASE_TYPE}" \
    --dbname="${MOODLE_DATABASE_NAME}" \
    --dbuser="${MOODLE_DATABASE_USER}" \
    --dbpass="${MOODLE_DATABASE_PASSWORD}" \
    --dbhost="${MOODLE_DATABASE_HOST}" \
    --dbport="${MOODLE_DATABASE_PORT_NUMBER}" \
    --fullname="${MOODLE_SITE_NAME}" \
    --shortname="${MOODLE_SITE_NAME}" \
    --adminuser="${MOODLE_USERNAME}" \
    --adminpass="${MOODLE_PASSWORD}" \
    --adminemail="${MOODLE_EMAIL}" \
    --agree-license --non-interactive

  echo "✅ Installer done. Generated config.php"
fi

# 2) Hand off to Apache (foreground)
echo "🌀 Starting Apache…"
exec apache2-foreground
