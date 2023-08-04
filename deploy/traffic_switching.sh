#!/bin/bash

PIPELINE_ID=$1
CURRENT_NGINX_TCP_PORT=`fgrep localhost:300 /etc/nginx/sites-enabled/app.conf  | awk {'print$2'} | awk -F ":" {'print$2'} | sed 's/;//'`

#echo $PIPELINE_ID $CURRENT_APP_TCP_PORT $CURRENT_NGINX_TCP_PORT

cd /opt/app/$PIPELINE_ID
i=0
      until [ "$(docker-compose ps | grep running | awk {'print$4'})" = "running" ] && [ -z "$(docker-compose ps | grep starting )" ] && [ -z "$(docker-compose ps | grep unhealthy)" ]; do
        if [ $i = 25 ]; then
          echo "time is up! Deleting the currently deployed release"
          docker-compose down && rm -rf /opt/app/$PIPELINE_ID
          exit 1
        fi
        sleep 10
        i=$(( $i + 1 ))
        echo "waiting"
        echo "Attempt number $i out of 25"
      done

if [ "$CURRENT_NGINX_TCP_PORT" = 3003 ]; then
    echo "switching the application to 3004 tcp port"
    sed -i 's/3001:3001/3004:3001/' /opt/app/$PIPELINE_ID/docker-compose.yaml
else
    echo "switching the application to 3003 tcp port"
    sed -i 's/3001:3001/3003:3001/' /opt/app/$PIPELINE_ID/docker-compose.yaml
fi


docker-compose stop && docker-compose up -d

i=0
      until [ "$(docker-compose ps | grep running | awk {'print$4'})" = "running" ] && [ -z "$(docker-compose ps | grep starting )" ] && [ -z "$(docker-compose ps | grep unhealthy)" ]; do
        if [ $i = 25 ]; then
          echo "time is up! Deleting the currently deployed release"
          docker-compose down && rm -rf /opt/app/$PIPELINE_ID
          exit 1
        fi
        sleep 10
        i=$(( $i + 1 ))
        echo "waiting"
        echo "Attempt number $i out of 25"
      done


if [ "$CURRENT_NGINX_TCP_PORT" = 3003 ]; then
    echo "switching the nginx upstream to 3004 tcp port"
    sed -i 's/localhost:3003/localhost:3004/' /etc/nginx/sites-enabled/app.conf
    nginx -t
    nginx -s reload
    cd /opt/app/$(ls /opt/app/ | grep -v $PIPELINE_ID) && docker-compose down && cd /opt/app/ && rm -rf $(ls | grep -v $PIPELINE_ID)
else
    echo "switching the nginx upstream to 3003 tcp port"
    sed -i 's/localhost:3004/localhost:3003/' /etc/nginx/sites-enabled/app.conf
    nginx -t
    nginx -s reload
    cd /opt/app/$(ls /opt/app/ | grep -v $PIPELINE_ID) && docker-compose down && cd /opt/app/ && rm -rf $(ls | grep -v $PIPELINE_ID)
fi
