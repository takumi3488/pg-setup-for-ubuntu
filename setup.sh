#!/bin/bash -e

# Install postgresql
ssh -i $SSH_KEY $HOST "sudo apt update && \
    sudo apt install -y postgresql && \
    sudo systemctl start postgresql && \
    sudo systemctl enable postgresql"

# Create tmp user
ssh -i $SSH_KEY $HOST "sudo -u postgres psql -c \"CREATE USER tmp WITH PASSWORD 'tmp'\" && \
    sudo -u postgres psql -c \"CREATE DATABASE tmp WITH OWNER tmp\" && \
    sudo -u postgres psql -c \"ALTER USER tmp WITH SUPERUSER\""

# Allow remote access to postgresql
ssh -i $SSH_KEY $HOST "sudo sed -i \"s/#listen_addresses = 'localhost'/listen_addresses = '*'/g\" /etc/postgresql/16/main/postgresql.conf && \
    sudo chmod 777 /etc/postgresql/16/main/pg_hba.conf && \
    sudo echo 'host all    all   0.0.0.0/0    password' >> /etc/postgresql/16/main/pg_hba.conf && \
    sudo chmod 640 /etc/postgresql/16/main/pg_hba.conf && \
    sudo systemctl restart postgresql"

# Extract host from $HOST
HOST=$(echo $HOST | cut -d'@' -f2)

# Restore database
psql -d "postgresql://tmp:tmp@$HOST:5432/tmp?sslmode=disable" -f backup.sql

echo "Restored database successfully"
