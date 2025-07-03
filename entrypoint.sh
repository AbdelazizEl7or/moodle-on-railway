#!/bin/bash

set -e

echo "🚀 Starting Moodle container..."

if [ ! -f /var/www/html/config.php ]; then
  echo "🔧 No config.php found. Launching for first-time browser-based install..."
else
  echo "✅ config.php exists. Proceeding to patch and launch..."
  sed -i "s|^\$CFG->wwwroot\s*=.*|\$CFG->wwwroot = 'https://theme.magicmoodle.com';|" /var/www/html/config.php
  echo "\$CFG->sslproxy = true;" >> /var/www/html/config.php
fi

exec apache2-foreground
