#!/bin/bash
set -eo pipefail


# echo "Setup letsencrypt context..."

# gsutil -m rsync -r "${LETSENCRYPT_BUCKET}" /etc/letsencrypt

echo "Renewing certificate..."

dns_provider_options="--dns-${DNS_PROVIDER}"
if [ "${DNS_PROVIDER}" != "route53" ] && [ "${DNS_PROVIDER}" != "google" ]; then
  echo -e "${DNS_PROVIDER_CREDENTIALS}" > /dns_api_key.ini
  dns_provider_options="${dns_provider_options} --dns-${DNS_PROVIDER}-credentials /dns_api_key.ini"
fi

echo certbot certonly -v -n \
  -m "${LETSENCRYPT_CONTACT_EMAIL}" --agree-tos \
  --preferred-challenges dns ${dns_provider_options} \
  -d "*.${CUSTOM_DOMAIN}"

certbot certonly -v -n \
  -m "${LETSENCRYPT_CONTACT_EMAIL}" --agree-tos \
  --preferred-challenges dns ${dns_provider_options} \
  -d "*.${CUSTOM_DOMAIN}"

echo openssl rsa \
  -in "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/privkey.pem" \
  -out "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/privkey-rsa.pem" \

openssl rsa \
  -in "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/privkey.pem" \
  -out "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/privkey-rsa.pem" \


# echo "Backup of letsencrypt context"
# gsutil -m rsync -r /etc/letsencrypt "${LETSENCRYPT_BUCKET}"

echo ""
echo "CERTIFICATE"
echo "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/fullchain.pem"
echo ""
cat /etc/letsencrypt/live/${CUSTOM_DOMAIN}/fullchain.pem
echo ""

echo ""
echo "PRIVATE KEY"
echo "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/privkey-rsa.pem"
echo ""
cat /etc/letsencrypt/live/${CUSTOM_DOMAIN}/privkey-rsa.pem
echo ""

echo "Install certificate on App Engine"
certificate_id=25661238

echo "Updating existing certificate"
gcloud app ssl-certificates update "${certificate_id}" \
	--certificate "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/fullchain.pem" \
	--private-key "/etc/letsencrypt/live/${CUSTOM_DOMAIN}/privkey-rsa.pem"

echo "Enable certificate on *.${CUSTOM_DOMAIN} domain mapping"
gcloud app domain-mappings update "*.${CUSTOM_DOMAIN}" --certificate-management manual --certificate-id "${certificate_id}"