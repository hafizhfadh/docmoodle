#!/bin/bash

echo "Configuring Redis cache for Moodle..."

cat >> /bitnami/moodle/config.php <<EOF

// Redis cache configuration
\$CFG->session_handler_class = '\\core\\session\\redis';
\$CFG->session_redis_host = 'redis';
\$CFG->session_redis_port = 6379;
\$CFG->session_redis_password = 'redispass';
\$CFG->session_redis_prefix = 'moodle_prod_';
\$CFG->cachestore_redis_server = 'redis';
\$CFG->cachestore_redis_port = 6379;
\$CFG->cachestore_redis_password = 'redispass';
EOF
