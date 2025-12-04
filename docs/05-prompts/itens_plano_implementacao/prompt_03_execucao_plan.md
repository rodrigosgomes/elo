# Plano de Execução — Prompt 03 (Inventário de Bens e Patrimônio)

## Objetivos

- Entregar o fluxo completo do módulo de Bens (`/bens`, `/bens/:id`, `/bens/novo`, `/bens/:id/comprovantes`) alinhado ao protótipo "Bens (Inventário Patrimonial).png" e ao tema Dark Luxury.
- Garantir consistência zero-knowledge: somente dados reais do Supabase com RLS ativo e criptografia client-side para comprovantes.
- Integrar métricas e checklist (FLX-01, KPI NET_WORTH, KPI CHECKLIST) à telemetria já consumida pelo Dashboard.
- Manter arquitetura Provider, controllers testáveis e desacoplados de widgets.

## Dependências e Ativações Prévias

1. **Supabase**: tabelas `assets`, `asset_documents`, `kpi_metrics`, `user_checklists`, `trust_events`, `step_up_events` já criadas conforme `supabase/schema.sql`.
2. **FX Service**: `FxService` disponível para conversões on-demand (cache 1h).
3. **Criptografia**: reutilizar o serviço usado em Documentos (a ser extraído se necessário) para o bucket `asset-proofs`.
4. **Design Tokens**: `AppTheme.dark()` com base #121212, primária #5590A8 — manter consistência.

## Workstreams

### WS1 — Modelos, Repositório e DTOs

- Criar `lib/models/asset_model.dart` com `AssetModel`, `AssetDocumentModel`, `AssetFilters`, `NetWorthBreakdown`.
- Adicionar `AssetsRepository` em `lib/services/assets_repository.dart` com métodos:
  - `Future<List<AssetModel>> fetchAssets(AssetFilters filters, {int limit, int offset})`
  - `Future<List<AssetDocumentModel>> fetchDocuments(int assetId)`
  - `Future<AssetModel> insertAsset(AssetInput input)` / `updateAsset` / `archiveAsset` / `deleteAsset`
  - `Future<void> insertKpiSnapshot(NetWorthSnapshot snapshot)`
  - `Future<void> insertTrustEvent(...)`
  - `Future<void> upsertChecklistAfterFirstAsset()`
  - `Future<void> insertStepUpEvent(...)`
- Garantir filtros server-side usando `SupabaseQueryBuilder` com `ilike`, `in`, `gte`, `lte`, `order`.

### WS2 — Controller e Estado (Provider)

- Criar `AssetsController extends ChangeNotifier` em `lib/screens/bens/assets_controller.dart` com responsabilidades listadas no prompt.
- Implementar debounce interno (ex.: `Timer? _searchDebounce`) para busca >2 chars.
- Gerenciar paginação (pageSize=50) e streaming (`supabase.channel('public:assets')`).
- `recalcNetWorth()` deve receber lista atual + dívidas, aplicar conversões via `FxService`, ignorar `value_unknown`, persistir snapshot em `kpi_metrics` com metadata breakdown.
- Propagar eventos para `DashboardController` via `Provider`/`StreamController` simples (ex.: `StreamController<AssetsEvent>` ou callback) até definirmos bus central.

### WS3 — UI `/bens`

- Estrutura em `lib/screens/bens/bens_screen.dart`:
  - `CustomScrollView` com blocos: KPI card, filtros (chips, busca, toggles, botão "Filtrar" abre bottom sheet), lista (`SliverList` com `AnimatedList`/`ListView.builder` + skeletons).
  - `FloatingActionButton.extended` circular (DS-BTN-01) fixado.
  - KPI card exibindo valor BRL, variação 4 semanas, CTA "Ver detalhamento" abrindo bottom sheet com breakdown + "Valores a estimar".
  - Uso de `Semantics` e feedbacks (Snackbars, placeholder "Ainda não existem bens cadastrados").
- Persistir filtros localmente via `SharedPreferences` (Android), `NSUserDefaults` (iOS) e `html.window.localStorage` (web). Encapsular em `AssetsFilterStorage` service.

### WS4 — Formulários e Detalhes

- `AssetFormSheet` (`/bens/novo` e `/bens/:id/editar`): bottom sheet com campos especificados (máscara monetária `flutter_masked_text2` ou `intl` + `TextInputFormatter` custom), validações pt-BR, accordion para avançados.
- `AssetDetailSheet` (`/bens/:id`): seções (Cabeçalho, Resumo financeiro, Descrição, Comprovantes, Timeline). Footer com botões `Editar`, `Adicionar comprovante`, `Remover` (step-up >200k ou IMOVEIS).
- Swipe actions usando `Slidable` ou `Dismissible` custom com ações `Arquivar`, `Duplicar`, `Adicionar comprovante`.
- Toast "Em breve" no botão Exportar.

### WS5 — Comprovantes e Storage

- Criar `AssetProofService` reutilizando `DocumentEncryptionService` (se existente) ou introduzindo `lib/services/document_encryption_service.dart` compartilhado.
- Fluxo upload: selecionar arquivo → criptografar → gerar checksum → enviar para bucket `asset-proofs` (`userId/assetId/timestamp.enc`) → inserir `asset_documents` → atualizar `assets.has_proof`.
- Download/descriptografia com validação de step-up para alto valor.
- Remoção: excluir do storage + registro; se último, atualizar `assets` (`has_proof=false`, status `PENDING_REVIEW`).

### WS6 — KPI, Checklist e Telemetria

- Integrar `AssetsController` com `kpi_metrics` (`NET_WORTH`, `CHECKLIST_ITEM_COMPLETED`, `CHECKLIST_COMPLETED`) e `trust_events` (ASSET*CREATED|UPDATED|ARCHIVED|DELETED|PROOF*\*|ASSET_ERROR).
- Atualizar `DashboardController` (via notificação) quando patrimônio líquido alterar ou `has_asset` mudar.
- Implementar `step_up_events` logging (auth factor, related_resource='assets').

### WS7 — Testes e Observabilidade

- `test/screens/bens/assets_controller_test.dart`:
  - Mock `AssetsRepository` + `FxService` para validar cálculos (multi-moeda, dívidas, valor desconhecido, atualizações de `has_proof`).
  - Testar filtros (categoria, comprovantes, busca) e paginação.
- `test/screens/bens/asset_form_test.dart`: validações de formulário, máscara monetária e mensagens pt-BR.
- Considerar `golden tests` para KPI card e card de bem.
- Garantir `flutter analyze` limpo; adicionar logs estruturados (ex.: `debugPrint` guardado) somente em `assertions`.

## Entregáveis Incrementais

1. **Scaffolding**: rotas + telas vazias + controller com estado básico.
2. **Lista + KPI**: dados reais, filtros server-side, skeletons, FAB.
3. **Detalhes + formulário**: CRUD completo, duplicação, swipe actions.
4. **Comprovantes**: upload criptografado, badges `has_proof`.
5. **Telemetria e testes**: KPIs, checklist update, unit/widget tests.

Cada incremento deve manter o app executável (`flutter run`) e coberto por testes (`flutter test`). Documentar mudanças relevantes no README/SETUP se novos comandos ou dependências forem introduzidos.
