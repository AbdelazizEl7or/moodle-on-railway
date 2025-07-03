#!/bin/bash

set -e

echo "🚀 Starting Moodle container with Apache..."

# Start Apache in the background to let Moodle auto-install via ENV vars
apache2-foreground &

# Wait until config.php is generated
until [ -f /var/www/html/config.php ]; do
  echo "⏳ Waiting for config.php to be generated..."
  sleep 2
done

echo "🔧 Patching config.php for HTTPS and proxy support..."

# Update wwwroot to use HTTPS domain
sed -i "s|^\$CFG->wwwroot\s*=.*|\$CFG->wwwroot = 'https://theme.magicmoodle.com';|" /var/www/html/config.php

# Append sslproxy = true if not set
if ! grep -q "\$CFG->sslproxy" /var/www/html/config.php; then
  echo "\$CFG->sslproxy = true;" >> /var/www/html/config.php
fi

# Kill background Apache so we can restart it cleanly in foreground
killall apache2

echo "✅ config.php patched. Starting Apache in foreground..."
exec apache2-foreground
