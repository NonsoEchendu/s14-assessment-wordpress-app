# S14 Assessment: Dockerized WordPress CI/CD

This project demonstrates a Dockerized WordPress application with a CI/CD pipeline, rollback capability, automated backups, and monitoring, deployed to an Ubuntu server.

## Table of Contents

- [Project Description](#project-description)
- [Setup Guide](#setup-guide)
    - [Prerequisites](#prerequisites)
    - [Server Setup](#server-setup)
    - [GitHub Actions Configuration](#github-actions-configuration)
    - [Nginx and SSL Setup](#nginx-and-ssl-setup)
    - [Automated Backups](#automated-backups)
    - [Monitoring Setup](#monitoring-setup)
- [Project Status](#project-status)
    - [What Works](#what-works)
    - [Areas for Improvement](#areas-for-improvement)
- [Screenshots](#screenshots)
- [License](#license)

## Project Description

This repository contains the code and configuration to deploy a WordPress application using Docker Compose. The deployment process is automated via GitHub Actions, which also includes a manual rollback mechanism. Data and the database are backed up daily using a server-side script. The application and server are monitored using Prometheus and Grafana with relevant exporters.

## Setup Guide

Follow these steps to set up and deploy the application.

### Prerequisites

* Git
* Docker and Docker Compose installed on your local machine.
* An Ubuntu server instance (e.g., AWS EC2) with SSH access.
* Docker and Docker Compose installed on your Ubuntu server.
* An SSH key pair for secure access to your server.
* A domain name pointing to your server's IP address (e.g., `your-website.com` and `monitoring.your-website.com`).
* A Slack workspace and webhook URL (for notifications).

### Server Setup

1.  **Connect to your Ubuntu server via SSH** using your SSH key.
    ```bash
    ssh -i your-key-pair.pem ubuntu@your-ip-address
    ```
2.  **Ensure Docker and Docker Compose are installed.** If not, follow the [official Docker documentation for Ubuntu](https://docs.docker.com/engine/install/ubuntu/).
3.  **Clone the repository:**
    ```bash
    git clone [https://github.com/NonsoEchendu/s14-assessment-wordpress-app.git](https://github.com/NonsoEchendu/s14-assessment-wordpress-app.git)
    cd s14-assessment-wordpress-app
    ```

4.  **Configure environment variables:**
    Create a `.env` file in the project root directory from the `.env.example` file and fill in your desired database credentials.

    ```bash
    cp .env.example .env
    ```

    The .env file would look like this:
    ```bash
    MYSQL_ROOT_PASSWORD=mysql_root_password
    MYSQL_DATABASE=wordpress
    MYSQL_USER=wordpress
    MYSQL_PASSWORD=wordpress_db_password
    
    WORDPRESS_DB_HOST=db:3306
    WORDPRESS_DB_USER=${MYSQL_USER}
    WORDPRESS_DB_PASSWORD=${MYSQL_PASSWORD}
    WORDPRESS_DB_NAME=${MYSQL_DATABASE}
    ```

### GitHub Actions Configuration

1.  **Add Repository Secrets:** Go to your GitHub repository -> **Settings** -> **Secrets and variables** -> **Actions**. Add the following repository secrets:
    * `SERVER_HOST`: Your server's IP address or hostname.
    * `SERVER_USERNAME`: The SSH user on your server (e.g., `ubuntu`).
    * `SSH_PRIVATE_KEY`: The **entire content** of the private SSH key you will use for deployment (including `-----BEGIN...-----` and `-----END...-----`).
    * `SLACK_WEBHOOK_URL`: Your Slack webhook URL. Check th

2.  **Ensure Workflow Files are in `.github/workflows/`:** Verify that `deploy.yml` and `rollback.yml` are in the `.github/workflows/` directory.

3.  **Perform the initial deployment:** Push your code to the `main` branch or manually trigger the `Deploy Wordpress App` workflow in the GitHub Actions tab.

### Nginx and SSL Setup

Configure Nginx on your Ubuntu server to act as a reverse proxy for your Dockerized WordPress application and your Grafana dashboard.

1.  **Install Nginx:**
2.  ```bash
    sudo apt update
    sudo apt install nginx -y
    ```
4.  **Copy Nginx configuration files** from `nginx.conf` to `/etc/nginx/sites-available/wordpress` for your WordPress site.
5.  **Enable the configurations** by creating symlinks in `/etc/nginx/sites-enabled/`.
   ```bash
   sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
   ```

7.  **Test Nginx config:** `sudo nginx -t`
8.  **Install Certbot:**
    ```bash
    sudo apt update
    sudo apt install certbot python3-certbot-nginx
    ```
    
9.  Obtain SSL certificates for both your WordPress domain (`your-website.com`) and your monitoring subdomain (`monitoring.your-website.com`). Certbot will automatically configure Nginx for SSL:
    ```bash
    sudo certbot --nginx -d your-website.com -d www.your-website.com
    sudo certbot --nginx -d monitoring.your-website.com -d www.monitoring.your-website.com
    ```
    
10.  **Reload Nginx:** `sudo systemctl reload nginx`

### Automated Backups

1.  **Place the `backup.sh` script** on your Ubuntu server (e.g., in your home directory: `~/backup.sh`).
2.  **Make the script executable:** `chmod +x ~/backup.sh`
3.  **Edit the script** to ensure paths (`APP_DIR`, `BACKUP_ROOT_DIR`) and service names match your setup.
4.  **Set up a daily cron job** to run the script: `crontab -e`, then add a line like `0 2 * * * /bin/bash /home/ubuntu/backup.sh` (adjust time and path as needed).
5.  **Refer to the restoration guide** `how-to-restore-backup.txt` in the `backup` folder for how to restore from these backups.

### Monitoring Setup

Ensure Prometheus, Grafana, Node Exporter, and Blackbox Exporter are installed and running on your Ubuntu server as system services or via Docker Compose.

For a guide on how to setup these monitoring tools, checkout [this article](https://dev.to/nonso_echendu_001/mastering-modern-monitoring-a-comprehensive-guide-to-grafana-prometheus-and-dora-metrics-20ec) i wrote on it.

1.  **Install/Configure Monitoring Services:** Follow the documentation for installing and configuring Prometheus, Grafana, Node Exporter, and Blackbox Exporter on Ubuntu.
2.  **Configure Prometheus** (`/etc/prometheus/prometheus.yml`) to scrape metrics from Node Exporter (`localhost:9100`) and Blackbox Exporter (`localhost:9115`) using the Blackbox exporter's `/probe` endpoint to check your WordPress site.
3.  **Start/Restart Prometheus and Exporter services.**
4.  **Log in to Grafana** (`http://your-server-ip:3000` or `https://monitoring.your-website.comh` if using Nginx).
5.  **Add Prometheus as a data source** in Grafana.
6.  **Import dashboards** (e.g., Node Exporter Full ID 1860, Blackbox Exporter ID 7587) and/or create your own dashboards and alerts (like the CPU usage alert).

## Project Status

### What Works

* Dockerized WordPress and MySQL application setup using Docker Compose.
* Automated deployment of the latest `main` branch code to the Ubuntu server via GitHub Actions on push events.
* Manual deployment triggering via GitHub Actions (`workflow_dispatch`).
* Secure deployment using SSH key authentication instead of passwords.
* Manual rollback capability to a specific Git tag via a separate GitHub Actions workflow (`rollback.yml`).
* Automated rollback trigger from the deployment workflow (`deploy.yml`) to the rollback workflow (`rollback.yml`) if the deployment verification step fails.
* Automated daily backups of WordPress files and database using a server-side script and cron.
* Basic monitoring of server resources (CPU, Memory, Disk) using Prometheus and Node Exporter.
* Basic application availability monitoring (checking if the site is reachable) using Prometheus and Blackbox Exporter.
* Grafana dashboard for visualizing collected metrics.
* Grafana alert configured for high CPU usage.
* Nginx reverse proxy serving the WordPress site and Grafana dashboard with SSL certificates managed by Certbot.

### Areas for Improvement

With more time, the following areas could be improved:

* **More Robust CI Pipeline:** Improve the CI workflow to run code quality checks, linting, and unit tests on development/feature branches before merging to `main`.
* **Enhanced Deployment Verification:** Add more comprehensive application-level health checks in the deployment pipeline (e.g., checking for a successful HTTP response from the WordPress site, database connection checks from within the application container).
* **More Comprehensive Rollback:** Develop a more robust rollback strategy that includes handling data volume snapshots or database point-in-time recovery if needed, alongside code reversion.
* **Centralized Logging:** Implement a logging solution (e.g., ELK stack, Grafana Loki/Promtail) to centralize logs from Docker containers and system services.
* **Advanced Monitoring:** Add application-specific metrics (e.g., WordPress login failures, plugin errors) using WordPress-specific exporters or custom metrics.
* **Off-Site Backups:** Implement sending backups to a remote storage location (e.g., S3, Blob Storage) for disaster recovery.
* **Automated Backup Restoration Testing:** Periodically test the backup restoration process in a isolated environment to ensure backups are valid and restorable.
* **Infrastructure as Code (IaC):** Use tools like Terraform or Ansible to automate server provisioning and initial setup.
* **Secrets Management:** Integrate with a dedicated secrets management system.

## Screenshots

### Deployed WordPress Application

![website-live](https://github.com/user-attachments/assets/7c2ae3b0-3f11-4488-b118-2ec34b500d0a)

### Grafana Monitoring Dashboard

![grafana-dashboard-system-metrics](https://github.com/user-attachments/assets/597ce025-8cd2-4743-b467-0439ef4933ad)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
