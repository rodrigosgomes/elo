# Funcionalidades do Usuário — Elo

> Documento atualizado em: Dezembro 2025
>
> Escopo: lista **somente** o que já está implementado nos módulos Login, Dashboard e Bens/Assets.

---

## 1. Autenticação (Login)

| Funcionalidade            | Descrição                                                                                                                                          |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Criar conta**           | Cadastro de novo usuário com e-mail e senha (mínimo 8 caracteres). Após criar, o usuário recebe mensagem para confirmar o e-mail antes de acessar. |
| **Entrar (Login)**        | Usuários cadastrados informam e-mail e senha. Após validação via Supabase Auth, são direcionados ao Dashboard.                                     |
| **Esqueci minha senha**   | Envia link de redefinição de senha para o e-mail informado.                                                                                        |
| **Alternar modos**        | Botão permite trocar entre "Entrar" e "Criar conta" na mesma tela.                                                                                 |
| **Mostrar/ocultar senha** | Ícone de visibilidade alterna entre exibir e mascarar o campo de senha.                                                                            |

---

## 2. Dashboard (The Vault)

### 2.1 Cabeçalho e saudação

- Exibe "The Vault" e saudação personalizada com o nome do usuário logado.
- Botão de logout para encerrar a sessão.

### 2.2 Cabeçalho de Confiança (Trust Header)

- Banner educativo explicando criptografia ponta a ponta e zero-knowledge.
- Usuário pode dispensar clicando em "Entendi"; a escolha é persistida no perfil.

### 2.3 Banner de 2FA

- Exibido quando o usuário ainda não ativou autenticação em duas etapas.
- CTA "Configurar 2FA" direciona para tela de segurança.

### 2.4 Anel de Proteção (Protection Ring)

- Indicador circular de progresso mostrando percentual de conclusão do checklist FLX-01.
- Última atividade do protocolo de emergência e status atual ("MONITORING", etc.).

### 2.5 Seção de Pilares (Pillars)

Grid com resumos rápidos de cada pilar do cofre:

| Pilar          | Informações exibidas                                                                              |
| -------------- | ------------------------------------------------------------------------------------------------- |
| Bens           | Quantidade de ativos protegidos, patrimônio líquido em BRL, chips por moeda. CTA "Adicionar bem". |
| Documentos     | Quantidade de documentos criptografados. CTA "Ver cofre".                                         |
| Legado Digital | Contas e credenciais cadastradas. CTA "Gerenciar legado".                                         |
| Diretivas      | Testamento vital, preferências de funeral, cápsulas. CTA "Configurar diretivas".                  |

### 2.6 Checklist FLX-01

Tarefas para fortalecer a proteção do cofre:

1. **Registre um bem** — cadastrar um ativo com comprovantes.
2. **Convide um guardião** — adicionar alguém de confiança para liberar diretivas.
3. **Ative verificação de vida** — configurar canal (Push, Email, SMS) e fator de step-up.

Cada item pode ser marcado; a pontuação atualiza o anel de proteção.

### 2.7 Configuração de Verificação de Vida

Bottom sheet permite:

- Selecionar canal de verificação (Push / Email / SMS).
- Habilitar/desabilitar step-up (2FA ou biometria) para confirmar resposta.
- Salvar configuração no protocolo de emergência.

### 2.8 Seção de KPIs

Gráfico sparkline mostra evolução de métricas (itens do checklist concluídos, testes de protocolo, etc.).

### 2.9 Timeline de Próximas Ações

Lista eventos futuros relevantes:

- Próxima verificação de vida.
- Guardião pendente de aceitar convite.
- Assinaturas a revisar.

---

## 3. Bens / Assets (Inventário Patrimonial)

### 3.1 Listagem de Bens

- Lista de cards com título, descrição, valor estimado (ou "Valor desconhecido"), moeda, % de posse, status e indicador de comprovante.
- **Pull-to-refresh** para atualizar dados.
- Botão "Carregar mais" para paginação.

### 3.2 Card de Patrimônio Líquido

- Exibe soma de todos os bens em BRL.
- Variação (trend) comparando últimas 4 semanas.
- Chips de breakdown por categoria.
- CTA "Ver detalhamento" abre sheet com:
  - Valores por categoria.
  - Bens aguardando estimativa.
  - Conversões FX pendentes.

### 3.3 Filtros e Busca

| Filtro                | Descrição                                                                                     |
| --------------------- | --------------------------------------------------------------------------------------------- |
| Busca por texto       | Campo para pesquisar por título ou descrição.                                                 |
| Chips de categoria    | Imóveis, Veículos, Financeiro, Cripto, Dívidas.                                               |
| Filtro de comprovante | Todos / Com comprovante / Sem comprovante (SegmentedButton).                                  |
| Filtros avançados     | Sheet com: status (Ativo, Pendente, Arquivado), faixa de valor, moeda, % de posse, ordenação. |

### 3.4 Ações no Card (Slidable)

| Ação                   | Descrição                                                                   |
| ---------------------- | --------------------------------------------------------------------------- |
| **Duplicar**           | Abre formulário pré-preenchido para criar cópia do bem.                     |
| **Arquivar**           | Muda status para "Arquivado". Se o bem for de alto valor, solicita step-up. |
| **Anexar comprovante** | Upload de documento criptografado direto do card.                           |

### 3.5 Formulário de Novo Bem / Edição

Campos disponíveis:

- Categoria (dropdown com ícones).
- Título do bem.
- Moeda e valor estimado (máscara de moeda).
- Toggle "Valor desconhecido".
- Slider de % de posse (0–100%, passos de 5%).
- Checkbox "Já possui comprovante?".
- Campos avançados (ExpansionTile): status inicial e notas internas.

Ao salvar, o bem é criado/atualizado via repositório e a lista é atualizada.

### 3.6 Detalhes do Bem (Bottom Sheet)

Seções exibidas:

| Seção                       | Conteúdo                                                                |
| --------------------------- | ----------------------------------------------------------------------- |
| Cabeçalho                   | Título, categoria, valor, badges (status, moeda, % posse).              |
| Resumo financeiro           | Valor estimado, quota proporcional, status de conversão FX.             |
| Descrição e notas           | Texto livre de anotações.                                               |
| Comprovantes criptografados | Lista de documentos com upload, download e remoção.                     |
| Timeline de auditoria       | Registro de criação e última atualização.                               |
| Ações                       | Editar, Arquivar, Remover (com confirmação e step-up quando aplicável). |

### 3.7 Cofre de Comprovantes (Asset Proofs)

Sheet dedicado para gerenciar todos os documentos de um bem:

- Upload de novos comprovantes.
- Download (solicita step-up se bem for de alto valor).
- Remoção com confirmação.

### 3.8 Step-Up de Segurança

Operações sensíveis (arquivar, remover, baixar comprovante de bem de alto valor) exigem confirmação adicional:

- O sistema verifica método preferido do usuário (biometria, security key ou senha mestra).
- Exibe sheet pedindo validação do fator.
- Se o fator não estiver disponível, fallback para senha mestra.

### 3.9 Fallback de Exclusão

Se a remoção de um bem falhar por dependências no banco (constraint violation), o sistema:

1. Registra evento de fallback.
2. Arquiva o bem automaticamente para preservar histórico.
3. Notifica o usuário sobre a decisão.

---

## 4. Navegação

- **VaultNavigationBar** fixa na parte inferior com abas:
  - **Vault** (Dashboard)
  - **Bens**
- Rotas definidas em `main.dart` permitem deep-link para detalhes, formulários e cofre de comprovantes.

---

## 5. Tema e Acessibilidade

- Design system "Dark Luxury" com paleta escura e tons roxos primários.
- Cores semânticas para success, warning e error.
- Contrastes e tamanhos de toque seguem diretrizes AA de acessibilidade.

---

## Resumo

O Elo, até o momento, oferece ao usuário:

1. Autenticação completa (cadastro, login, reset de senha).
2. Dashboard centralizado com visão geral do cofre, checklist de proteção e configurações de verificação de vida.
3. Módulo de Bens com CRUD completo, filtros avançados, comprovantes criptografados e step-up de segurança para operações sensíveis.
