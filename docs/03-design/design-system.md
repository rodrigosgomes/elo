# Elo Design System v1.0

- Nome: Elo Design System
- Versão: 1.0 (MVP), alinhado ao PRD v1.0
- Plataformas: Flutter (iOS/Android)
- Temas: Dark (padrão) e Light (opcional)
- Rastreabilidade: componentes referenciam requisitos do PRD por ID quando
  aplicável.

## 1. Princípios

- Confiança visível: comunicar segurança (zero-knowledge, criptografia) sem
  jargões.
- Consistência: grid de 8 pt, tipografia estável, ícones coerentes.
- Clareza orientada a tarefa: CTA direto, redução de passos, linguagem simples.
- Acessibilidade: AA, touch targets ≥ 44, foco visível.
- Resiliência: estados de erro/rede pensados (fila de upload, skeletons).

## 2. Tokens

### 2.1 Cores

#### Brand

- Primary: #5590A8
- Secondary: #4682B4
- Hover: #4C8AA1

#### Estados

- Success: #1F9D62
- Warning: #C77800
- Danger: #D7322D
- Info: #2F62CC
- Badge encrypted: #1F9D62 (com ícone de cadeado)

#### Dark theme (padrão)

- bg/surface: #121212
- bg/elev1: #161A1E
- bg/elev2: #1C2127
- text/primary: #E9EEF5
- text/secondary: #B7C1CF
- text/tertiary: #8A95A6
- text/inverse: #0B0D10
- line/soft: #2A3038
- line/strong: #3A414B
- chip/bg: #20262D

#### Light theme (opcional)

- bg/surface: #F6F8FB
- bg/elev1: #FFFFFF
- bg/elev2: #EEF2F7
- text/primary: #1B2430
- text/secondary: #445065
- text/tertiary: #63718A
- text/inverse: #FFFFFF
- line/soft: #D7DEE8
- line/strong: #C2CBD8
- chip/bg: #E9EFF7

### 2.2 Tipografia

- Família: Inter (Variable Font)
- Fallback: -apple-system, Roboto, sans-serif
- Implementação Flutter: `google_fonts: ^6.0.0`
- Características:
  - Números tabulares para valores financeiros
  - Variable Font (economia de ~70% vs. múltiplos arquivos)
  - Suporte completo a caracteres PT-BR
  - Otimizada para telas de alta e baixa densidade

#### Uso

| Estilo  | Tamanho/Altura | Peso | Uso                                 |
| ---     | ---            | ---  | ---                                 |
| Display | 34/40          | 600  | Valores, números de destaque        |
| H1      | 28/34          | 600  | Títulos de página, totais           |
| H2      | 22/28          | 600  | Seções, categorias                  |
| H3      | 18/24          | 500  | Subtítulos, labels de cards         |
| Body    | 16/24          | 400  | Texto principal, descrições         |
| Small   | 14/20          | 400  | Metadados, labels secundários       |
| Caption | 12/16          | 400  | Timestamps, hints, disclaimers      |

#### Pesos utilizados

- 400 (Regular): texto corrido
- 500 (Medium): ênfase suave
- 600 (Semibold): títulos e valores

### 2.3 Espaçamento e forma

- Espaçamentos base 8 pt: 4, 8, 12, 16, 24, 32.
- Raio: 12 (cartões), 8 (inputs/botões), 20 (pills).
- Bordas: 1 px padrão; 2 px em foco.

### 2.4 Elevação e sombra

- Dark: elev1 `0 1 2 rgba(0,0,0,0.40)`, elev2 `0 6 16 rgba(0,0,0,0.45)`.
- Light: elev1 `0 1 2 rgba(0,0,0,0.15)`, elev2 `0 6 16 rgba(0,0,0,0.12)`.

### 2.5 Ícones

- Estilo: linha/duotone 24 px; estados ativos usam brand/primary.

## 3. Padrões de layout

### 3.1 App shell

- Tab Bar (5 itens): Bens, Documentos, Legado, Diretivas, Emergência. Ícone
  24 + label 12; ativo em brand/primary.
- Header: 56–64 px, título central, ações à direita (busca/filtros/settings).

### 3.2 Dashboard (The Vault) — FR-VAU-01..04

- Trust Header: escudo + link "Saiba como protegemos seus dados".
- Checklist tridivido: Bens, Guardiões, Verificação de Vida, com CTA direto.
- Banner 2FA: até ativação (danger se desativado).
- Cards de atalho: para os 5 pilares com ícone + título + microcópia.

### 3.3 Listas e grades

- Inventário: itens com título, valor, caret; filtros no topo; KPI Patrimônio
  Líquido destacado.
- Cofre de Documentos: chips de filtro, badge "Encrypted", metadados e ações
  rápidas.
- Legado: cards por serviço com avatar, identificador, seletor de destino
  (Excluir/Memorializar/Transferir), toggle de status.
- Diretivas: checklist de opções (checkbox) e formulários com presets.
- Emergência: wizard em passos, timeline de eventos, botão "Testar Protocolo".

## 4. Biblioteca de componentes (IDs DS-*)

### Botões

| ID        | Tipo        | Descrição                                |
| ---       | ---         | ---                                      |
| DS-BTN-01 | Primário    | Fundo brand/primary, texto inverse       |
| DS-BTN-02 | Secundário  | Fundo bg/elev1, borda line/strong        |
| DS-BTN-03 | Fantasma    | Texto brand/primary sem fundo            |
| DS-BTN-04 | Perigoso    | Fundo danger, texto inverse              |

- Estados: default, pressed (±8% luminância), disabled (40% opacidade),
  loading.

### Inputs

| ID        | Tipo       | Descrição                                 |
| ---       | ---        | ---                                       |
| DS-INP-01 | TextField  | Padrão (label flutuante)                   |
| DS-INP-02 | Password   | Ícone cadeado + botão "Mostrar"            |
| DS-INP-03 | Search     | Ícone e clear                              |

### Controles

| ID        | Tipo              | Descrição                             |
| ---       | ---               | ---                                   |
| DS-CTL-01 | Toggle            | 44×24 (off neutro, on brand)          |
| DS-CTL-02 | Checkbox          | 20×20 (marcado brand)                 |
| DS-CTL-03 | Segmented/Selector| Para Excluir/Memorializar/Transferir |

### Cards

- DS-CRD-01 (Card de lista): ícone, título, meta; toque abre detalhe.
- DS-CRD-02 (Card de documento): título, tags, badge Encrypted, metadados,
  ações.
- DS-CRD-03 (Card de serviço conectado): avatar, identificador, destino,
  toggle; ref. FR-LEG-02.
- DS-CRD-04 (KPI): Total Net Worth/Patrimônio Líquido.
- DS-CRD-05 (Emergency banner): contador grande + CTA; ref. FR-EME-05.

### Feedback

| ID        | Tipo          | Descrição                                      |
| ---       | ---           | ---                                            |
| DS-FDB-01 | Toast         | Mensagens temporárias                          |
| DS-FDB-02 | Dialog        | Confirmação (suporta 2FA/biometria)            |
| DS-FDB-03 | Skeletons     | Para cards e listas                            |
| DS-FDB-04 | Tooltip/Info  | Informações contextuais                        |

### Navegação

| ID        | Tipo           | Descrição             |
| ---       | ---            | ---                   |
| DS-NAV-01 | Tab Bar        | 5 itens               |
| DS-NAV-02 | AppBar/Header  | Com ações             |
| DS-NAV-03 | Wizard/Stepper | Emergência            |

### Badges e chips

| ID        | Tipo             | Descrição             |
| ---       | ---              | ---                   |
| DS-BDG-01 | Encrypted        | Cadeado + "Encrypted" |
| DS-CHP-01 | Chip de filtro   | Selecionável          |
| DS-TAG-01 | Tag de categoria | Documentos            |

### Componentes de segurança

| ID        | Tipo         | Descrição                              |
| ---       | ---          | ---                                    |
| DS-SEC-01 | Trust Header | Texto curto + link                     |
| DS-SEC-02 | Step-up Auth | Biometria/2FA antes de seções sensíveis |

## 5. Interações e estados

- Pressed: escurece/clarea em ±8% (respeitar contraste AA).
- Focus: borda de 2 px em brand/primary.
- Off-line: fila de upload com status; DS-FDB-01 Toast informando tentativas.
- Erro: uso de danger com copy orientada à correção.
- "Testar Protocolo": modo simulado claro, sem dados reais; banner informativo.

## 6. Acessibilidade

- Alvos ≥ 44×44; labels descritivos de contexto ("Alternar acesso do Google").
- Dynamic Type: tipografia escala até 120% sem quebra crítica.
- Cores: contraste verificado em dark/light; não depender só de cor para estado.

## 7. Conteúdo e microcópia (tonalidade de confiança)

- "Seus arquivos são criptografados no seu aparelho antes do envio. Nem o Elo
  pode ler."
- "Você pode simular o protocolo agora. Nenhum dado será liberado."
- "Arquivos até 10MB. Podemos tentar novamente quando houver Wi-Fi."

## 8. Motion

- Durações: 120–200 ms; easing ease-out/in-out.
- Accordion/expansões: 120 ms; progress/contador suave.
- Upload: progress bar discreta; estados criptografando → enviando → confirmado.

## 9. Diretrizes por páginas (PRD)

- Dashboard: usar DS-SEC-01 (Trust Header), DS-CRD-04 (KPI), checklist com
  DS-CTL-02 (checkbox) — cobre FR-VAU-01..04.
- Bens: DS-CRD-01 com valor em H3 + meta; filtros com DS-CHP-01 — cobre
  FR-BEN-01..05.
- Documentos: DS-CRD-02, DS-BDG-01, DS-CHP-01; upload mostra skeleton e fila —
  cobre FR-DOC-01..05.
- Legado: DS-CRD-03 (avatar, selector DS-CTL-03, toggle DS-CTL-01) — cobre
  FR-LEG-01..04.
- Diretivas: formulários com presets; cápsula usa botão primário e cards com
  thumbnail — cobre FR-DIR-01..04.
- Emergência: DS-CRD-05 (banner), DS-NAV-03 (wizard), timeline (lista com
  ícones de estado) — cobre FR-EME-01..07.

## 10. Theming e implementação (Flutter)

- Um único ColorScheme por tema, tokens mapeados no `ThemeData`.
- Variantes Dark/Light nos componentes com testes de contraste.
- Componente `SecurityGate` (DS-SEC-02) injeta step-up auth antes de rotas
  sensíveis (referência PRD NFR-SEC-03).

## 11. Checklist de qualidade (design)

- Contraste AA validado em todos os estados (incluindo disabled).
- Ícones e labels consistentes com os 5 pilares; nomes iguais aos do PRD.
- Estados offline e de erro implementados com feedback claro.
- "Encrypted" badge presente em todos os locais com dados criptografados
  client-side.

## 12. Exemplos de microcópia (reutilizável)

- Trust Header: "Criptografia ponta-a-ponta. Somente você tem a chave."
- Banner 2FA: "Proteja sua conta com 2 fatores. Leva menos de 1 minuto."
- Protocolo teste: "Este é um teste. Nenhum dado será liberado."
