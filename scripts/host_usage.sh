#!/bin/bash

# capture database connection arguments for database connection. 
# tell scrip where database is, which one to connect to, and using what credentials
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# validate the number of CLI arguments. 
# PostgreSQL server hostname (localhost), PostgreSQL port number (5432), Database name (host_agent), PostgreSQL username (postgres), PostgreSQL password (password)
if [ "$#" -ne 5 ]; then
	echo "Error: 5 arguments are expected."
	exit 1
fi

# collect resource usage stats and store in bash variable that will be parsed later
vmstat_mb=$(vmstat --unit M)

# parse and assign the parsed portion corresponding bash variables
hostname=$(hostname -f)
memory_free=$(echo "$vmstat_mb" | awk 'END {print $4}')
cpu_idle=$(echo "$vmstat_mb" | awk 'END {print $15}')
cpu_kernel=$(echo "$vmstat_mb" | awk 'END {print $14}')
disk_available=$(df -BM / | awk 'END {print $4}' | tr -d 'M')
disk_io=$(vmstat -d | awk 'NR==3 {print $10}')
timestamp=$(date -u '+%Y-%m-%d %H:%M:%S')

# find the matching host ID from host_info table (hardware table)
# connects your two database tables (host_info and host_usage) /foreign key relationship
# find the machine's ID in the hardware table where the HOSTNAME matches the current one
# store that as a bash variable (host_id)
host_id="(SELECT id FROM host_info WHERE hostname='$hostname')"

# display the bash variables for testing
# echo "Hostname: $hostname"
# echo "Free Memory: $memory_free MB"
# echo "CPU Idle: $cpu_idle%"
# echo "CPU Kernel: $cpu_kernel%"
# echo "Disk Available: $disk_available MB"
# echo "Disk I/O: $disk_io"
# echo "Timestamp (UTC): $timestamp"
# echo "Host ID Subquery: $host_id"

# contruct SQL INSERT statement
insert_stmt="INSERT INTO host_usage (
    timestamp,
    host_id,
    memory_free,
    cpu_idle,
    cpu_kernel,
    disk_io,
    disk_available
) VALUES (
    '$timestamp',
    $host_id,
    $memory_free,
    $cpu_idle,
    $cpu_kernel,
    $disk_io,
    $disk_available
);"

# display the INSERT statement for testing
# echo "$insert_stmt"

# execute SQL INSERT statement using PostgreSQL
PGPASSWORD="$psql_password" psql \
    -h "$psql_host" \
    -p "$psql_port" \
    -U "$psql_user" \
    -d "$db_name" \
    -v ON_ERROR_STOP=1 \
    -c "$insert_stmt"
exit $?
