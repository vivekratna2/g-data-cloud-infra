#!/bin/bash

sudo su
sudo yum -y update

# Install and run docker
sudo yum install -y docker amazon-ecr-credential-helper
sudo service docker start
sudo service docker status

# Install docker compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose
echo "Installed Docker compose"

sudo mkdir -p ~/.docker && chmod 0700 ~/.docker
sudo echo '{"credsStore": "ecr-login"}' > ~/.docker/config.json

# Save the docker-compose.yml
echo "Saving docker compose.yml"
echo "
version: '3.7'
services:
    flask:
      image: 368759994472.dkr.ecr.us-west-2.amazonaws.com/gbd-data-platform-api:${etl_api_version}
      command: |
        bash -c 'gunicorn -w 4 --bind :80 --timeout 60 --log-level DEBUG app.main:flaskapp --reload'
      ports:
        - '8000:80'
      environment:
        FLASK_PORT: 8000
        REDIS_HOST: ${redis_host}
        REDIS_PORT: 6379
        REDIS_DB: ${redis_dag_index}
        REDIS_PASSWORD: ''
        AIRFLOW_BASEURL: ''
        ENVIRONMENT: ${environment}
        REGION: us-west-2
        CAI_REPARSE_SQS_QUEUE_URL: ${cai_reparse_sqs_queue_url}
        DX_BASE_URL: ${dx_base_url}
        DX_TOKEN: ${dx_token}
      logging:
        driver: 'json-file'
        options:
          max-size: '100m'
          max-file: '2'
" > /home/ec2-user/docker-compose.yml
echo "Saved docker compose"

# Run the docker-compose.yml
sudo docker-compose -f /home/ec2-user/docker-compose.yml up -d
