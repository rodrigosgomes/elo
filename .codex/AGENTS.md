# GPT Codex Agents Guide for Elo

Esta versao foi alinhada ao PRD oficial (`docs/01-product/prd-geral.md`) para garantir que agentes GPT Codex atuem de forma consistente com a visao do produto e os requisitos do MVP.

---

## Quick story - why this exists

O PRD descreve o Elo como o "Cofre da Vida": um app Flutter + Supabase zero-knowledge que organiza bens, documentos, diretivas e protocolos de emergencia. Este guia consolida arquitetura atual, convencoes e prioridades para que cada contribuicao avance os objetivos do MVP com seguranca e qualidade.

---

## Visao do produto (resumo do PRD)

- Proposta de valor: centralizar patrimonio, documentos e desejos para proteger familias em momentos criticos.
- Slogan: "O elo entre o que voce construiu e quem voce ama".
- Publico-alvo: pessoas de 30-60 anos com patrimonio disperso e preocupacao sucessoria.
- Pilares do MVP: Dashboard (The Vault), Bens, Documentos, Legado Digital, Diretivas, Emergencia.
- Requisitos criticos: criptografia ponta a ponta, 2FA obrigatorio, UX "Dark Luxury" (dark mode padrao, primary #5590A8), acessibilidade AA, uploads resilientes, protocolo de guardioes.

Sempre referencie `docs/01-product/prd-geral.md` para IDs de requisitos (FR/NFR/FLX/KPI) ao abrir issues, PRs ou planejar features.

---

## Arquitetura e estrutura atual

- **Frontend**: Flutter (Material 3). Entrada em `lib/main.dart` com inicializacao do Supabase e roteamento entre `LoginScreen` e `HomeScreen`.
- **Pastas principais**:
  - `lib/screens/`: telas; crie subpastas por pilar (ex.: `screens/bens/`).
  - `lib/services/`: integracao com Supabase (`AuthService`, servicos futuros de guardioes, inventario etc.).
  - `lib/theme/`: `AppTheme` refletindo Dark Luxury.
  - `assets/`: icones/imagens utilizados nas telas.
- **Backend**: Supabase (Postgres + Auth + Storage). As credenciais atuais em `main.dart` sao placeholders e devem ser extraidas para env vars antes de producao.
- **State management**: Provider (definido como padrao no projeto; expanda o uso conforme novos modulos forem criados).
- **Plataformas**: Android, iOS, Web e desktop ja scaffoldados.

Enquanto nao migrarmos para uma arquitetura feature-first completa, mantenha consistencia criando subestruturas por dominio dentro de `screens/` e `services/` e descreva planos de refatoracao maiores em ADRs.

---

## Papeis dos agentes

- **Code authoring**: implementar funcionalidades dos pilares do PRD, integrar com Supabase/Providers e escrever testes correspondentes.
- **Code reviewer**: validar requisitos criticos (seguranca, UX, acessibilidade), apontar riscos, sugerir melhorias e cobrar testes/lints.
- **Issue/PR writer**: redigir artefatos claros citando IDs do PRD, passos de reproducao e criterios de aceite.
- **Security/Migration**: zelar por criptografia client-side, controle de acesso, politicas RLS e eventuais migracoes de dados.

---

## Convencoes obrigatorias

- **Idioma**: codigo, comentarios e commits em ingles; strings visiveis ao usuario em portugues seguindo a terminologia do Design System (`docs/03-design/design-system.md`).
- **Separacao de responsabilidades**: widgets cuidam de UI; logica de dominio vai para services/providers/controllers.
- **Async seguro**: respeite `context.mounted` apos awaits e trate erros Supabase com mensagens amigaveis.
- **Terminologia**: use os nomes dos pilares (Bens, Documentos, Legado, Diretivas, Emergencia) em rotas, estados e testes.
- **Secrets**: nunca comitar chaves reais. Utilize `.env`/`--dart-define` e documente placeholders em `README.md` e `docs/04-guides/setup-ambiente.md`.
- **Acessibilidade**: mantenha contraste AA, alvos 44x44 e suporte a Dynamic Type/TalkBack/VoiceOver.

---

## Supabase & dados sensiveis

- Centralize autenticacao em `AuthService`; novos fluxos (guardiao, inventario, uploads) devem ter services dedicados registrados no Provider.
- Antes de criar tabelas/politicas, registre uma ADR em `docs/02-architecture/adr/` (ex.: `0001-escolha-tecnologia-cofre.md`).
- Implementacoes de upload/documentos precisam garantir criptografia client-side antes do envio (requisito zero-knowledge do PRD).
- Registre logs/auditoria para eventos criticos (FR-EME-06) e valide step-up auth (biometria/2FA) para acoes sensiveis.

---

## Ambiente local & comandos uteis

- Dependencias: `flutter pub get`.
- Execucao: `flutter run` (adicione `--dart-define SUPABASE_URL=... --dart-define SUPABASE_ANON_KEY=...`).
- Analise: `flutter analyze` (obrigatorio antes de commit/PR).
- Formatacao: `dart format .`.
- Testes: `flutter test` ou arquivos especificos (`flutter test test/widget_test.dart`). Use `--coverage` quando solicitado.
- Documente scripts auxiliares em `docs/04-guides/` e mantenha o `README.md` atualizado com pre-requisitos.

---

## Prioridades do MVP (segundo o PRD)

1. **FLX-01 onboarding seguro**: cadastro, 2FA, checklist (1 bem + 1 guardiao + verificacao de vida).
2. **FR-BEN-01..05 inventario patrimonial** com KPI de patrimonio liquido e upload de comprovantes.
3. **FR-DOC-01..05 cofre de documentos** com uploads resilientes, fila offline e badge "Encrypted".
4. **FR-EME-01..07 protocolo de emergencia**: guardioes, timer, verificacao de vida, step-up auth e teste simulado.
5. **FR-LEG-01..04 legado digital** e **FR-DIR-01..04 diretivas** para contas online, credenciais mestras e capsula do tempo.

Relacione cada tarefa/issue/commit ao ID do requisito correspondente para manter rastreabilidade.

---

## Workflow de branches, commits e PRs

- Branches: `feature/<resumo>` ou `fix/<resumo>` (ex.: `feature/guardioes-crud`).
- Commits: mensagem curta e imperativa. Cite issue quando existir (`feat: add guardians provider (#12)`).
- Pull requests devem incluir:
  1. O que mudou e por que (cite FR/NFR/FLX).
  2. Passos para testar localmente (com comandos/env vars).
  3. Impactos em Supabase, storage ou seguranca.
  4. Evidencias (prints, videos, logs de testes) para flows criticos.

---

## Testes & qualidade

- Estruture `test/` espelhando `lib/` (ex.: `test/screens/login/login_screen_test.dart`).
- Use mocks/fakes para Supabase e storage; evite chamadas reais em testes automatizados.
- Cubra fluxos prioritarios: checklist do Dashboard, CRUD de Bens, uploads, protocolo de guardioes, capsula do tempo.
- Sempre execute `flutter analyze` e `flutter test` antes de abrir PR; documente saidas relevantes.
- Para criptografia e seguranca, adicione testes que validem ausencia de dados em texto puro e checagens de step-up auth.

---

## Referencias rapidas

- PRD completo: `docs/01-product/prd-geral.md`.
- Guia de ambiente: `docs/04-guides/setup-ambiente.md`.
- Design System: `docs/03-design/design-system.md`.
- ADRs: `docs/02-architecture/adr/`.

Cite explicitamente essas fontes em issues/PRs quando usar requisitos ou decisoes deles.

---

## Prompt templates uteis

- **Implementar requisito do PRD**
  > "Implemente o FR-BEN-01 criando tela e servico para CRUD de bens com Provider. Registre o service, escreva testes em `test/bens/` e atualize o checklist do Dashboard."
- **Investigar bug critico**
  > "Investigue por que o fluxo FLX-03 (Protocolo) ignora o timer de inatividade e proponha correcao com testes e referencias ao PRD."
- **Planejar integracao Supabase**
  > "Modele as tabelas necessarias para FR-EME-01 guardioes, descrevendo RLS, colunas e migracao em uma ADR."

---

## Do / Don't checklist

### Do

- Referencie IDs do PRD em issues, commits e PRs.
- Preserve o tema Dark Luxury e as diretrizes de acessibilidade.
- Valide flows criticos com testes e, se possivel, gravacoes curtas.
- Documente decisoes arquiteturais ou de seguranca em ADRs antes de implementa-las.

### Don't

- Comitar chaves Supabase, tokens ou dados sensiveis reais.
- Colocar regras de negocio complexas diretamente em widgets.
- Ignorar requisitos de seguranca (2FA, zero-knowledge, step-up auth, logs).
- Adicionar dependencias ou alterar arquitetura sem justificativa documentada.

---

Siga este guia ao colaborar: ele conecta o trabalho diario ao PRD e garante que o Elo entregue confianca, seguranca e clareza para as familias.
