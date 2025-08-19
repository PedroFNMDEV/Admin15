/*
  # Atualização do Schema - Unificar login e usuario

  1. Alterações nas Tabelas
    - `streamings`: Renomear coluna `login` para `usuario` para padronizar com revendas
    - Manter compatibilidade com dados existentes

  2. Índices
    - Recriar índices únicos para a nova coluna `usuario`
    - Remover índices da coluna `login` antiga

  3. Dados
    - Migrar dados existentes da coluna `login` para `usuario`
    - Verificar integridade dos dados após migração
*/

-- Verificar se a coluna usuario já existe na tabela streamings
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'streamings' AND column_name = 'usuario'
  ) THEN
    -- Adicionar nova coluna usuario
    ALTER TABLE streamings ADD COLUMN usuario VARCHAR(50);
    
    -- Migrar dados da coluna login para usuario (se existir)
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'streamings' AND column_name = 'login'
    ) THEN
      UPDATE streamings SET usuario = login WHERE login IS NOT NULL;
    END IF;
    
    -- Tornar a coluna usuario NOT NULL após migração
    ALTER TABLE streamings ALTER COLUMN usuario SET NOT NULL;
    
    -- Criar índice único para usuario
    CREATE UNIQUE INDEX IF NOT EXISTS idx_streamings_usuario ON streamings(usuario);
    
    -- Remover coluna login antiga (se existir)
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'streamings' AND column_name = 'login'
    ) THEN
      ALTER TABLE streamings DROP COLUMN login;
    END IF;
  END IF;
END $$;

-- Verificar se todas as streamings têm usuario definido
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM streamings WHERE usuario IS NULL OR usuario = ''
  ) THEN
    RAISE NOTICE 'Atenção: Existem streamings sem usuário definido. Verifique os dados.';
  END IF;
END $$;