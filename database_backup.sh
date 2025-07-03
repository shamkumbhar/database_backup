#!/bin/bash

# Configuration
CONTAINER_NAME="mysql-0"
DATABASE_NAME="hrmsdb"
MYSQL_USER="root"
MYSQL_PASSWORD="root"
DUMP_FILE="/tmp/${DATABASE_NAME}_backup.sql"
LOCAL_BACKUP_FILE="./${DATABASE_NAME}_backup_$(date +%F_%H-%M-%S).sql"
S3_BUCKET="hrmsdb-database-01"

# Step 1: Dump database inside the container
echo "Dumping MySQL database '$DATABASE_NAME' inside container '$CONTAINER_NAME'..."
kubectl exec $CONTAINER_NAME sh -c "mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $DATABASE_NAME > $DUMP_FILE"

# Step 2: Copy dump file to host
echo "Copying dump to host as $LOCAL_BACKUP_FILE..."
kubectl cp $CONTAINER_NAME:$DUMP_FILE $LOCAL_BACKUP_FILE

# Step 3: Upload to S3
echo "Uploading $LOCAL_BACKUP_FILE to s3://$S3_BUCKET/ ..."
aws s3 cp $LOCAL_BACKUP_FILE s3://$S3_BUCKET/

# Optional: Clean up container dump
echo "Cleaning up container dump..."
docker exec $CONTAINER_NAME rm -f $DUMP_FILE

# Step 5: Remove local backup file
echo "Removing local backup file $LOCAL_BACKUP_FILE..."
rm -f "$LOCAL_BACKUP_FILE"


echo "✅ Backup and upload complete!"
