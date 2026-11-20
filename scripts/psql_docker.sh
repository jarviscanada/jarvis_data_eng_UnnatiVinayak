#!/bin/sh

# Capture CLI arguments. $1, $2, $3 represent the command line arguments
cmd=$1
db_username=$2
db_password=$3

# Start Docker if it is not running already
sudo systemctl status docker || sudo systemctl start docker

# Check if the PostgreSQL container exists
docker container inspect jrvs-psql
container_status=$?

# Handle the create, start, and stop commands
case "$cmd" in
  create)

  # Check if the container is already created
  if [ "$container_status" -eq 0 ]; then
    echo 'Container already exists'
    exit 1
  fi

  # Check # of CLI arguments
  if [ "$#" -ne 3 ]; then
    echo 'Create requires username and password'
    exit 1
  fi

  # Create persistent storage for PostgreSQL
  docker volume create pgdata

  # Create and start the PostgreSQL container
  docker run --name jrvs-psql \
          -e POSTGRES_USER="$db_username" \
          -e POSTGRES_PASSWORD="$db_password" \
          -d \
          -v pgdata:/var/lib/postgresql/data \
          -p 5432:5432 \
          postgres:9.6-alpine
  exit $?
  ;;

  start|stop)

  # Check instance status; exit 1 if container has not been created
  if [ "$container_status" -ne 0 ]; then
    echo 'Container does not exist'
    exit 1
  fi

  # Start or stop the container
  docker container "$cmd" jrvs-psql
  exit $?
  ;;

  *)
    echo 'Illegal command'
    echo 'Commands: start|stop|create'
    exit 1
    ;;
esac
