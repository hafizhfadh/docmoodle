# Moodle Docker Deployment with Nginx, PostgreSQL, Redis, and PMM

This repository provides a comprehensive Docker Compose setup to deploy [Moodle](https://moodle.org/), an open-source learning platform, with the following components:

- **Nginx**: Reverse proxy and web server
- **Moodle**: The Moodle application container
- **PostgreSQL**: Percona Distribution for PostgreSQL as the database
- **Redis**: In-memory data structure store for caching and session management
- **PMM (Percona Monitoring and Management)**: Monitoring tool for PostgreSQL
- **SSL Support**: Secure your application with HTTPS using SSL certificates

This setup is designed for production environments running on **Ubuntu 22.04**.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Configure Environment Variables](#2-configure-environment-variables)
  - [3. Generate SSL Certificates](#3-generate-ssl-certificates)
  - [4. Configure Nginx](#4-configure-nginx)
  - [5. Build and Run Containers](#5-build-and-run-containers)
- [Services Overview](#services-overview)
  - [Nginx](#nginx)
  - [Moodle](#moodle)
  - [PostgreSQL](#postgresql)
  - [Redis](#redis)
  - [PMM Server](#pmm-server)
- [SSL Configuration](#ssl-configuration)
- [Monitoring with PMM](#monitoring-with-pmm)
- [Data Persistence](#data-persistence)
- [Security Considerations](#security-considerations)
- [Backup and Restore](#backup-and-restore)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Prerequisites

- **Ubuntu 22.04** server
- **Docker** and **Docker Compose** installed
- A registered **domain name** pointing to your server's public IP
- Ports **80** and **443** open on your firewall
- Basic knowledge of Docker and Docker Compose

---

## Project Structure

```plaintext
├── docker-compose.yml
├── moodle/
├── nginx/
│   ├── certs/
│   ├── conf.d/
│   │   └── default.conf
│   └── nginx.conf
├── postgresql/
│   ├── conf.d/
│   │   └── postgresql.conf
│   ├── Dockerfile
│   ├── pmm-entrypoint.sh
│   └── sql/
│       └── init.sql
├── redis/
│   └── redis.conf
└── README.md
```

- **docker-compose.yml**: Docker Compose configuration file
- **moodle/**: Contains Moodle-related configurations (if any)
- **nginx/**: Nginx configuration and SSL certificates
- **postgresql/**: PostgreSQL configuration, Dockerfile, and initialization scripts
- **redis/**: Redis configuration

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/hafizhfadh/docmoodle.git
cd docmoodle
```

### 2. Configure Environment Variables

Update the `docker-compose.yml` file and replace placeholders with your actual values:

- **Domain Name**: Replace `your-domain.com` with your actual domain.
- **Passwords**: Replace `moodlepass`, `redispass`, and other passwords with strong, unique passwords.

### 3. Generate SSL Certificates

#### Option 1: Using Let's Encrypt (Recommended for Production)

Install Certbot and obtain certificates:

```bash
sudo apt update
sudo apt install certbot
sudo certbot certonly --standalone -d your-domain.com --agree-tos --email your-email@example.com --non-interactive
```

Copy the certificates to the Nginx certs directory:

```bash
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem nginx/certs/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem nginx/certs/
sudo chown $(whoami):$(whoami) nginx/certs/*.pem
sudo chmod 600 nginx/certs/*.pem
```

#### Option 2: Creating Self-Signed Certificates (For Testing/Development)

```bash
mkdir -p nginx/certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/certs/self-signed.key \
  -out nginx/certs/self-signed.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=your-domain.com"
```

Update `default.conf` accordingly.

### 4. Configure Nginx

Update `nginx/conf.d/default.conf` with your domain and SSL certificate paths.

```nginx
server {
    listen       80;
    server_name  your-domain.com;
    return       301 https://$host$request_uri;
}

server {
    listen       443 ssl;
    server_name  your-domain.com;

    ssl_certificate     /etc/ssl/certs/fullchain.pem;
    ssl_certificate_key /etc/ssl/certs/privkey.pem;

    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://moodle:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### 5. Build and Run Containers

```bash
docker-compose up -d
```

---

## Services Overview

### Nginx

- Acts as a reverse proxy to route traffic to the Moodle container.
- Handles SSL termination.
- Configuration files located in `nginx/`.

### Moodle

- Based on the Bitnami Moodle Docker image.
- Configured to use PostgreSQL and Redis.
- Environment variables set in `docker-compose.yml`.

### PostgreSQL

- Uses Percona Distribution for PostgreSQL.
- Custom `Dockerfile` builds the image with PMM client.
- Configuration and initialization scripts in `postgresql/`.

### Redis

- Provides caching and session storage for Moodle.
- Configured with a password for security.
- Configuration file located at `redis/redis.conf`.

### PMM Server

- Monitors the PostgreSQL database performance.
- Accessible at `http://your-domain.com:8083`.
- Default credentials are `admin` / `admin` (change immediately after deployment).

---

## SSL Configuration

- SSL certificates are stored in `nginx/certs/`.
- Nginx is configured to redirect all HTTP traffic to HTTPS.
- Ensure certificates are kept up to date (automate renewal if using Let's Encrypt).

---

## Monitoring with PMM

- PMM Server collects metrics from PostgreSQL.
- PMM client is installed in the PostgreSQL container via the custom `Dockerfile`.
- Access PMM Server at `http://your-domain.com:8083`.

---

## Data Persistence

The following volumes are used for data persistence:

- `postgres_data`: PostgreSQL data directory
- `moodle_data`: Moodle application data
- `moodle_moodledata`: Moodle data directory
- `redis_data`: Redis data
- `pmm-data`: PMM Server data

Ensure regular backups of these volumes to prevent data loss.

---

## Security Considerations

- **Passwords**: Use strong, unique passwords for all services.
- **Firewall**: Allow only necessary ports (80, 443, 8083) and block others.
- **SSL**: Always use HTTPS in production.
- **Access Control**: Limit access to PMM Server and other management interfaces.
- **Updates**: Keep Docker images and dependencies up to date.

---

## Backup and Restore

### Backup

To back up your data volumes:

```bash
docker run --rm --volumes-from postgres -v $(pwd):/backup ubuntu tar cvf /backup/postgres_data.tar /var/lib/postgresql/data
docker run --rm --volumes-from moodle -v $(pwd):/backup ubuntu tar cvf /backup/moodle_data.tar /bitnami/moodle
docker run --rm --volumes-from moodle -v $(pwd):/backup ubuntu tar cvf /backup/moodle_moodledata.tar /bitnami/moodledata
```

### Restore

To restore your data volumes:

```bash
docker run --rm --volumes-from postgres -v $(pwd):/backup ubuntu bash -c "cd /var/lib/postgresql/data && tar xvf /backup/postgres_data.tar --strip 1"
docker run --rm --volumes-from moodle -v $(pwd):/backup ubuntu bash -c "cd /bitnami/moodle && tar xvf /backup/moodle_data.tar --strip 1"
docker run --rm --volumes-from moodle -v $(pwd):/backup ubuntu bash -c "cd /bitnami/moodledata && tar xvf /backup/moodle_moodledata.tar --strip 1"
```

---

## Troubleshooting

- **Containers Not Starting**: Check logs using `docker-compose logs -f`.
- **Cannot Access Moodle**: Ensure Nginx is properly configured and SSL certificates are valid.
- **Database Connection Errors**: Verify PostgreSQL is running and accessible from the Moodle container.
- **PMM Metrics Not Showing**: Ensure PMM client is properly installed and configured in the PostgreSQL container.
- **Permission Issues**: Ensure correct permissions on mounted volumes and SSL certificates.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [Moodle](https://moodle.org/)
- [Bitnami Docker Images](https://hub.docker.com/u/bitnami)
- [Percona Distribution for PostgreSQL](https://www.percona.com/software/postgresql-distribution)
- [Percona Monitoring and Management](https://www.percona.com/software/database-tools/percona-monitoring-and-management)
- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)

---

**Note**: Replace placeholders like `your-domain.com`, `your-email@example.com`, and adjust paths as per your actual setup.

If you encounter any issues or have questions, please open an issue on this repository.

Happy Learning! 📚