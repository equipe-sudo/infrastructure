#!/bin/sh
set -eu

# Cria/ajusta o role de runtime `smart_api` usando a senha do secret montado
# em /run/secrets/runtime_password (api-password). Executado pelo entrypoint do
# postgres APENAS na primeira inicialização do volume de dados.
#
# IMPORTANTE: CREATE ROLE/ALTER ROLE são comandos utilitários e NÃO podem ser
# executados estaticamente dentro de um bloco DO (plpgsql) — precisam de
# EXECUTE (SQL dinâmico). Por isso usamos format() + %L.

SMART_RUNTIME_PASSWORD=$(tr -d '\r\n' < /run/secrets/runtime_password)
export SMART_RUNTIME_PASSWORD

psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --set ON_ERROR_STOP=1 <<'SQL'
\getenv runtime_password SMART_RUNTIME_PASSWORD
\getenv database_name POSTGRES_DB

DO $$
DECLARE
  pw text := :'runtime_password';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'smart_api') THEN
    EXECUTE format('CREATE ROLE smart_api LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD %L', pw);
  ELSE
    EXECUTE format('ALTER ROLE smart_api WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD %L', pw);
  END IF;
END
$$;

REVOKE ALL ON DATABASE :"database_name" FROM PUBLIC;
GRANT CONNECT ON DATABASE :"database_name" TO smart_api;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
SQL

unset SMART_RUNTIME_PASSWORD
