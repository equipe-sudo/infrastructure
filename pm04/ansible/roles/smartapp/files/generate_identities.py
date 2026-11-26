#!/usr/bin/env python3
"""Gera o s3-identities.json do SeaweedFS privado a partir das chaves geradas.

Idempotente: só grava quando o arquivo está ausente e recusa sobrescrever se
houver divergência com as chaves (sinal de rotação). Nunca imprime segredos.
"""
import json
import os
import sys

SECRETS_DIR = os.environ.get(
    "SECRETS_DIR", "/opt/smart-construction/.secrets/backend"
)


def read(name: str) -> str:
    with open(os.path.join(SECRETS_DIR, name), encoding="utf-8") as fh:
        return fh.read().strip()


identities = {
    "identities": [
        {
            "name": "bootstrap",
            "credentials": [
                {
                    "accessKey": read("s3-bootstrap-access-key"),
                    "secretKey": read("s3-bootstrap-secret-key"),
                }
            ],
            "actions": ["Admin", "Read", "Write", "List", "Tagging"],
        },
        {
            "name": "api",
            "credentials": [
                {
                    "accessKey": read("s3-api-access-key"),
                    "secretKey": read("s3-api-secret-key"),
                }
            ],
            "actions": [
                "Read:smart-cadastros-private",
                "Write:smart-cadastros-private",
                "List:smart-cadastros-private",
            ],
        },
    ]
}

target = os.path.join(SECRETS_DIR, "s3-identities.json")
new = json.dumps(identities) + "\n"

if os.path.exists(target):
    with open(target, encoding="utf-8") as fh:
        if fh.read() == new:
            print("s3-identities.json inalterado.")
            sys.exit(0)
    raise SystemExit("s3-identities.json diverge das chaves; revisar rotacao.")

with open(target, "x", encoding="utf-8") as fh:
    fh.write(new)
os.chmod(target, 0o444)
print("s3-identities.json gerado.")
