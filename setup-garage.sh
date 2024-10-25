#!/bin/bash

docker compose up -d garage

sleep 2

node_id=$(docker compose exec garage /garage status | tail -n1 | awk '{ printf $1 }')

docker compose exec garage /garage layout assign -z dc0 -c 1G $node_id

docker compose exec garage /garage layout apply --version 1

docker compose exec garage /garage bucket create aasa-assetlinks

docker compose exec garage /garage key create aasa-assetlinks-server

docker compose exec garage /garage bucket allow --read --write --owner aasa-assetlinks --key aasa-assetlinks-server

docker compose exec garage /garage bucket info aasa-assetlinks
