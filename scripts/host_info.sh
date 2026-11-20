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

# collect hardware specifications and store in bash variable that will be parsed later
lscpu_out=$(lscpu)

# parse and assign the parsed portion respective bash variables
hostname=$(hostname -f)
cpu_number=$(echo "$lscpu_out" | grep '^CPU(s):' | awk '{print $2}')
cpu_architecture=$(echo "$lscpu_out" | grep '^Architecture:' | awk '{print $2}')
cpu_model=$(echo "$lscpu_out" | grep '^Model name:' | cut -d ':' -f2- | xargs)
cpu_mhz=$(grep '^cpu MHz' /proc/cpuinfo | head -1 | awk '{print $4}')
l2_cache=$(echo "$lscpu_out" | grep '^L2 cache:' | awk '{print $3}')
total_mem=$(free -k | grep '^Mem:' | awk '{print $2}')
timestamp=$(date -u '+%Y-%m-%d %H:%M:%S')

# Display hardware specifications for testing
# echo "Hostname: $hostname"
# echo "CPU Number: $cpu_number"
# echo "CPU Architecture: $cpu_architecture"
# echo "CPU Model: $cpu_model"
# echo "CPU MHz: $cpu_mhz MHz"
# echo "L2 Cache: $l2_cache KiB"
# echo "Total Memory: $total_mem KiB"
# echo "Timestamp (UTC): $timestamp"

# construct SQL INSERT statement and name it insert_stmt (string bash variable)
insert_stmt="INSERT INTO host_info (
    hostname,
    cpu_number,
    cpu_architecture,
    cpu_model,
    cpu_mhz,
    l2_cache,
    total_mem,
    timestamp
) VALUES (
    '$hostname',
    $cpu_number,
    '$cpu_architecture',
    '$cpu_model',
    $cpu_mhz,
    $l2_cache,
    $total_mem,
    '$timestamp'
);"

# display INSERT statement for testing
# echo "$insert_stmt"

# execute INSERT statement using psql
 PGPASSWORD="$psql_password" psql \
    -h "$psql_host" \
    -p "$psql_port" \
    -U "$psql_user" \
    -d "$db_name" \
    -v ON_ERROR_STOP=1 \
    -c "$insert_stmt"
exit $?
