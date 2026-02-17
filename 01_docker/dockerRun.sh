#!/bin/bash
#
#
ipa=$(curl ipinfo.io/ip)

echo $ipa
cat <<EOF > ./compose-file/ic-webapp-compose.yml
services:
  ic-webapp:
    container_name: ic-webapp
    ports:
      - 8080:8080
    #image: ulrichsteve/ic-webapp:1.0
    image: ic-webapp:1.0
    environment:
      - "ODOO_URL=http://$ipa:8069/"
      - "PGADMIN_URL=http://$ipa:80"

EOF

docker compose -f ./compose-file/pgadmin-compose.yml up -d
docker compose -f ./compose-file/odoo-compose.yml up -d
docker compose -f ./compose-file/ic-webapp-compose.yml up -d
