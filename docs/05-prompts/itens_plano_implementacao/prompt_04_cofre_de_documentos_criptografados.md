# Prompt 04 — Cofre de Documentos Criptografados

Implemente o módulo completo do Cofre de Documentos (rota autenticada `/documentos`) seguindo o protótipo "Documentos (Cofre de Documentos).png", o tema Dark Luxury (#121212 de fundo, primária #5590A8) e os requisitos FR-DOC-01..05 / NFR-SEC / NFR-PER / NFR-UX. Não utilize mocks: todas as leituras/escritas devem ir diretamente para o Supabase (`documents`, `document_upload_queue`, `profiles`, `trust_events`, `kpi_metrics`, `step_up_events`). Mantenha arquitetura Provider e garanta zero-knowledge (criptografia client-side antes de subir qualquer arquivo).

1. Estrutura Geral, Rota e Layout

   - Adicione a aba "Documentos" à `VaultNavigationBar`, navegando para `/documentos`. Verifique sessão via `supabase.auth.getSession()` e redirecione para `/login` se vazio. Permita deep-link `/documentos/:id`.
   - Layout principal: `Scaffold` com fundo #121212 e topo hero dividido em duas colunas (em telas ≥600dp) / pilha vertical no mobile. O hero inclui título "Cofre de Documentos", subtítulo reforçando zero-knowledge, ícone cadeado preenchido e badge "Encrypted" sempre visível.
   - Painel de indicadores imediatamente abaixo: três cards Material 3 mostrando (a) quantidade de documentos com `status IN ('ENCRYPTED','AVAILABLE')`, (b) espaço ocupado (somatório `size_bytes`) e (c) uploads pendentes (`COUNT document_upload_queue WHERE status IN ('PENDING_UPLOAD','UPLOADING','FAILED')`). Cada card mostra mini gráfico/sparkline conforme protótipo.
   - Barra de filtros fixada (scroll stick) com: campo de busca (`title`, `description`, `tags` via `ilike`), chips de tags sugeridas, dropdown de ordenação e botón "Filtros avançados" que abre bottom sheet (status, intervalo de validade, tamanho, tags múltiplas).
   - Corpo em `CustomScrollView`: seção "Uploads recentes" (cards em grid 2xN) seguida de "Todos os documentos" (lista). Use `SliverAppBar` colapsável para replicar layout do protótipo. Sempre mostre resumo da fila offline no rodapé (mini card com contador e CTA "Ver fila").
   - Estados vazios: mensagem "Nenhum documento criptografado ainda" + botão primário "Enviar documento". Skeletons shimmer para cards enquanto `DocumentsController.isLoading` true. Tratamento de erro com card vermelho e opção "Tentar novamente".

1. CTA de Upload, Formulário e Validações (FR-DOC-01)

   - CTAs: botão primário "Upload criptografado" no hero e FAB circular no canto inferior direito. Ambos abrem bottom sheet/modal `UploadDocumentSheet`.
   - Formulário: picker multi-arquivo (PDF, JPG, PNG, DOCX, até 10MB cada), campos "Nome amigável" (default = nome do arquivo), "Descrição", seletor de tags (chips sugeridas + campo texto), data opcional "Validade/Expira em", toggle "Priorizar upload apenas via Wi‑Fi" (default desligado), toggle "Permitir compartilhamento" (para exibir opção de link mais tarde).
   - Validação: rejeite arquivos >10MB antes de criptografar, obrigue pelo menos uma tag. Mostre contador de tamanho total quando selecionar múltiplos.
   - Ao confirmar: para cada arquivo gere `documentDraftId` local, insira em `documents` (`user_id`, `title`, `description`, `status='PENDING_UPLOAD'`, `tags`, `expires_at`, `created_at=now()`), registre placeholder `storage_path` (`userId/tmp/documentDraftId`) e `size_bytes` inicialmente 0. Em seguida crie entrada em `document_upload_queue` com `network_policy` = `'WIFI_ONLY'` se toggle ativo ou `'ANY'` caso contrário e `priority` baseado na ordem da seleção.
   - Persista metadados de UI (progress, erro) em estado local e exponha via provider para atualizar badges "Encrypting..." / "Em fila".

1. Serviço de Criptografia Client-Side e Upload Resiliente (FR-DOC-02, NFR-SEC-02)

   - Crie `DocumentEncryptionService` compartilhado, responsável por: (a) derivar chave mestra do usuário decifrando `user_keys.encrypted_private_key` com o segredo armazenado no Secure Enclave/Keystore, (b) gerar chave simétrica única por arquivo (`fileKey`, AES-256-GCM), (c) criptografar bytes localmente (chunked stream para não explodir memória), (d) calcular `checksum` SHA-256 do payload criptografado e (e) persistir `fileKey` recriptografada em `flutter_secure_storage` indexada por `document_id`.
   - Após criptografar, envie para bucket Supabase Storage `vault-documents` usando caminho `${userId}/${documentId}/${timestamp}.enc`. Atualize `documents.storage_path`, `size_bytes`, `mime_type`, `encrypted_at=now()`, `status='ENCRYPTED'`. Quando o backend confirmar disponibilidade, marque `status='AVAILABLE'`.
   - Em caso de falha ou perda de rede, mantenha arquivo criptografado no diretório temporário exclusivo do app (`path_provider`). Só delete após receber 200 OK do upload e atualização confirmada no Supabase. Nunca armazene payload não criptografado.
   - Garanta que reenvios usem `offline_blob_checksum` armazenado na fila para verificar integridade antes de subir. Respeite `max_retries <= 3` e exponha mensagens claras quando exceder.

1. Lista/Grelha de Documentos, Filtros e Ordenações (FR-DOC-03)

   - Renderize cards responsivos: ícone baseado na tag principal, título, descrição curta, chips de tags, metadados (tamanho formatado, `updated_at`, `expires_at`), e badges de status:
     - `status='PENDING_UPLOAD'|'UPLOADING'` → badge âmbar "Encrypting/Uploading".
     - `status='ENCRYPTED'|'AVAILABLE'` → badge verde "Encrypted".
     - `status='FAILED'` → badge vermelha "Falhou".
   - Permita ordenar por `updated_at desc` (default), `title asc`, `size_bytes desc`, `expires_at asc`. Combine múltiplos filtros (tags, status, range de datas). Todas as queries devem usar `supabase.from('documents').select().eq('user_id', currentUserId)` aplicando `inFilter` para tags/status.
   - Suporte busca incremental (debounce 400ms) que consulta Supabase usando `or("title.ilike.%term%,description.ilike.%term%,tags.cs.{term}")`.
   - Exiba chip "Expira em breve" quando `expires_at <= now()+30 days`. Para documentos expirados, desabilite compartilhamento até renovação.
   - Perfis com mais de 20 documentos mostram "Agrupar por tag" toggle → reorganiza lista em seções por tag principal (primeiro item da array `tags`).

1. Detalhe do Documento e Operações Avançadas (FR-DOC-04/05)

   - Ao tocar em um card abra `DocumentDetailSheet` (rota `/documentos/:id`). Estrutura:
     1. Cabeçalho com título editável, badges (Encrypted/Expira em), chips de tags e CTA "Baixar".
     2. Bloco "Metadados" exibindo tamanho, tipo, checksum, `last_accessed_at`, `expires_at` (com campo para atualizar).
     3. Timeline de auditoria listando `trust_events` relacionados ao `document_id`.
     4. Seção "Operações" com botões: Renomear, Mover para coleção (escolhe tag primária), Editar tags, Baixar, Compartilhar link seguro, Baixar chave (apenas debug interno), Remover.
   - Renomear / editar descrição / atualizar validade: execute `UPDATE documents SET title=?, description=?, expires_at=?, updated_at=now() WHERE id=:id AND user_id=:uid`. Atualize UI imediatamente e registre evento `trust_events`.
   - Mover: interprete a primeira tag como "Coleção". Atualize `tags[1..]` preservando demais. Para mudar coleção, substitua `tags[0]`.
   - Compartilhar: gere signed URL curto via `supabase.storage.from('vault-documents').createSignedUrl(storage_path, expiresIn: 3600)` somente se documento estiver `status='AVAILABLE'`. Antes de gerar, exija step-up se `profiles.two_factor_enforced=false` ou se tag principal ∈ { "Escritura", "Seguro de Vida", "Documentos Pessoais" }. Registre evento `trust_events (event_type='DOC_SHARE')` + `step_up_events` quando step-up ocorrer. Exiba modal mostrando tempo restante e botão "Revogar" que invalida link (delete signed url + registra evento).
   - Download: baixe arquivo criptografado, recupere `fileKey` do Secure Storage, decifre localmente e entregue ao usuário. Exija step-up para tags sensíveis ou se o documento foi compartilhado >3 vezes. Atualize `documents.last_accessed_at` e grava `trust_events`.
   - Remover: apresente diálogo de confirmação com copy "Excluir de forma permanente". Na confirmação, (a) delete do Storage, (b) `DELETE FROM documents WHERE id=:id AND user_id=:uid` ou, se preferir retenção, `UPDATE documents SET deleted_at=now()` e esconda do feed, (c) limpe registros correspondentes em `document_upload_queue`, (d) remova `fileKey` local.

1. Fila Offline, Reenvio Automático e Monitoramento

   - Crie painel "Fila de Upload" (sheet acessado pelo rodapé) listando entradas de `document_upload_queue` com status, `retry_count`, `network_policy`, `last_retry_at`. Permita ações: "Forçar reenvio agora" (set `status='PENDING_UPLOAD'`, `retry_reason=null`), "Editar política de rede" (update `network_policy`), "Remover da fila" (remove entry + marca documento como `FAILED`).
   - Escute conectividade (package `connectivity_plus`). Quando rede voltar ou Wi‑Fi disponível para itens `WIFI_ONLY`, reprocessar automaticamente respeitando `max_retries`. Atualize `status` para `UPLOADING` enquanto envia e `FAILED` com `retry_reason` quando atingir limite.
   - Mostre notificações locais (snackbar/toast) quando fila estiver limpa, quando um upload falhar e quando o badge "Encrypted" ficar ativo.
   - Forneça log compacto no painel com últimas 5 ações da fila (sucesso, falha, aguardando Wi‑Fi) com ícones e horários.

1. Tags Inteligentes, Chips e Sugestões

   - Pré-carregue lista fixa de tags recomendadas do PRD: "Seguro de Vida", "Escritura", "Certidão", "Contrato", "Comprovantes Fiscais", "Documentos Pessoais". Exiba-as como chips selecionáveis na barra de filtros e dentro do modal de upload.
   - Permita tags customizadas: input com auto-complete (mostra tags existentes do usuário). Garanta deduplicação (`tags` em minúsculas).
   - Ao enviar arquivos, sugira tags automaticamente analisando nome/mime (ex.: se nome contém "certidao", marque "Certidão"). Usuário pode ajustar antes de confirmar.
   - Persistência: `tags` são gravadas como array text na coluna `documents.tags`. Use `contains` para filtros e a primeira tag define coleção exibida na UI.
   - Exiba chips "Selecionar múltiplos" para realizar filtros combinados (AND). Sempre sincronize seleção com o estado do controller.

1. Controllers, Serviços e Integrações Supabase

   - Crie `DocumentsController` (ChangeNotifier) responsável por `loadInitialData()`, `refreshDocuments()`, `startUpload(List<DocumentUploadInput>)`, `retryUpload(int queueId)`, `updateDocument(DocumentInput)`, `moveDocument(...)`, `deleteDocument(...)`, `shareDocument(...)`, `downloadDocument(...)`, `applyFilters(DocumentFilterState)`. Ele deve carregar `documents`, `document_upload_queue`, `trust_events` relacionados e expor `ValueNotifier<List<DocumentModel>>`.
   - Implemente `DocumentQueueWorker` (classe separada ou serviço singleton) rodando timers para processar fila e reagir a eventos de conectividade. Ele lê `document_upload_queue` (status pendentes) e chama `DocumentEncryptionService` + Storage. Atualize a fila com `retry_count++`, `last_retry_at=now()` a cada tentativa e delete linha após sucesso.
   - Use `supabase.channel('public:documents')` e `supabase.channel('public:document_upload_queue')` para receber `postgres_changes` e manter UI sincronizada sem refresh manual.
   - Em cada alteração que impacta contagem total, notifique `DashboardController` (via Provider ou EventBus) para atualizar o card "Documentos" mostrado no Dashboard.
   - Garanta que todo controller valide `auth.uid()` antes de executar `select/update/delete` respeitando as políticas RLS definidas em `schema.sql`.

1. Segurança, Auditoria e KPIs

   - Respeite NFR-SEC-01..05: comunicação TLS 1.3, criptografia client-side obrigatória, 2FA/step-up em operações críticas (download, compartilhamento, exclusão). Armazene chaves somente em Secure Storage local.
   - Registre `trust_events` em todos os pontos sensíveis: `DOC_UPLOAD_STARTED`, `DOC_UPLOAD_FINISHED`, `DOC_UPLOAD_FAILED`, `DOC_DOWNLOAD`, `DOC_SHARE_CREATED`, `DOC_SHARE_REVOKED`, `DOC_DELETED`, `DOC_ERROR`. Inclua `metadata` com `document_id`, `file_name`, `tags`, `network_policy`, `retry_count`.
   - Logue `step_up_events` quando o usuário realiza step-up (campos `event_type='DOC_STEP_UP'`, `factor_used`, `related_resource='documents'`).
   - Instrumente KPIs: insira em `kpi_metrics` registros `metric_type='DOC_ENCRYPTED'` (quando `status` vira `ENCRYPTED`), `metric_type='DOC_DOWNLOAD'`, `metric_type='DOC_SHARE'` com `metric_value=1` e metadata contextual. Esses valores alimentam indicadores KPIs do Dashboard/KPI-ATV/KPI-RET.
   - Exiba tooltip no hero "Como protegemos seus arquivos" reutilizando copy do Cabeçalho de Confiança; ao abrir, registre `trust_events` (`event_type='DOC_TRUST_TOOLTIP'`).

1. Testes, Performance e Acessibilidade

   - Tests unitários:
     - `DocumentEncryptionService` (valida geração de checksum, criptografia AES-GCM e armazenamento da chave).
     - `DocumentQueueWorker` (simule perda de rede, retries, respeito ao `max_retries`).
     - `DocumentsController` (filtros/sort, atualizações de status, integração com `kpi_metrics`).
   - Widget tests para: (a) renderização do hero + badges, (b) formulário de upload validando limite 10MB e Wi‑Fi toggle, (c) painel da fila mostrando estados PENDING/FAILED.
   - Performance: use `Future.wait` no carregamento inicial, paginação (limite 50 docs por fetch), `ListView.builder` com `AutomaticKeepAlive` para evitar re-render. Cache preview/ícones com `Image.memory` e `CachedNetworkImage` (para thumbnails futuros).
   - Acessibilidade: textos e botões em pt-BR, tamanhos mínimos 48dp, contraste AA, `Semantics` descrevendo estado da criptografia ("Documento 100% criptografado"). Suporte a `textScaleFactor` e navegação por teclado (focus outlines).
   - Observabilidade: capture exceções em Sentry/Crashlytics (se habilitado) e sempre mostre feedback ao usuário ("Upload em fila — reenviaremos assim que possível"). Documente no README como configurar variáveis `SUPABASE_URL/KEY` para testes deste módulo.

Entrega esperada: telas Flutter completas (`/documentos`, detail sheet, fila offline), serviços de criptografia/upload, controllers/providers conectados ao Supabase, telemetria/trust events configurados e cobertura básica de testes garantindo a resiliência dos uploads client-side encrypted, fila offline com reenvio automático, badge "Encrypted", tags inteligentes e operações avançadas conforme PRD e protótipo.
