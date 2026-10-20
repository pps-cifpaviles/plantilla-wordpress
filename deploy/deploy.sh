#!/usr/bin/env bash
# Despliega WordPress + WAF en la VM del entorno y comprueba que responde por HTTPS.
# Uso (desde el pipeline):  deploy/deploy.sh <host>
# Necesita: ALUMNO y WP_DB_PASSWORD (secreto del entorno).
set -euo pipefail

HOST=${1:?Uso: deploy.sh <host>}
: "${ALUMNO:?Falta la variable ALUMNO del repositorio}"
: "${WP_DB_PASSWORD:?Falta el secreto WP_DB_PASSWORD del entorno}"

BASE=$((20000 + 10#$ALUMNO * 100))
export WP_HTTP_PORT=$((BASE + 30))
export WP_HTTPS_PORT=$((BASE + 31))
export CERT_DIR=/srv/pps/certs
export CERT_NAME="$HOST"
PROYECTO="a${ALUMNO}-wordpress"

# La contraseña se guarda fuera del repositorio, en el home del runner
SECRETOS="$HOME/.pps/$PROYECTO"
mkdir -p "$SECRETOS" && chmod 700 "$SECRETOS"
printf '%s' "$WP_DB_PASSWORD" > "$SECRETOS/db_password.txt"
chmod 644 "$SECRETOS/db_password.txt"     # los contenedores leen el fichero con su propio usuario
export DB_PASSWORD_FILE="$SECRETOS/db_password.txt"

cd "$(dirname "$0")/.."
docker compose -p "$PROYECTO" -f compose.yml up -d --remove-orphans

echo "Comprobando https://${HOST}:${WP_HTTPS_PORT} …"
for _ in $(seq 1 40); do
  CODE=$(curl -sk -o /dev/null -w '%{http_code}' "https://localhost:${WP_HTTPS_PORT}/" || true)
  if [[ "$CODE" =~ ^(200|301|302)$ ]]; then
    echo "OK (${CODE}) · https://${HOST}:${WP_HTTPS_PORT}"
    [ -n "${GITHUB_STEP_SUMMARY:-}" ] && echo "WordPress en https://${HOST}:${WP_HTTPS_PORT}" >> "$GITHUB_STEP_SUMMARY"
    exit 0
  fi
  sleep 5
done
echo "WordPress no responde. Últimos logs:" >&2
docker compose -p "$PROYECTO" -f compose.yml logs --tail 50 >&2
exit 1
