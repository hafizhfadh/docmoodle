FROM percona/percona-distribution-postgresql:15

# Install PMM Client
RUN yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm && \
    percona-release setup pmm && \
    yum install -y pmm2-client

# Copy configuration files and scripts
COPY conf.d/postgresql.conf /etc/postgresql/postgresql.conf
COPY sql/init.sql /docker-entrypoint-initdb.d/init.sql
COPY pmm-entrypoint.sh /docker-entrypoint-initdb.d/pmm-entrypoint.sh

# Ensure scripts are executable
RUN chmod +x /docker-entrypoint-initdb.d/pmm-entrypoint.sh
