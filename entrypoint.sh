#!/bin/bash

set -e

# Wait until Moodle auto-generates config.php
until [ -f /var/www/html/config.php ]; do
  echo "⏳ Waiting for config.php to be generated..."
  sleep 1
done

# Inject https and sslproxy config
echo "🔧 Patching config.php with correct wwwroot and sslproxy"
sed -i "s|^\$CFG->wwwroot\s*=.*|\$CFG->wwwroot = 'https://theme.magicmoodle.com';|" /var/www/html/config.php

# Add sslproxy if not present
grep -q "\$CFG->sslproxy" /var/www/html/config.php || \
  echo "\$CFG->sslproxy = true;" >> /var/www/html/config.php

# Start Apache
exec apache2-foreground
