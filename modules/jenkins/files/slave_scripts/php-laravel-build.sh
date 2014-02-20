#!/bin/bash -xe
# Build a Laravel/PHP distribution using composer.

cat >bootstrap/environment.php <<EOF
<?php
\$env = \$app->detectEnvironment(function()
{
  return 'dev';
});
EOF
curl -s https://getcomposer.org/installer | /usr/bin/php
php composer.phar install --prefer-dist