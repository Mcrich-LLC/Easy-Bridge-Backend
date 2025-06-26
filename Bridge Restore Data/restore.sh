#!/bin/bash

# Get the directory of the script
script_dir=$(dirname "$0")

# Prompt the user to enter the Docker container name
read -p "Enter your Docker container name: " your_db_container

# Check if the container exists
sudo docker inspect $your_db_container > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Docker container '$your_db_container' not found."
    exit 1
fi

# Prompt the user to enter the database username
read -p "Enter your database username: " your_db_user

# Prompt the user to enter the database name
read -p "Enter your database name: " your_db_name

# Path to the SQL dump file (Seattle.sql)
your_dump_file="$script_dir/Seattle.sql"

# Check if the dump file exists
if [ ! -f "$your_dump_file" ]; then
    echo "Error: Dump file '$your_dump_file' not found."
    exit 1
fi

# Command to execute
cat "$your_dump_file" | sudo docker exec -i $your_db_container psql -U $your_db_user -d $your_db_name
