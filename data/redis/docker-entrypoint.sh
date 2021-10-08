#!/bin/bash

upload()
{
    echo "Wait for file upload... ($1)"
    while true
    do
        out=$(redis-cli -p $INITIAL_PORT -c < $1 2>&1 | grep "OK")
        res=$?
        if [[ $res -eq 0 ]]; then
            break
        fi
        sleep 1
    done
    echo "Finished uploading the file ($1)"
}

upload_redis_samples()
{
    echo "Wait for redis container..."
    
    while true
    do
        out=$(redis-cli -p $INITIAL_PORT -c info > /dev/null 2>&1)
        res=$?
        if [[ $res -eq 0 ]]; then
            break
        fi
        sleep 1
    done

    # upload data to redis
    upload "/data/redis/user.redis.query.txt"
    upload "/data/redis/inventory.redis.query.txt"
}

upload_redis_samples &
exec /docker-entrypoint.sh redis-cluster
