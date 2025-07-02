#!/bin/bash

# Database Backup Script
# This script performs MySQL database backups and uploads them to AWS S3
# Created: 2024
#
# Prerequisites:
# - MySQL/MariaDB installed
# - AWS CLI configured with appropriate credentials
# - Sufficient permissions on the backup directory
#
# Usage: 
# 1. Edit the configuration variables below
# 2. Make script executable: chmod +x backup_databases.sh
# 3. Run: bash backup_databases.sh

#===========================================
# CONFIGURATION - MODIFY THESE VALUES
#===========================================

# MySQL database connection details
USER="your_mysql_username"        # Enter your MySQL username
PASSWORD="your_mysql_password"    # Enter your MySQL password
HOST="localhost"                  # Enter your database host (usually localhost)

# AWS S3 configuration
S3BUCKET="your-bucket-name"      # Enter your S3 bucket name

# Comma-separated list of databases to backup
# Example: "database1,database2,database3"
DATABASES="database1,database2"   # Enter your database names

# Backup directory path
BACKUPROOT="/home/ubuntu/backups/db_backup" # Enter your desired backup directory

#===========================================
# DO NOT MODIFY BELOW THIS LINE
#===========================================

# Timestamp configuration
TSTAMP=$(date +"%d-%b-%Y-%H-%M-%S")
YEAR=$(date +"%b-%Y")

# Verify backup directory exists
if ! mkdir -p "$BACKUPROOT"; then
    echo "Error: Unable to create backup directory"
    exit 1
fi

# S3 folder configuration
S3FOLDER="s3://$S3BUCKET/$YEAR/"

# Function to backup and upload database
backup_database() {
    local db_name=$1
    local backup_file="$BACKUPROOT/$TSTAMP.$db_name.sql.gz"
    
    echo "Starting backup of database: $db_name"
    
    # Verify mysqldump is available
    if ! command -v mysqldump >/dev/null 2>&1; then
        echo "Error: mysqldump command not found"
        return 1
    fi
    
    # Create compressed MySQL dump
    if ! /usr/bin/mysqldump -u "$USER" -p"$PASSWORD" -h "$HOST" --databases "$db_name" | gzip > "$backup_file"; then
        echo "Error: Database backup failed for $db_name"
        return 1
    fi
    
    # Verify AWS CLI is available
    if ! command -v aws >/dev/null 2>&1; then
        echo "Error: AWS CLI not found"
        return 1
    fi
    
    # Upload to S3
    echo "Uploading backup to S3..."
    if ! aws s3 cp "$backup_file" "$S3FOLDER"; then
        echo "Error: S3 upload failed for $db_name"
        return 1
    fi
    
    echo "✓ Backup completed successfully for: $db_name"
    echo "  Local backup: $backup_file"
    echo "  S3 location: $S3FOLDER$(basename "$backup_file")"
}

# Perform backup for each database
echo "Starting backup process..."
IFS=',' read -ra DB_ARRAY <<< "$DATABASES"
for DB in "${DB_ARRAY[@]}"; do
    backup_database "$DB"
done

echo "Backup process completed"
