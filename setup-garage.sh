#!/bin/bash

docker compose up -d garage

sleep 2

node_id=$(docker compose exec garage /garage status | tail -n1 | awk '{ printf $1 }')

docker compose exec garage /garage layout assign -z dc0 -c 1G $node_id

docker compose exec garage /garage layout apply --version 1

docker compose exec garage /garage bucket create aasa-assetlinks

key_create=$(docker compose exec garage /garage key create aasa-assetlinks-server)

echo S3_ACCESS_KEY_ID=$(echo "$key_create" | grep 'Key ID:' | awk '{ print $3 }') >>.env
echo S3_SECRET_ACCESS_KEY=$(echo "$key_create" | grep 'Secret key:' | awk '{ print $3 }') >>.env

docker compose exec garage /garage bucket allow --read --write --owner aasa-assetlinks --key aasa-assetlinks-server

docker compose exec garage /garage bucket info aasa-assetlinks
