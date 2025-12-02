# Supabase schema reference

Este documento resume o schema definido no `prompt_01_definicao_do_modelo_de_dados.md` para facilitar implementacoes futuras. Utilize-o junto ao PRD (`docs/01-product/prd-geral.md`) e mantenha as referencias aos IDs de requisitos (FR/NFR/FLX/KPI) ao criar issues ou PRs.

## Enumeracoes customizadas

Crie os tipos antes das tabelas:

- `asset_category_enum = ('IMOVEIS','VEICULOS','FINANCEIRO','CRIPTO','DIVIDAS')`
- `asset_status_enum = ('ACTIVE','PENDING_REVIEW','ARCHIVED')`
- `document_status_enum = ('PENDING_UPLOAD','UPLOADING','ENCRYPTED','AVAILABLE','FAILED')`
- `guardian_status_enum = ('INVITED','VERIFIED','BLOCKED','REVOKED')`
- `guardian_event_type_enum = ('INVITATION_SENT','CONTACT_CONFIRMED','REMOVED','TEST_SIMULATED')`
- `access_scope_enum = ('TOTAL','DOCUMENTOS')`
- `emergency_state_enum = ('IDLE','MONITORING','ALERT_SENT','AWAITING_RESPONSE','RELEASING','RESOLVED')`
- `emergency_event_type_enum = ('DETECCAO','AVISO_GUARDIAO','VERIFICACAO_VIDA','LIBERACAO','TESTE_SIMULADO')`
- `action_preference_enum = ('EXCLUIR','MEMORIALIZAR','TRANSFERIR')`
- `subscription_cycle_enum = ('MONTHLY','QUARTERLY','YEARLY','OTHER')`
- `life_check_channel_enum = ('PUSH','EMAIL','SMS')`
- `life_check_status_enum = ('SCHEDULED','SENT','RESPONDED','EXPIRED','FAILED')`
- `capsule_type_enum = ('TEXT','AUDIO','VIDEO')`
- `capsule_status_enum = ('DRAFT','SCHEDULED','RELEASED','CANCELLED')`

## Tabelas por dominio

### Identidade e seguranca

| Tabela            | Campos principais                                                                                                                                                                                        |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `profiles`        | `id (uuid, PK, FK auth.users)`, `full_name (text)`, `avatar_url`, `zero_knowledge_ready (bool)`, `two_factor_enforced (bool)`, `headline_status`, `trust_header_dismissed_at`, timestamps e `deleted_at` |
| `user_keys`       | `id (bigserial)`, `user_id (uuid unique)`, `encrypted_private_key`, `recovery_seed_hint`, `step_up_method`, `secure_storage_provider`, timestamps                                                        |
| `device_sessions` | `id`, `user_id`, `device_info (jsonb)`, `last_seen_at`, `revoked_at`, `push_token`                                                                                                                       |
| `trust_events`    | `id`, `user_id`, `event_type`, `description`, `metadata (jsonb)`, `created_at`                                                                                                                           |
| `step_up_events`  | `id`, `user_id`, `event_type`, `success`, `factor_used`, `related_resource`, `metadata`, `occurred_at`                                                                                                   |

### Checklist e protocolo de emergencia

| Tabela                | Campos principais                                                                                                                                                    |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `user_checklists`     | `id`, `user_id unique`, `has_asset`, `has_guardian`, `life_check_enabled`, `protection_ring_score (0-100)`, `updated_at`                                             |
| `emergency_protocols` | `id`, `user_id unique`, `inactivity_timer_days (30/60/90)`, `life_check_channel`, `step_up_required`, `status`, `last_check_sent_at`, `last_activity_at`, timestamps |
| `guardians`           | `id`, `user_id`, `name`, `email (unique per user)`, `phone`, `verification_code`, `verified_at`, `status`, `access_scope`, `preferred_channel`, `invited_at`         |
| `guardian_events`     | `id`, `guardian_id`, `event_type`, `metadata`, `created_at`, `is_test`                                                                                               |
| `life_checks`         | `id`, `protocol_id`, `guardian_id`, `scheduled_at`, `response_received_at`, `status`, `channel`, `response_channel`                                                  |
| `emergency_events`    | `id`, `protocol_id`, `guardian_id`, `event_type`, `payload`, `occurred_at`, `is_test`                                                                                |

### Bens e documentos

| Tabela                  | Campos principais                                                                                                                                                                                     |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `assets`                | `id`, `user_id`, `category`, `title`, `description`, `value_estimated`, `value_currency (text(3))`, `value_unknown`, `ownership_percentage`, `has_proof`, `status`, timestamps                        |
| `asset_documents`       | `id`, `asset_id`, `storage_path`, `file_type`, `encrypted_checksum`, `uploaded_at`                                                                                                                    |
| `documents`             | `id`, `user_id`, `title`, `description`, `storage_path`, `size_bytes`, `mime_type`, `tags (text[])`, `status`, `expires_at`, `encrypted_at`, `checksum`, `last_accessed_at`, `deleted_at`, timestamps |
| `document_upload_queue` | `id`, `user_id`, `document_id`, `retry_count`, `last_retry_at`, `network_policy`, `status`, `max_retries (<=3)`, `retry_reason`, `offline_blob_checksum`, `priority`                                  |

### Legado digital e diretivas

| Tabela                   | Campos principais                                                                                                                                                                                                                                       |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `legacy_accounts`        | `id`, `user_id`, `provider_name`, `account_identifier`, `credential_type`, `action_preference`, `notes`, `requires_step_up`, `linked_credential_id`, `verified_at`, `verification_notes`, timestamps                                                    |
| `master_credentials`     | `id`, `user_id`, `title`, `encrypted_payload`, `second_factor_hint`, `last_verified_at`, timestamps, `deleted_at`                                                                                                                                       |
| `subscriptions`          | `id`, `user_id`, `service_name`, `amount`, `currency`, `billing_cycle`, `next_charge_at`, `cancel_on_emergency`, `notes`, `cancelled_at`, `cancelled_reason`                                                                                            |
| `medical_directives`     | `id`, `user_id unique`, `presets_json`, `legal_document_path`, `last_signed_at`, `updated_at`, `updated_by_user_id`, `deleted_at`                                                                                                                       |
| `funeral_preferences`    | `id`, `user_id unique`, `ceremony_type`, `music_playlist`, `notes`, `contact_person`, `updated_at`, `updated_by_user_id`, `deleted_at`                                                                                                                  |
| `capsule_entries`        | `id`, `user_id`, `title`, `capsule_type`, `storage_path`, `message_body`, `recipient_name`, `recipient_email`, `recipient_phone`, `release_at`, `status`, `linked_guardian_id`, `allow_offline_draft`, `download_limit`, `last_notified_at`, timestamps |
| `capsule_release_events` | `id`, `capsule_id`, `event_type`, `event_payload`, `occurred_at`                                                                                                                                                                                        |

### KPI e telemetria

| Tabela        | Campos principais                                                         |
| ------------- | ------------------------------------------------------------------------- |
| `kpi_metrics` | `id`, `user_id`, `metric_type`, `metric_value`, `recorded_at`, `metadata` |

## RLS e indices

- Habilite Row Level Security em todas as tabelas. Politica padrao: `auth.uid() = user_id` (ou usuario relacionado via guardian/protocolos). Para tabelas dependentes de protocolos/guardioes, utilize `EXISTS` com joins em `emergency_protocols`.
- Guardioes so enxergam dados liberados via `access_scope`; registre excecoes em ADRs antes de ampliar escopos.
- Indices recomendados: `assets (user_id, category)`, `documents (user_id, status)`, `document_upload_queue (user_id, status)`, `capsule_entries (user_id, release_at)`, `subscriptions (user_id, cancel_on_emergency)`, `kpi_metrics (user_id, recorded_at)` e `trust_events (user_id, created_at)`.

## Observacoes operacionais

- Configure `ON DELETE CASCADE` onde indicado (assets, documents, guardians, capsule_entries, emergency tables) para manter o banco limpo ao remover perfis.
- Replique a logica do `protection_ring_score` em funcoes SQL ou TRIGGERs quando automatizarmos calculos server-side.
- Sempre registre novas colunas ou tabelas neste arquivo e em um ADR (`docs/02-architecture/adr/XXXX`) antes de rodar migracoes.
