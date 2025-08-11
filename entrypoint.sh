#!/bin/bash
set -Eeuo pipefail

log() { echo -e "$*"; }

# ---------- Ensure moodledata volume and structure ----------
log "📁 Ensuring /var/www/moodledata (volume) exists & is writable..."
mkdir -p /var/www/moodledata/{filedir,temp,trashdir}
# Guarded chown/chmod
if [ -d /var/www/moodledata ]; then
  chown -R www-data:www-data /var/www/moodledata || true
  chmod -R 0777 /var/www/moodledata || true
fi

# Seed from image defaults on first boot (optional)
if [ ! -d /var/www/moodledata/filedir ] || [ -z "$(ls -A /var/www/moodledata/filedir 2>/dev/null || true)" ]; then
  if [ -d /usr/src/moodledata ] && [ -n "$(ls -A /usr/src/moodledata 2>/dev/null || true)" ]; then
    log "📦 Seeding moodledata from /usr/src/moodledata..."
    cp -R /usr/src/moodledata/* /var/www/moodledata/ || true
    chown -R www-data:www-data /var/www/moodledata || true
  fi
fi

# ---------- DB wait ----------
: "${MOODLE_DATABASE_HOST:?Missing MOODLE_DATABASE_HOST}"
: "${MOODLE_DATABASE_PORT_NUMBER:=3306}"
log "🛠 Waiting for database at ${MOODLE_DATABASE_HOST}:${MOODLE_DATABASE_PORT_NUMBER}..."
until php -r '
$mysqli = @new mysqli(
  getenv("MOODLE_DATABASE_HOST"),
  getenv("MOODLE_DATABASE_USER"),
  getenv("MOODLE_DATABASE_PASSWORD"),
  getenv("MOODLE_DATABASE_NAME"),
  (int)getenv("MOODLE_DATABASE_PORT_NUMBER")
);
exit($mysqli && !$mysqli->connect_errno ? 0 : 1);
'; do
  log "⏳ DB not ready, retrying in 3s..."
  sleep 3
done

# ---------- Apache proxy + port 8080 ----------
log "🛠 Configuring Apache for port 8080 & proxy headers..."
sed -i 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf || true
sed -i 's/^<VirtualHost \*:80>/<VirtualHost *:8080>/' /etc/apache2/sites-enabled/000-default.conf || true
a2enmod remoteip setenvif >/dev/null 2>&1 || true
if ! grep -q "RemoteIPHeader X-Forwarded-For" /etc/apache2/sites-enabled/000-default.conf; then
  sed -i '/<VirtualHost \*:8080>/a \
    RemoteIPHeader X-Forwarded-For\n\
    RemoteIPInternalProxy 127.0.0.1\n\
    RemoteIPInternalProxy 100.64.0.0/10\n\
    SetEnvIf X-Forwarded-Proto https HTTPS=on' /etc/apache2/sites-enabled/000-default.conf
fi

# ---------- Install on first run ----------
MOODLE_WWWROOT="${MOODLE_WWWROOT:-https://magiclms.store}"
CONFIG="/var/www/html/config.php"

if [ ! -f "$CONFIG" ]; then
  log "🚀 Running Moodle CLI install..."
  php admin/cli/install.php \
    --lang="${MOODLE_LANG:-en}" \
    --wwwroot="${MOODLE_WWWROOT}" \
    --dataroot="/var/www/moodledata" \
    --dbtype="${MOODLE_DATABASE_TYPE:-mariadb}" \
    --dbname="${MOODLE_DATABASE_NAME}" \
    --dbuser="${MOODLE_DATABASE_USER}" \
    --dbpass="${MOODLE_DATABASE_PASSWORD}" \
    --dbhost="${MOODLE_DATABASE_HOST}" \
    --dbport="${MOODLE_DATABASE_PORT_NUMBER}" \
    --fullname="${MOODLE_SITE_NAME:-Magic LMS}" \
    --shortname="${MOODLE_SITE_NAME:-Magic LMS}" \
    --adminuser="${MOODLE_USERNAME:-admin}" \
    --adminpass="${MOODLE_PASSWORD:-Admin123!}" \
    --adminemail="${MOODLE_EMAIL:-admin@example.com}" \
    --agree-license --non-interactive
  log "✅ Installed."
else
  log "✅ config.php exists, skipping install."
fi

# ---------- Enforce config (wwwroot/dataroot/sslproxy) ----------
log "🔧 Enforcing wwwroot/dataroot/sslproxy in config.php..."
# wwwroot
sed -i "s|^\(\$CFG->wwwroot\s*=\s*\).*$|\1'${MOODLE_WWWROOT}';|" "$CONFIG"
# dataroot
if grep -q "^\$CFG->dataroot" "$CONFIG"; then
  sed -i "s|^\(\$CFG->dataroot\s*=\s*\).*$|\1'/var/www/moodledata';|" "$CONFIG"
else
  printf "\n\$CFG->dataroot = '/var/www/moodledata';\n" >> "$CONFIG"
fi
# sslproxy
if grep -q "^\$CFG->sslproxy" "$CONFIG"; then
  sed -i "s|^\(\$CFG->sslproxy\s*=\s*\).*$|\1true;|" "$CONFIG"
else
  printf "\n\$CFG->sslproxy = true;\n" >> "$CONFIG"
fi

# ---------- Final permissions (guarded) ----------
log "🔐 Fixing permissions..."
if [ -d /var/www/html ]; then
  chown -R www-data:www-data /var/www/html || true
  find /var/www/html -type d -exec chmod 755 {} \; || true
  find /var/www/html -type f -exec chmod 644 {} \; || true
fi
if [ -d /var/www/moodledata ]; then
  chown -R www-data:www-data /var/www/moodledata || true
  chmod -R 0777 /var/www/moodledata || true
fi

# ---------- Start ----------
log "🌀 Starting Apache…"
exec apache2-foreground
