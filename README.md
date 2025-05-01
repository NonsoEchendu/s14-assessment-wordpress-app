# S14 Assessment: Dockerized WordPress CI/CD

This project demonstrates a Dockerized WordPress application with a CI/CD pipeline, rollback capability, automated backups, and monitoring, deployed to an Ubuntu server.

## Table of Contents

- [Project Description](#project-description)
- [Setup Guide](#setup-guide)
    - [Prerequisites](#prerequisites)
    - [Local Setup](#local-setup)
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
* A domain name pointing to your server's IP address (e.g., `s14.michaeloxo.tech` and `monitoring.s14.michaeloxo.tech`).
* A Slack workspace and webhook URL (optional, for notifications).

### Local Setup

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/NonsoEchendu/s14-assessment-wordpress-app.git](https://github.com/NonsoEchendu/s14-assessment-wordpress-app.git)
    cd s14-assessment-wordpress-app
    ```

2.  **Configure environment variables:**
    Create a `.env` file in the project root directory from the `.env.example` file and fill in your desired database credentials.

    ```bash
    cp .env.example .env
    ```

### Server Setup

1.  **Connect to your Ubuntu server via SSH** using your SSH key.
    ```bash
    ssh -i your-key-pair.pem ubuntu@your-ip-address
    ```
2.  **Ensure Docker and Docker Compose are installed.** If not, follow the [official Docker documentation for Ubuntu](https://docs.docker.com/engine/install/ubuntu/).
3.  **Create a directory** on the server for your application code:
    ```bash
    mkdir ~/s14-assessment-wordpress-app
    ```
4.  **Place your `.env` file** on the server within the application directory.

### GitHub Actions Configuration

1.  **Add Repository Secrets:** Go to your GitHub repository -> **Settings** -> **Secrets and variables** -> **Actions**. Add the following repository secrets:
    * `SERVER_HOST`: Your server's IP address or hostname.
    * `SERVER_USERNAME`: The SSH user on your server (e.g., `ubuntu`).
    * `SSH_PRIVATE_KEY`: The **entire content** of the private SSH key you will use for deployment (including `-----BEGIN...-----` and `-----END...-----`).
    * `SLACK_WEBHOOK_URL`: Your Slack webhook URL. Check th

2.  **Ensure Workflow Files are in `.github/workflows/`:** Verify that `deploy.yml` and `rollback.yml` (or your chosen names) are in the `.github/workflows/` directory.

3.  **Perform the initial deployment:** Push your code to the `main` branch or manually trigger the `Deploy Wordpress App` workflow in the GitHub Actions tab.

### Nginx and SSL Setup

Configure Nginx on your Ubuntu server to act as a reverse proxy for your Dockerized WordPress application and your Grafana dashboard.

1.  **Install Nginx:** `sudo apt update && sudo apt install nginx`
2.  **Create Nginx configuration files** in `/etc/nginx/sites-available/` for your WordPress site (proxying to `http://127.0.0.1:8000`) and your monitoring dashboard (proxying to `http://127.0.0.1:3000`).
3.  **Enable the configurations** by creating symlinks in `/etc/nginx/sites-enabled/`.
4.  **Test Nginx config:** `sudo nginx -t`
5.  **Install Certbot** and obtain SSL certificates for both your WordPress domain (`your-website.com`) and your monitoring subdomain (`monitoring.your-website.com`). Certbot will automatically configure Nginx for SSL. Follow the Certbot instructions for Nginx on Ubuntu.
6.  **Reload Nginx:** `sudo systemctl reload nginx`

### Automated Backups

1.  **Place the `backup.sh` script** on your Ubuntu server (e.g., in your home directory: `~/backup.sh`).
2.  **Make the script executable:** `chmod +x ~/backup.sh`
3.  **Edit the script** to ensure paths (`APP_DIR`, `BACKUP_ROOT_DIR`) and service names match your setup.
4.  **Set up a daily cron job** to run the script: `crontab -e`, then add a line like `0 2 * * * /bin/bash /home/ubuntu/backup.sh` (adjust time and path as needed).
5.  **Refer to the restoration guide** (either in this README or a separate document) for how to restore from these backups.

### Monitoring Setup

Ensure Prometheus, Grafana, Node Exporter, and Blackbox Exporter are installed and running on your Ubuntu server as system services or via Docker Compose.

1.  **Install/Configure Monitoring Services:** Follow the documentation for installing and configuring Prometheus, Grafana, Node Exporter, and Blackbox Exporter on Ubuntu.
2.  **Configure Prometheus** (`/etc/prometheus/prometheus.yml`) to scrape metrics from Node Exporter (`localhost:9100`) and Blackbox Exporter (`localhost:9115`) using the Blackbox exporter's `/probe` endpoint to check your WordPress site.
3.  **Start/Restart Prometheus and Exporter services.**
4.  **Log in to Grafana** (`http://your-server-ip:3000` or `https://monitoring.your-website.comh` if using Nginx).
5.  **Add Prometheus as a data source** in Grafana.
6.  **Import dashboards** (e.g., Node Exporter Full ID 1860, Blackbox Exporter ID 7587) and/or create your own dashboards and alerts (like the CPU usage alert).

## Project Status

### What Works

* Dockerized WordPress and MySQL application setup using Docker Compose.
* Automated deployment to the Ubuntu server via GitHub Actions on push to `main`.
* Manual deployment triggering via GitHub Actions.
* Secure deployment using SSH key authentication.
* Manual rollback capability via a separate GitHub Actions workflow using Git tags.
* Automated daily backups of WordPress files and database using a server-side script and cron.
* Basic monitoring of server resources (CPU, Memory, Disk) and application availability (via Blackbox Exporter) using Prometheus and Grafana.
* Nginx reverse proxy serving the WordPress site and Grafana dashboard with SSL certificates managed by Certbot.

### Areas for Improvement

With more time, the following areas could be improved:

* **More Robust CI Pipeline:** Implement a separate CI workflow to run code quality checks, linting, and unit tests on development/feature branches before merging to `main`.
* **Enhanced Deployment Verification:** Add more comprehensive application-level health checks in the deployment pipeline (e.g., checking for a successful HTTP response from the WordPress site, database connection checks from within the application container).
* **Automated Rollback on Verification Failure:** Modify the pipeline to automatically trigger the rollback workflow if the deployment verification step fails.
* **More Comprehensive Rollback:** Develop a more robust rollback strategy that includes handling data volume snapshots or database point-in-time recovery if needed, alongside code reversion.
* **Centralized Logging:** Implement a logging solution (e.g., ELK stack, Grafana Loki/Promtail) to centralize logs from Docker containers and system services.
* **Advanced Monitoring:** Add application-specific metrics (e.g., WordPress login failures, plugin errors) using WordPress-specific exporters or custom metrics.
* **Off-Site Backups:** Implement sending backups to a remote storage location (e.g., S3, Blob Storage) for disaster recovery.
* **Automated Backup Restoration Testing:** Periodically test the backup restoration process in a isolated environment to ensure backups are valid and restorable.
* **Infrastructure as Code (IaC):** Use tools like Terraform or Ansible to automate server provisioning and initial setup.
* **Secrets Management:** Integrate with a dedicated secrets management system.
* **Database Backup Consistency:** Ensure database backups are fully consistent, potentially using `FLUSH TABLES WITH READ LOCK` or `--single-transaction` options in `mysqldump`.

## Screenshots

### Deployed WordPress Application

![website-live](https://github.com/user-attachments/assets/7c2ae3b0-3f11-4488-b118-2ec34b500d0a)

### Grafana Monitoring Dashboard

![grafana-dashboard-system-metrics](https://github.com/user-attachments/assets/597ce025-8cd2-4743-b467-0439ef4933ad)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
