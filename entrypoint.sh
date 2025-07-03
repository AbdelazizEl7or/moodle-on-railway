#!/bin/bash

set -e

echo "🚀 Starting Moodle container..."

# Wait until config.php is generated
until [ -f /var/www/html/config.php ]; do
  echo "⏳ Waiting for config.php to be generated..."
  sleep 2
done

echo "🔧 Patching config.php for HTTPS and proxy support..."

# Force wwwroot to use HTTPS
sed -i "s|^\$CFG->wwwroot\s*=.*|\$CFG->wwwroot = 'https://theme.magicmoodle.com';|" /var/www/html/config.php

# Ensure sslproxy = true is set
if ! grep -q "\$CFG->sslproxy" /var/www/html/config.php; then
  echo "\$CFG->sslproxy = true;" >> /var/www/html/config.php
fi

echo "✅ config.php patched. Running Apache..."
exec apache2-foreground
