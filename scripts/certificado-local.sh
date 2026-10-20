#!/usr/bin/env bash
# Genera un certificado autofirmado para probar el WAF en tu equipo (certs/localhost.*).
# En las VM del aula se usan los certificados de la CA del aula (/srv/pps/certs).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p certs secrets
openssl req -x509 -newkey rsa:2048 -sha256 -days 90 -nodes \
  -keyout certs/localhost.key -out certs/localhost.crt \
  -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
chmod 644 certs/localhost.key   # el contenedor del WAF corre sin root y debe poder leerla
[ -f secrets/db_password.txt ] || { openssl rand -base64 24 > secrets/db_password.txt; chmod 644 secrets/db_password.txt; }
echo "Listo: certs/localhost.crt y secrets/db_password.txt"
