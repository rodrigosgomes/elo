# Prompt 03 — Inventário de Bens e Patrimônio

Implemente o módulo completo de Bens (rota autenticada `/bens`) seguindo o protótipo "Bens (Inventário Patrimonial).png" e o tema Dark Luxury (#121212 de fundo, primária #5590A8). Use exclusivamente dados reais do Supabase definidos no `prompt_01`/`schema.sql`, sem mock data, e mantenha a arquitetura Provider do app.

1. Estrutura Geral e Navegação

   - Adicione o item "Bens" na Tab Bar (DS-NAV-01) apontando para `/bens`. Garanta redirecionamento para `/login` se `supabase.auth.getSession()` retornar vazio.
   - Layout da página `/bens`: AppBar (DS-NAV-02) com título "Inventário Patrimonial", ação de busca (ícone DS-INP-03) e botão fantasma "Exportar" (gera PDF/CSV em sprint futura; por ora, exibir toast "Em breve"). Corpo em blocos verticais: (a) KPI Patrimônio Líquido, (b) filtros/chips, (c) lista de cards dos bens, (d) FAB primário (DS-BTN-01 circular) "Adicionar bem" fixo no canto inferior direito.
   - Crie sub-rotas/modal sheets: `/bens/novo` (formulário), `/bens/:id` (detalhes), `/bens/:id/comprovantes` (gestão de documentos). Utilize transições tipo modal com cantos 24px conforme Material 3.

2. KPI Patrimônio Líquido (DS-CRD-04)

   - Componente no topo exibindo: título "Patrimônio Líquido", valor total em BRL com tipografia H2, variação das últimas 4 semanas (se disponível) e CTA secundário "Ver detalhamento" que abre bottom sheet com breakdown por categoria/moeda. A variação deve comparar o valor atual com o último registro em `kpi_metrics` (`metric_type='NET_WORTH'`) cuja `recorded_at` esteja pelo menos 28 dias atrás; se não existir snapshot, mostre placeholder "--" acompanhado do texto "Histórico insuficiente".
   - Lógica: considere apenas bens ativos (todas as categorias exceto `DIVIDAS` com `status != 'ARCHIVED'`) e dívidas vigentes (`category = 'DIVIDAS'` e `status != 'ARCHIVED'`). Some `value_estimated * ownership_percentage/100` para `IMOVEIS`, `VEICULOS`, `FINANCEIRO`, `CRIPTO` e subtraia o total de dívidas. Ignore itens com `value_unknown = true`, mas liste-os na folha de detalhamento em seção "Valores a estimar".
   - Persistência do histórico: toda vez que o patrimônio líquido for recalculado (inclusão/edição/arquivamento/remoção), insira um novo registro em `kpi_metrics` (`metric_type='NET_WORTH'`, `metric_value` = total BRL, metadata com breakdown). Limite o carregamento da variação a uma query que busca apenas o snapshot mais antigo >=28 dias ou, caso não encontre, o mais antigo disponível para fallback do detalhamento.
   - Multi-moeda: `value_currency` default 'BRL'. Quando diferente, utilize `FxService` para converter para BRL (cache 1h). Caso não haja cotação, mostre chip com a moeda original e inclua no breakdown separado até conversão estar disponível.
   - Exponha subtotais por categoria (ex.: Imóveis R$ X, Dívidas R$ Y) e quantidade total de bens. Atualize o KPI em tempo real ao criar/editar/arquivar bens.

3. Filtros, Busca e Ordenação

   - Barra de busca (DS-INP-03) filtrando por `title` e `description` com `ilike` no Supabase. Atualize a query conforme o usuário digita (>2 chars) com debounce 400ms.
   - Chips de categoria (DS-CHP-01) listando todas as opções do `asset_category_enum`. Permitir múltipla seleção. Chip "Todos" reseta o filtro.
   - Toggle visível "Comprovante" (DS-CTL-02) com 3 estados: Todos, Com comprovante (`has_proof = true`), Sem comprovante (`has_proof = false`).
   - Botão "Filtrar" abre bottom sheet com campos extras: status (`asset_status_enum`), faixa de valor (slider), moeda, percentual de posse (`ownership_percentage`) e ordem (Valor desc, Valor asc, Nome A-Z, Categoria). Persistir preferências por usuário/dispositivo via `SharedPreferences` (Android) / `NSUserDefaults` (iOS) / `localStorage` (web) usando chave `assets_filters_<userId>`; não sincronizar no backend nesta fase.

4. Lista de Bens (Cards DS-CRD-01)

   - Renderize `ListView` com `SliverList` e skeletons (DS-FDB-03) durante o carregamento. Paginação: carregue 50 itens por vez usando `from`, `limit` do Supabase e `onEndReached`.
   - Cada card deve mostrar: ícone por categoria, título, descrição reduzida, valor (ou "Valor desconhecido"), chip de status (`ACTIVE`, `PENDING_REVIEW`, `ARCHIVED`) coloridos conforme tema, etiqueta de comprovante (ícone cadeado verde se `has_proof`, ícone alerta âmbar se não).
   - Conteúdo adicional: percentual de posse em texto pequeno, data de atualização (`updated_at` formatada), caret/chevron indicando navegação. Ao tocar, navegar para `/bens/:id`.
   - Ações rápidas via swipe-left: "Arquivar" (set `status='ARCHIVED'` se ainda não estiver) com toast + ação "Desfazer" que reverte para o status anterior, e "Duplicar" (abre formulário preenchido, mas exige novo título). Swipe-right: "Adicionar comprovante" abre modal de upload. Impedir arquivamento de itens já arquivados (no-op) e aplicar a atualização imediata do KPI após a confirmação.

5. Detalhe do Bem (`/bens/:id`)

   - Estrutura em seções: (1) Cabeçalho com título, categoria, status, valor principal e badges de moeda/percentual. (2) Resumo financeiro (valor estimado, conversão BRL, percentual, campo "Valor desconhecido" se aplicável). (3) Bloco "Descrição e notas". (4) Bloco "Comprovantes" listando registros de `asset_documents`. (5) Timeline de auditoria simples mostrando `created_at` e `updated_at` com responsáveis (usuário atual).
   - Ações no footer: botão primário "Editar" → `/bens/:id/editar`, botão secundário "Adicionar comprovante", botão fantasma perigoso "Remover" exigindo confirmação DS-FDB-02 + step-up (ds-SEC-02) se `value_estimated > 200000` ou categoria = `IMOVEIS`. Caso o fator configurado em `user_keys.step_up_method` não esteja disponível, ofereça fallback para senha mestra e registre o fator efetivamente usado em `step_up_events`. Remover = `DELETE FROM assets WHERE id=...` após confirmar que não há dependências; mantenha fallback para apenas arquivar se o delete falhar por restrição.

6. Formulário de Cadastro/Edição (`/bens/novo`)

   - Use bottom sheet com campos DS-INP-01: Título (obrigatório), Descrição (multilinha), Categoria (dropdown com ícones), Valor estimado (TextField com máscara monetária e separador decimal conforme locale pt-BR), Moeda (dropdown ISO 4217), Toggle "Valor desconhecido" (desabilita campo de valor e adiciona dica "Tudo bem, você pode preencher depois"), Percentual de posse (slider 0–100 em passos de 5) e Checkbox "Já tenho comprovante" (se marcado, incentive upload imediato).
   - Campos avançados (accordion): status inicial (default `PENDING_REVIEW` se `has_proof` falso, senão `ACTIVE`), notas internas.
   - Validações: título ≥ 3 caracteres, valor obrigatório quando `value_unknown=false`, valor > 0, percentual >0. Mostre mensagens em pt-BR.
   - `INSERT assets`: envie `user_id`, `category`, `title`, `description`, `value_estimated` (ou null), `value_currency`, `value_unknown`, `ownership_percentage`, `has_proof=false`, `status` (default `PENDING_REVIEW`). Após sucesso, recarregue lista, atualizar KPI e disparar checklists (item 8). A duplicação deve reutilizar apenas campos textuais/financeiros, forçando `has_proof=false`, `status='PENDING_REVIEW'` e sem copiar registros de `asset_documents`.
   - `UPDATE assets`: permitir editar todos os campos exceto `user_id`. Se usuário alternar para "Valor desconhecido", zere `value_estimated` e mantenha currency apenas para referência.

7. Upload e Gestão de Comprovantes

   - Utilize bucket Supabase Storage `asset-proofs`. Fluxo: selecionar arquivo (PDF/JPG, máx. 10MB), criptografar client-side reutilizando o mesmo serviço central de documentos (`DocumentEncryptionService` ou equivalente compartilhado) para garantir zero-knowledge consistente, gerar `encrypted_checksum` (SHA-256) e enviar para Storage (`userId/assetId/timestamp.enc`) antes de inserir registro em `asset_documents` (`asset_id`, `storage_path`, `file_type`, `encrypted_checksum`).
   - Após primeiro comprovante, executar `UPDATE assets SET has_proof=true, status='ACTIVE' WHERE id=:assetId`. Caso o usuário remova o último comprovante, definir `has_proof=false` e, se `status='ACTIVE'`, retornar para `PENDING_REVIEW`.
   - UI: lista de comprovantes com nome amigável, data de upload, ações "Baixar" (descriptografa localmente) e "Remover" (confirmação). Mostrar badge "Comprovante pendente" em cards sem upload.
   - Se envio falhar (timeout/offline), exibir toast DS-FDB-01 e permitir retentativa. Registrar motivo no `metadata` de auditoria.

8. Integração com Checklist FLX-01, KPI-ATV e Dashboard

   - Após inserir o primeiro bem (`COUNT assets WHERE user_id = currentUser` retorna 1), chamar `UPDATE user_checklists SET has_asset=true, protection_ring_score = calcScore()` (mesma lógica documentada no prompt_02) e emitir `kpi_metrics` com `metric_type='CHECKLIST_ITEM_COMPLETED'`, `metadata {"item":"asset"}`.
   - Sempre que o patrimônio líquido mudar, grave linha em `kpi_metrics` com `metric_type='NET_WORTH'`, `metric_value` = valor BRL e metadata com breakdown (categoria/total). Use isso para gráficos futuros.
   - Notifique o `DashboardController` (por Provider ou `StreamController`) para que o card de Bens e o anel de proteção atualizarão sem refresh manual.

9. Controller, Estado e Integração Supabase

   - Crie `AssetsController` (ChangeNotifier) responsável por: `Future<void> loadAssets({bool refresh=false})`, `void applyFilters(AssetsFilter filter)`, `Future<void> createAsset(AssetInput input)`, `Future<void> updateAsset(...)`, `Future<void> archiveAsset(id)`, `Future<void> deleteAsset(id)`, `Future<void> uploadProof(assetId, file)`, `Future<void> removeProof(documentId)`, `Future<void> recalcNetWorth()`.
   - `loadAssets` deve executar SELECT paginado em `assets` com todos os filtros aplicados no lado do servidor. Use `supabase.channel('public:assets').on('postgres_changes', ...)` para atualizar lista em tempo real quando registros do usuário mudarem.
   - `recalcNetWorth` também busca `asset_documents` agregados para atualizar `has_proof` localmente e chama o `FxService` para converter moedas pendentes.
   - Organize modelos `AssetModel` e `AssetDocumentModel` com métodos `fromJson`. Evite lógica pesada nas widgets.
   - Trate erros Supabase exibindo Snackbar/Toast com copy "Não foi possível salvar agora" e logue `trust_events` (item 10).

10. Auditoria, Segurança e Telemetria

- Cada operação deve registrar `trust_events` com `event_type` e `description` específicos:
- `ASSET_CREATED`, `description='Bem cadastrado'`, metadata `{asset_id, category, value_currency, value_estimated}`.
- `ASSET_UPDATED`, `ASSET_ARCHIVED`, `ASSET_DELETED`, `ASSET_PROOF_UPLOADED`, `ASSET_PROOF_REMOVED`, `ASSET_ERROR` (para exceções). Inclua `user_id`, timestamp e contexto da tela.
- Para bens de alto valor (`value_estimated >= 200000 BRL` ou categoria `IMOVEIS`), exija step-up auth (DS-SEC-02) antes de permitir exclusão permanente ou download de comprovante. Quando o método preferido (`user_keys.step_up_method`) não estiver acessível, caia para senha mestra ou segundo fator disponível, registrando o fator escolhido em `step_up_events`.
- Honre RLS: sempre filtre por `user_id = currentUser.id`. Não exponha caminhos de Storage de outros usuários.
- Gatilho para step-up event: insira em `step_up_events` ao concluir a autenticação extra (registrando `event_type`, `factor_used` e `related_resource='assets'`).

  11.Testes, Performance e Acessibilidade

- Escreva testes unitários para `AssetsController` cobrindo: cálculo de patrimônio líquido (com multi-moeda, dívidas, valor desconhecido), marcação de `has_proof`, filtros aplicados. Adicione widget tests para o formulário validar máscara monetária e mensagens de erro.
- Garanta experiência fluida: `Future.wait` no carregamento inicial de assets + documentos + checklist; use memoização para não recalcular net worth em cada rebuild; carregue comprovantes sob demanda ao abrir detalhe.
- Acessibilidade: todos botões ≥ 48dp, textos em português, suporte a Dynamic Type. Forneça `Semantics` descritivos para o KPI ("Patrimônio Líquido: R$ X") e para indicadores de comprovante ("Bem sem comprovante").
- Feedback visual: skeletons para cards, toasts em erros, estados vazios com copy "Ainda não existem bens cadastrados" + botão primário para adicionar.

Entrega esperada: telas Flutter completas (`/bens`, `/bens/:id`, modais), controller/provider integrado ao Supabase, fluxo de upload com criptografia, integração com checklist/KPI e cobertura básica de testes. Tudo deve respeitar o design system (DS-CRD-01, DS-CHP-01, DS-BTN-01/02, DS-INP-01/03, DS-FDB-01/02) e NFRs (segurança, performance e acessibilidade) descritos no PRD.
