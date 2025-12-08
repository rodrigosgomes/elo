# Elo — Gestão de Legado Digital

Elo é o "Cofre da Vida" que conecta os bens, documentos e diretivas de um legado digital com protocolos de emergência, tudo protegido por uma arquitetura zero-knowledge em Flutter + Supabase. O MVP entrega os pilares dashboard, bens, documentos, legado/diretivas e emergência descritos no PRD (docs/01-product/prd-geral.md) e é calibrado para clientes que valorizam segurança, clareza e governança para quem fica.

## MVP em foco

- **Dashboard (The Vault)**: anel de proteção, cartões dos pilares, status didático (Seguro/Atenção) e checklist FLX-01 com CTA para adicionar 1 bem, 1 guardião e ativar verificação de vida. Banner persistente lembra 2FA até a autenticação de segundo fator estar ativa.
- **Bens (Inventário Patrimonial)**: CRUD com categorias (Imóveis, Veículos, Financeiro, Cripto, Dívidas), máscara monetária, indicador de valor desconhecido, upload criptografado de comprovantes e filtros/ busca baseados em categoria/status, combustível para o cálculo automático de patrimônio líquido.
- **Documentos (Cofre de Documentos)**: upload de até 10 MB com criptografia client-side, fila de reenvio e badges “Encrypted”; metadados, tags inteligentes e operação segura para renomear, baixar e, futuramente, compartilhar links medidos.
- **Emergência (Protocolo Dead Man's Switch)**: guardiões verificados, timer de inatividade (30/60/90 dias), verificação de vida (push/email) com step-up, timeline de eventos e opção de teste simulado; liberações condicionais a escopos (total/documentos) conforme FR-EME.
- **Legado Digital & Diretivas**: catálogo de contas estratégicas, ações (excluir/memorializar/transferir), cofre de credenciais mestras com camada extra, assinaturas recorrentes marcadas para cancelamento em emergência, diretivas médicas, preferências de funeral e cápsula do tempo multi-mídia para mensagens futuras.

## Segurança e confiança

- Arquitetura zero-knowledge com criptografia AES-256 em repouso, TLS 1.3 em trânsito e chaves do usuário armazenadas com suporte a Secure Enclave / Keystore.
- 2FA obrigatória e step-up para ações críticas; eventos de confiança e step-up registrados em `trust_events` e `step_up_events`.
- RLS em todas as tabelas Supabase (`assets`, `documents`, `guardians`, `emergency_*`, etc.). Consulte os tipos customizados e políticas recomendadas no resumo de schema (`docs/02-architecture/supabase_schema.md`).
- Fluxos de recuperação guiados com seed hint e métricas de disponibilidade visualizadas diretamente no dashboard.

## Arquitetura e dados

- Frontend: Flutter 3 mantendo estado em Provider/ChangeNotifier; telas em `lib/screens/*`, serviços em `lib/services/*` e theming Dark Luxury em `lib/theme/app_theme.dart`.
- Supabase (Auth, PostgREST, Storage, Realtime); a configuração dinâmica vive em `lib/config/app_config.dart`, que lê valores via `--dart-define`.
- Controle de uploads, buckets e políticas devem sempre acompanhar o plano `docs/01-product/prd-geral.md` e o schema `supabase/schema.sql`; extensões e triggers são discutidas em `docs/02-architecture/adr/`.
- Telemetria mínima: onboarding, uploads, checklist, protocolo, diretivas e legado; KPIs (KPI-ATV, KPI-RET, KPI-CONV, KPI-NPS) instrumentados em `kpi_metrics`.

## Configuração local

1. Instale o Flutter 3+ e o Dart 3+; use o canal estável.
1. Configure variáveis via `--dart-define` antes de rodar:

  ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://<seu>.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=<anon-key> \
     --dart-define=SUPABASE_EMAIL_REDIRECT_URL=https://<seu>.supabase.co/auth/v1/callback
  ```

1. Instale dependências com `flutter pub get` e sincronize qualquer bucket/policy do Supabase executando `supabase/schema.sql`.

## Desenvolvimento e qualidade

- Lint: `flutter analyze`
- Formatação: `dart format .`
- Testes: `flutter test` (ou `flutter test test/screens/...` para suites específicas).
- Observabilidade: adicione logs em `services`/`controllers` para capturar taxa de sucesso do checklist e dos uploads, mantendo sus métricas no Supabase.

## Métricas e instrumentação

- KPI-ATV: percentual de usuários que completam a checklist de ativação (1 bem + 1 guardião + verificação de vida).
- KPI-RET: check-ins mensais do protocolo de emergência.
- KPI-CONV: número de pilares com 2+ seções completas.
- KPI-NPS: pesquisa pós-teste do protocolo e eventos de confiança gravados em `trust_events`.
- Todos os eventos críticos (upload iniciado/concluído, protocolo ativado/teste) são logados para auditoria.

## Implantação

- Android: `flutter build apk` ou `flutter build appbundle`
- iOS: `flutter build ios`
- Web/Desktop: `flutter build web` / `flutter build windows`
- Lembre de ajustar os `--dart-define` e variáveis de ambiente no CI antes de cada build.

## Documentação complementar

- PRD completo e roadmap: `docs/01-product/prd-geral.md`
- Schema e tipos Supabase: `docs/02-architecture/supabase_schema.md` e `supabase/schema.sql`
- Setup detalhado: `docs/04-guides/setup-ambiente.md`
- Design tokens e protótipos Dark Luxury: `docs/03-design/design-system.md` + `docs/03-design/prototype/`
- ADRs e decisões técnicas: `docs/02-architecture/adr/`

## Licença

MIT License
