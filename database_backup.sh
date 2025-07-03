#!/bin/bash

# === Configuration ===
POD_NAME="mysql-0"
DATABASE_NAME="hrmsdb"
MYSQL_USER="root"
MYSQL_PASSWORD="root"
DUMP_FILE="/tmp/${DATABASE_NAME}_backup.sql"
TIMESTAMP=$(date +%F_%H-%M-%S)
LOCAL_BACKUP_FILE="./${DATABASE_NAME}_backup_${TIMESTAMP}.sql"
S3_BUCKET="hrmsdb-database-01"

# === Step 1: Dump database inside the pod ===
echo "[INFO] Dumping MySQL database '$DATABASE_NAME' inside pod '$POD_NAME'..."
kubectl exec "$POD_NAME" -- sh -c "mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $DATABASE_NAME > $DUMP_FILE"

# === Step 2: Copy dump file to host ===
echo "[INFO] Copying dump to host as $LOCAL_BACKUP_FILE..."
kubectl cp "$POD_NAME":"$DUMP_FILE" "$LOCAL_BACKUP_FILE"

# === Step 3: Upload to S3 ===
echo "[INFO] Uploading $LOCAL_BACKUP_FILE to s3://$S3_BUCKET/ ..."
aws s3 cp "$LOCAL_BACKUP_FILE" "s3://$S3_BUCKET/"

# === Step 4: Clean up inside the pod ===
echo "[INFO] Cleaning up dump file inside pod..."
kubectl exec "$POD_NAME" -- rm -f "$DUMP_FILE"

# === Step 5: Optionally remove local file ===
echo "[INFO] Removing local backup file $LOCAL_BACKUP_FILE..."
rm -f "$LOCAL_BACKUP_FILE"

echo "✅ Backup and upload complete!"



