#!/bin/sh
set -eu

# Cria/ajusta o role de runtime `smart_api` usando a senha do secret montado
# em /run/secrets/runtime_password (api-password). Executado pelo entrypoint do
# postgres APENAS na primeira inicialização do volume de dados. A reexecução
# manual é segura (idempotente): recria o role se ausente ou apenas atualiza a
# senha para coincidir com o secret — sem tocar nos dados.

SMART_RUNTIME_PASSWORD=$(tr -d '\r\n' < /run/secrets/runtime_password)
export SMART_RUNTIME_PASSWORD

psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --set ON_ERROR_STOP=1 <<'SQL'
\getenv runtime_password SMART_RUNTIME_PASSWORD
\getenv database_name POSTGRES_DB

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'smart_api') THEN
    CREATE ROLE smart_api LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD :'runtime_password';
  ELSE
    ALTER ROLE smart_api WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD :'runtime_password';
  END IF;
END
$$;

REVOKE ALL ON DATABASE :"database_name" FROM PUBLIC;
GRANT CONNECT ON DATABASE :"database_name" TO smart_api;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
SQL

unset SMART_RUNTIME_PASSWORD
