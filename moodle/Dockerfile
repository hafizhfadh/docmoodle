FROM bitnami/moodle:latest

# Install any necessary packages
USER root

# Install the PHP Redis extension (if not already installed)
RUN install_packages php-redis

# Copy custom initialization scripts
COPY init_scripts/ /docker-entrypoint-init.d/
RUN chmod +x /docker-entrypoint-init.d/*

USER 1001
