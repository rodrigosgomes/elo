# Prompt 02 — Dashboard The Vault e Checklist

Crie a Dashboard "The Vault" completa (rota autenticada `/dashboard`) do Elo, garantindo consistência com o tema Dark Luxury (tons #121212, primária #5590A8) e com o protótipo "Dashboard (The Vault) — tela inicial com checklist e status". Use o modelo de dados definido no prompt_01, sem mock data.

1. Estrutura Geral e Layout

   - Utilize Scaffold/Material 3 com background #121212 e padding horizontal de 24px. Layout vertical em blocos: cabeçalho de confiança, banner 2FA, anel de proteção + status, cards dos pilares, checklist FLX-01, seção KPI/telemetria e lista de próximos passos.
   - Rota protegida: redirecionar para `/login` se `supabase.auth.getSession()` retornar vazio.
   - Crie provider/controller `DashboardController` para orquestrar leituras (profiles, user_checklists, assets, guardians, emergency_protocols, kpi_metrics) e emitir eventos.

1. Cabeçalho de Confiança

   - Componente exibido no topo enquanto `profiles.trust_header_dismissed_at` estiver `NULL`.
   - Conteúdo: título "Cabeçalho de Confiança", texto curto explicando criptografia client-side e botão "Entendi".
   - Ao clicar em "Entendi": `UPDATE profiles SET trust_header_dismissed_at = now()` e ocultar o componente após sucesso.

1. Banner 2FA Persistente

   - Se `profiles.two_factor_enforced = false`, renderizar banner com ícone de alerta, texto "Ative o 2FA para proteger sua conta" e CTA "Configurar 2FA".
   - Ação: navegar para `/settings/security` (criar rota placeholder) e registrar evento em `trust_events` com `event_type = '2FA_PROMPT'`, `description = 'Banner 2FA exibido no dashboard'` e metadata básica (timestamp, origem da tela).
   - Banner deixa de aparecer quando `two_factor_enforced` for true.

1. Anel de Proteção e Status Geral

   - Use componente circular (progress indicator) vinculado a `user_checklists.protection_ring_score` (0-100). Centralizar percentagem grande e texto "Anel de Proteção".
   - Aba lateral direita: mostrar `profiles.headline_status` (ex.: "Seguro", "Atenção"). Se vazio, derive: >=80 → "Seguro", 40-79 → "Atenção", <40 → "Risco".
   - Subtexto: última atividade do protocolo (usar `emergency_protocols.last_activity_at`, fallback `updated_at`).

1. Cards dos Pilares (Bens, Documentos, Legado, Diretivas)

   - Grid responsivo 2x2, cada card com ícone, título, status e CTA.
   - Dados:
   - Bens: contar `assets` ativos (status != 'ARCHIVED'); calcular patrimônio total respeitando `value_currency`. Agrupe valores por moeda e apresente: (a) total convertido para BRL usando `FxService` (cotação diária, cache local por 1h) e (b) lista de chips por moeda com os respectivos subtotais quando cotação não estiver disponível. CTA "Adicionar bem" abre modal `/bens/novo`.
     - Documentos: mostrar `COUNT documents WHERE status='ENCRYPTED'` e badge "Badge Encrypted". CTA "Ver cofre" → `/documentos`.
     - Legado: contar `legacy_accounts` e `master_credentials`; CTA `/legado`.
     - Diretivas: verificar existência em `medical_directives`, `funeral_preferences`, `capsule_entries`. CTA `/diretivas`.
   - Atualize dinamicamente ao receber stream do Supabase (use `supabase.channel` nos respectivos tópicos) ou re-carregue via `FutureBuilder` após operações.

1. Checklist FLX-01 (1 bem + 1 guardião + verificação de vida)

   - Display em card vertical com 3 itens marcáveis. Cada item possui título, descrição e botão contextual.
   - Antes de renderizar, valide se existe registro em `user_checklists` para o usuário autenticado. Caso não exista, crie automaticamente (`INSERT user_checklists` com todos os campos booleanos em false e `protection_ring_score = 0`) e prossiga com o fluxo.
     1. "Registre um bem" → verifique `user_checklists.has_asset`. Se falso, botão "Cadastrar" abre `/bens/novo`. Após inserir asset (`INSERT assets`), execute `UPDATE user_checklists SET has_asset = true, protection_ring_score = calcScore()`.
     2. "Convide um guardião" → usar `user_checklists.has_guardian`. Botão "Adicionar guardião" abre `/guardioes/novo` e após sucesso marcar true.
     3. "Ative verificação de vida" → `user_checklists.life_check_enabled`. Botão "Configurar" abre modal onde usuário define `emergency_protocols.life_check_channel` e `step_up_required`. Ao salvar (`UPDATE emergency_protocols`), marcar campo true e recalcular score.
   - `calcScore()` = média ponderada (ex.: 30 cada item, 10 restante se 2FA ativo). Documente a lógica no controller e salve no campo `protection_ring_score`.

1. Telemetria KPI-ATV/KPI-RET

   - Após cada item concluído, insira linha em `kpi_metrics`:
     - metric_type: 'CHECKLIST_ITEM_COMPLETED' com metadata `{"item":"asset"|"guardian"|"life_check"}`.
     - Quando todos concluídos, inserir 'CHECKLIST_COMPLETED'.
   - Exibir seção "Seu desempenho" com gráfico simples (barra ou linha) consumindo últimos 30 registros `kpi_metrics WHERE metric_type IN ('CHECKLIST_COMPLETED','PROTOCOL_TESTE')` ordenados por `recorded_at`. Use tema dark.

1. Timeline de Próximas Ações

   - Lista (ListView) mostrando próximos eventos:
     - Próxima verificação de vida: `SELECT MIN(scheduled_at) FROM life_checks WHERE status='SCHEDULED' AND user_id = currentUser.id`.
     - Próximo guardião pendente: `SELECT * FROM guardians WHERE status='INVITED' AND user_id = currentUser.id`.
     - Próxima assinatura marcada para cancelar: `SELECT * FROM subscriptions WHERE cancel_on_emergency=true AND cancelled_at IS NULL AND user_id = currentUser.id`.
       - Cada item com ícone, título, data e CTA (Configurar, Lembrar guardião, Revisar assinatura).

1. Integração com Supabase e Estado

   - Utilize um único Provider/ChangeNotifier chamado `DashboardController` (ou Riverpod Notifier equivalente) responsável por carregar dados e expor estado. Métodos:
     - `Future<void> loadInitialData()` – faz SELECT nas tabelas: `profiles`, `user_checklists`, `emergency_protocols`, `assets`, `documents`, `legacy_accounts`, `medical_directives`, `funeral_preferences`, `capsule_entries`, `kpi_metrics`, `life_checks`, `subscriptions`, `guardians` e chama `ensureChecklistSeeded()` antes de montar o estado.
     - `Future<void> ensureChecklistSeeded()` – faz `select().maybeSingle()` em `user_checklists` e, se vier `null`, executa `insert` com valores padrão (`has_asset=false`, `has_guardian=false`, `life_check_enabled=false`, `protection_ring_score=0`).
     - `void dismissTrustHeader()` – update profiles.
     - `Future<void> markChecklistItem(String item)` – atualiza `user_checklists`, recalcula score e insere em `kpi_metrics`.
     - `Future<void> recordTelemetria(String type, Map metadata, {required String description})` – abstrai inserts em `kpi_metrics` e já delega ao método de auditoria de confiança para manter descrições obrigatórias.
   - Garanta tratamento de erros com Snackbars/Dialogs. Em falhas Supabase, mostrar mensagem "Não foi possível atualizar agora. Tente novamente".
   - Todas queries devem filtrar por `user_id = currentUser.id` e respeitar RLS.

1. Navegação e Acessibilidade

   - Todos botões com labels em português e ícone + texto. Foco visível (outline #5590A8) e alvos mínimos 48x48dp (ideal 56dp) conforme Material 3 / WCAG.
   - Suporte a dynamic type através de `MediaQuery.textScaleFactor`. Use `Semantics` para anel de proteção e checklist.
   - Breadcrumb/Title bar: "The Vault" + saudação "Olá, {profiles.full_name}".

1. Testes e Instrumentação

   - Adicione testes widget/integration para: renderização com checklist incompleto, fechamento do cabeçalho, e fluxo concluindo itens.
   - Emita `trust_events` nos pontos críticos sempre preenchendo `description` e `metadata`:
     - Banner 2FA exibido → `event_type='2FA_PROMPT_SHOWN'`, `description='Banner 2FA exibido no dashboard'`.
     - Checklist completo → `event_type='CHECKLIST_DONE'`, `description='Checklist FLX-01 concluído'`, metadata com timestamp e itens concluídos.
     - Timeline acessada → `event_type='TIMELINE_VIEWED'`, `description='Usuário abriu timeline de próximas ações'`.
   - Log de erros: capture exceções Supabase e registre `trust_events` com `event_type='DASHBOARD_ERROR'`, `description` contextual (ex.: "Falha ao carregar cards dos pilares") e metadata detalhando stack/endpoint (sem PII).

1. Performance

   - Use `Future.wait` para carregamento inicial <2s. Exiba skeletons (shimmer) para anel, cards e checklist até dados carregarem.
   - Memorize cálculos (ex.: contagem de documentos) usando `ValueNotifier` ou caching de Provider para evitar recomputo a cada rebuild.

Entrega esperada: arquivos Dart para tela e controller/provider, integração com Supabase, componentes estilizados conforme tema, testes básicos e instrumentação KPI. Conecte tudo ao schema real (sem mocks) e garanta aderência aos requisitos FLX-01, FR-VAU-01..04 e KPIs KPI-ATV/KPI-RET.
