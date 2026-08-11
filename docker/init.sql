-- ============================================
-- SQL — Schema inicial do Jogo de Slots
-- ============================================
-- Executado automaticamente na primeira subida do container PostgreSQL
-- via docker-entrypoint-initdb.d/

CREATE TABLE IF NOT EXISTS usuario (
    id        SERIAL PRIMARY KEY,
    nome      VARCHAR(100) NOT NULL DEFAULT 'Jogador',
    saldo     DECIMAL(10, 2) NOT NULL DEFAULT 100.00,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS giro (
    id          SERIAL PRIMARY KEY,
    usuario_id  INTEGER NOT NULL REFERENCES usuario(id),
    grade_json  JSONB NOT NULL,
    aposta      DECIMAL(10, 2) NOT NULL,
    premio      DECIMAL(10, 2) NOT NULL DEFAULT 0,
    saldo_antes DECIMAL(10, 2) NOT NULL,
    saldo_apos  DECIMAL(10, 2) NOT NULL,
    data_hora   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS transacao (
    id          SERIAL PRIMARY KEY,
    usuario_id  INTEGER NOT NULL REFERENCES usuario(id),
    tipo        VARCHAR(20) NOT NULL CHECK (tipo IN ('deposito', 'aposta', 'premio', 'reset')),
    valor       DECIMAL(10, 2) NOT NULL,
    saldo_apos  DECIMAL(10, 2) NOT NULL,
    data_hora   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para consultas frequentes
CREATE INDEX IF NOT EXISTS idx_giro_usuario_data ON giro(usuario_id, data_hora DESC);
CREATE INDEX IF NOT EXISTS idx_transacao_usuario_data ON transacao(usuario_id, data_hora DESC);

-- Seed: usuário inicial
INSERT INTO usuario (nome, saldo) VALUES ('Jogador', 100.00) ON CONFLICT DO NOTHING;
