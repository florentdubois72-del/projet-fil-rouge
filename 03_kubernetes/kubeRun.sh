#/bin/bash
#
#
ipa=$(curl ipinfo.io/ip)

echo $ipa
cat <<EOF > ic-webapp/ic-webapp-cm.yml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ic-webapp-cm
  namespace: icgroup
  labels:
    env: prod
    app: ic-webapp
data:
  ODOO_URL:    http://$ipa:30010
  PGADMIN_URL: http://$ipa:30011
EOF

#kubectl apply -k .
