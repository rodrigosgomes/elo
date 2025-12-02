# Prompt 01 – Definição do Modelo de Dados

Olá! Vamos iniciar a construção do Elo — Gestão de Legado Digital. A etapa mais importante agora é definir o Modelo de Dados completo no Supabase, garantindo suporte às jornadas de Dashboard, Bens, Documentos, Emergência, Legado Digital e Diretivas descritas no PRD (`docs/01-product/prd-geral.md`). Por favor, crie as tabelas, relacionamentos, tipos ENUM e políticas a seguir.

Resumo da lógica:

- O usuário autenticado (auth.users) possui um perfil seguro, chaves de criptografia client-side, sessões monitoradas e progresso de checklist (1 bem + 1 guardião + verificação de vida).
- O usuário cadastra Bens com comprovantes e Documentos criptografados, ambos com uploads resilientes e auditoria.
- O Protocolo de Emergência controla guardiões, timers de inatividade, verificações de vida e eventos de liberação.
- O Legado Digital reúne contas on-line, cofre de credenciais mestras e assinaturas recorrentes acionáveis em emergências.
- Diretivas abrangem Testamento Vital, Preferências de Funeral e Cápsula do Tempo (texto/áudio/vídeo) liberada pelos guardiões.
- Todo o histórico crítico precisa de logs, RLS habilitado e referências claras às entidades centrais.
- Upload offline armazena apenas metadados criptografados em fila com no máximo três tentativas antes de sinalizar falha.

Antes de criar as tabelas, defina os tipos ENUM abaixo:

- asset_category_enum = ('IMOVEIS','VEICULOS','FINANCEIRO','CRIPTO','DIVIDAS')
- asset_status_enum = ('ACTIVE','PENDING_REVIEW','ARCHIVED')
- document_status_enum = ('PENDING_UPLOAD','UPLOADING','ENCRYPTED','AVAILABLE','FAILED')
- guardian_status_enum = ('INVITED','VERIFIED','BLOCKED','REVOKED')
- guardian_event_type_enum = ('INVITATION_SENT','CONTACT_CONFIRMED','REMOVED','TEST_SIMULATED')
- access_scope_enum = ('TOTAL','DOCUMENTOS')
- emergency_state_enum = ('IDLE','MONITORING','ALERT_SENT','AWAITING_RESPONSE','RELEASING','RESOLVED')
- emergency_event_type_enum = ('DETECCAO','AVISO_GUARDIAO','VERIFICACAO_VIDA','LIBERACAO','TESTE_SIMULADO')
- action_preference_enum = ('EXCLUIR','MEMORIALIZAR','TRANSFERIR')
- subscription_cycle_enum = ('MONTHLY','QUARTERLY','YEARLY','OTHER')
- life_check_channel_enum = ('PUSH','EMAIL','SMS')
- life_check_status_enum = ('SCHEDULED','SENT','RESPONDED','EXPIRED','FAILED')
- capsule_type_enum = ('TEXT','AUDIO','VIDEO')
- capsule_status_enum = ('DRAFT','SCHEDULED','RELEASED','CANCELLED')

## Tabela 1: profiles

- id: UUID, PK, referencia `auth.users.id` (ON DELETE CASCADE)
- created_at: TIMESTAMPTZ, default now()
- full_name: TEXT, not null
- avatar_url: TEXT
- zero_knowledge_ready: BOOLEAN, default false
- two_factor_enforced: BOOLEAN, default false
- onboarding_stage: TEXT, default 'start'
- headline_status: TEXT (exibir mensagens "Seguro"/"Atenção")
- trust_header_dismissed_at: TIMESTAMPTZ
- deleted_at: TIMESTAMPTZ

## Tabela 2: user_keys

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), not null, unique
- encrypted_private_key: TEXT, not null
- recovery_seed_hint: TEXT
- step_up_method: TEXT (ex.: 'biometria','senha_mestra'), not null
- secure_storage_provider: TEXT (ex.: 'SecureEnclave','Keystore')
- created_at / updated_at: TIMESTAMPTZ, default now()

## Tabela 3: device_sessions

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), not null
- device_info: JSONB (modelo, SO)
- last_seen_at: TIMESTAMPTZ, default now()
- revoked_at: TIMESTAMPTZ
- push_token: TEXT

## Tabela 4: trust_events (auditoria)

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), not null
- event_type: TEXT (ex.: 'UPLOAD_ENCRYPTED','PROTOCOLO_ATIVADO'), not null
- description: TEXT, not null
- created_at: TIMESTAMPTZ, default now()
- metadata: JSONB (detalhes adicionais)

## Tabela 5: user_checklists

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), unique, not null
- has_asset: BOOLEAN, default false
- has_guardian: BOOLEAN, default false
- life_check_enabled: BOOLEAN, default false
- protection_ring_score: INTEGER, default 0 CHECK (protection_ring_score BETWEEN 0 AND 100)
- updated_at: TIMESTAMPTZ, default now()

## Tabela 6: assets (Bens)

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), not null
- category: asset_category_enum, not null
- title: TEXT, not null
- description: TEXT
- value_estimated: NUMERIC(14,2)
- value_currency: TEXT(3) default 'BRL'
- value_unknown: BOOLEAN, default false
- ownership_percentage: NUMERIC(5,2), default 100
- has_proof: BOOLEAN, default false
- status: asset_status_enum default 'ACTIVE'
- created_at / updated_at: TIMESTAMPTZ, default now()

## Tabela 7: asset_documents

- id: BIGSERIAL, PK
- asset_id: BIGINT, FK → assets(id) ON DELETE CASCADE, not null
- storage_path: TEXT, not null
- file_type: TEXT
- encrypted_checksum: TEXT, not null
- uploaded_at: TIMESTAMPTZ, default now()

## Tabela 8: documents (Cofre)

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), not null
- title: TEXT, not null
- description: TEXT
- storage_path: TEXT, not null
- size_bytes: BIGINT
- mime_type: TEXT
- tags: TEXT[], default ARRAY[]::TEXT[]
- status: document_status_enum, default 'PENDING_UPLOAD'
- expires_at: TIMESTAMPTZ
- encrypted_at: TIMESTAMPTZ
- checksum: TEXT
- last_accessed_at: TIMESTAMPTZ
- deleted_at: TIMESTAMPTZ
- created_at / updated_at: TIMESTAMPTZ, default now()

## Tabela 9: document_upload_queue

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), not null
- document_id: BIGINT, FK → documents(id) ON DELETE CASCADE, not null
- retry_count: INTEGER, default 0
- last_retry_at: TIMESTAMPTZ
- network_policy: TEXT (ex.: 'WIFI_ONLY')
- status: document_status_enum, default 'PENDING_UPLOAD'
- max_retries: INTEGER, default 3 CHECK (max_retries <= 3)
- retry_reason: TEXT
- offline_blob_checksum: TEXT
- priority: SMALLINT, default 0

## Tabela 10: emergency_protocols

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), unique, not null
- inactivity_timer_days: INTEGER, default 60 CHECK (inactivity_timer_days IN (30,60,90))
- life_check_channel: life_check_channel_enum, default 'PUSH'
- step_up_required: BOOLEAN, default true
- status: emergency_state_enum, default 'MONITORING'
- last_check_sent_at: TIMESTAMPTZ
- last_activity_at: TIMESTAMPTZ
- created_at / updated_at: TIMESTAMPTZ, default now()

## Tabela 11: guardians

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), not null
- name: TEXT, not null
- email: TEXT, not null
- phone: TEXT
- verification_code: TEXT
- verified_at: TIMESTAMPTZ
- status: guardian_status_enum, default 'INVITED'
- access_scope: access_scope_enum, default 'DOCUMENTOS'
- invited_at: TIMESTAMPTZ, default now()
- preferred_channel: life_check_channel_enum, default 'EMAIL'
- UNIQUE(user_id, email)

## Tabela 12: guardian_events

- id: BIGSERIAL, PK
- guardian_id: BIGINT, FK → guardians(id) ON DELETE CASCADE, not null
- event_type: guardian_event_type_enum, not null
- metadata: JSONB
- created_at: TIMESTAMPTZ, default now()
- is_test: BOOLEAN, default false

## Tabela 13: life_checks

- id: BIGSERIAL, PK
- protocol_id: BIGINT, FK → emergency_protocols(id) ON DELETE CASCADE, not null
- guardian_id: BIGINT, FK → guardians(id)
- scheduled_at: TIMESTAMPTZ, not null
- response_received_at: TIMESTAMPTZ
- status: life_check_status_enum, default 'SCHEDULED'
- channel: life_check_channel_enum, not null
- response_channel: life_check_channel_enum

## Tabela 14: emergency_events (timeline)

- id: BIGSERIAL, PK
- protocol_id: BIGINT, FK → emergency_protocols(id) ON DELETE CASCADE
- guardian_id: BIGINT, FK → guardians(id)
- event_type: emergency_event_type_enum, not null
- payload: JSONB
- occurred_at: TIMESTAMPTZ, default now()
- is_test: BOOLEAN, default false

## Tabela 15: legacy_accounts

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), not null
- provider_name: TEXT, not null
- account_identifier: TEXT
- credential_type: TEXT
- action_preference: action_preference_enum, not null
- notes: TEXT
- requires_step_up: BOOLEAN, default true
- linked_credential_id: BIGINT, FK → master_credentials(id)
- verified_at: TIMESTAMPTZ
- verification_notes: TEXT
- created_at / updated_at: TIMESTAMPTZ, default now()

## Tabela 16: master_credentials

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), not null
- title: TEXT, not null
- encrypted_payload: TEXT, not null
- second_factor_hint: TEXT
- last_verified_at: TIMESTAMPTZ
- created_at: TIMESTAMPTZ, default now()
- deleted_at: TIMESTAMPTZ

## Tabela 17: subscriptions

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), not null
- service_name: TEXT, not null
- amount: NUMERIC(12,2)
- currency: TEXT(3) default 'BRL'
- billing_cycle: subscription_cycle_enum, default 'MONTHLY'
- next_charge_at: TIMESTAMPTZ
- cancel_on_emergency: BOOLEAN, default false
- notes: TEXT
- cancelled_at: TIMESTAMPTZ
- cancelled_reason: TEXT

## Tabela 18: medical_directives (Testamento Vital)

- Observação: somente o último estado é guardado neste MVP, então as colunas de auditoria garantem rastreabilidade.

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), unique, not null
- presets_json: JSONB (preferências médicas), not null
- legal_document_path: TEXT
- last_signed_at: TIMESTAMPTZ
- updated_at: TIMESTAMPTZ, default now()
- updated_by_user_id: UUID, FK → profiles(id)
- deleted_at: TIMESTAMPTZ

## Tabela 19: funeral_preferences

- Observação: também mantemos apenas o estado atual, com auditoria mínima.

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), unique, not null
- ceremony_type: TEXT (ex.: 'CREMACAO','SEPULTAMENTO')
- music_playlist: TEXT
- notes: TEXT
- contact_person: TEXT
- updated_at: TIMESTAMPTZ, default now()
- updated_by_user_id: UUID, FK → profiles(id)
- deleted_at: TIMESTAMPTZ

## Tabela 20: capsule_entries

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), not null
- title: TEXT, not null
- capsule_type: capsule_type_enum, not null
- storage_path: TEXT (para áudio/vídeo)
- message_body: TEXT (para texto)
- recipient_name: TEXT, not null
- recipient_email: TEXT
- recipient_phone: TEXT
- release_at: TIMESTAMPTZ
- status: capsule_status_enum, default 'DRAFT'
- linked_guardian_id: BIGINT, FK → guardians(id)
- allow_offline_draft: BOOLEAN, default true
- download_limit: INTEGER, default 1
- last_notified_at: TIMESTAMPTZ
- created_at / updated_at: TIMESTAMPTZ, default now()

## Tabela 21: capsule_release_events

- id: BIGSERIAL, PK
- capsule_id: BIGINT, FK → capsule_entries(id) ON DELETE CASCADE, not null
- event_type: TEXT (ex.: 'AGENDADA','ENTREGUE','CANCELADA'), not null
- event_payload: JSONB
- occurred_at: TIMESTAMPTZ, default now()

## Tabela 22: kpi_metrics

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), not null
- metric_type: TEXT (ex.: 'CHECKLIST_COMPLETED','PROTOCOL_TESTE')
- metric_value: NUMERIC(10,2)
- recorded_at: TIMESTAMPTZ, default now()
- metadata: JSONB

## Tabela 23: step_up_events

- id: BIGSERIAL, PK
- user_id: UUID, FK → profiles(id), not null
- event_type: TEXT (ex.: '2FA_SMS','BIOMETRIA','SENHA_MESTRA'), not null
- success: BOOLEAN, default false
- factor_used: TEXT
- related_resource: TEXT (ex.: 'legacy_accounts', 'emergency_protocol')
- metadata: JSONB
- occurred_at: TIMESTAMPTZ, default now()

## Instruções finais para o Supabase

- Crie todos os tipos ENUM listados antes das tabelas que os referenciam.
- Utilize `UUID` como FK padrão para tabelas ligadas a perfis; aplique `ON DELETE CASCADE` onde a remoção do usuário deve limpar dados dependentes (assets, documents, guardians etc.).
- Habilite Row Level Security (RLS) em todas as tabelas e prepare políticas básicas: proprietário visualiza/edita apenas seus registros; guardiões acessam somente o que for liberado; eventos de step-up são somente leitura.
- Considere a escala alvo (10k usuários / 50k documentos) e já crie índices específicos: `assets (user_id, category)`, `documents (user_id, status)`, `document_upload_queue (user_id, status)`, `capsule_entries (user_id, release_at)` e `subscriptions (user_id, cancel_on_emergency)`.
- Configure CHECK constraints onde citados (ex.: `max_retries <= 3`) e mantenha colunas de auditoria (`updated_by_user_id`, `deleted_at`).
- Documente eventuais funções ou triggers necessários (ex.: recalcular protection_ring_score, atualizar protection_ring_score ao inserir asset/guardian) para futuras etapas do roadmap.
