# Elo - Gestão de Legado Digital

Metadados
Detalhes
Nome do Produto
Elo
Versão
1.0 (MVP)
Status
Draft / Em Planejamento
Data de Criação
27/11/2025
Público-Alvo
Pessoas (30-60 anos) que buscam organização patrimonial e sucessória segura.

1. Visão do Produto & Objetivo
Proposta de Valor: O "Cofre da Vida" inteligente. Uma plataforma segura para organizar documentos, bens, desejos e memórias, garantindo que nada se perca e que a família esteja amparada burocraticamente.
Slogan: O elo entre o que você construiu e quem você ama.
Objetivos de Negócio (OKRs):
Lançar MVP funcional nas lojas (iOS/Android) em 4 meses.
Atingir NPS > 70 (foco em confiança e segurança).
Validar o modelo de "Botão de Emergência" com 500 usuários beta.

2. Personas (Quem usa?)
Persona A: O Organizador (Primary)
Perfil: 40 anos, casado, 2 filhos. Tem seguros, investimentos dispersos e medo de deixar a família desamparada.
Dor: "Se eu morrer amanhã, minha esposa não sabe nem a senha do banco."
Objetivo: Centralizar tudo em um lugar seguro.
Persona B: O Beneficiário (Secondary)
Perfil: Esposa(o) ou filho(a) do Organizador.
Dor: Burocracia e desconhecimento em momento de luto.
Objetivo: Acessar as informações críticas de forma rápida e guiada quando necessário.

3. Funcionalidades do MVP (Escopo)
Módulo 1: Dashboard "The Vault" (Cofre)
Visão Geral: Tela inicial focada em status de segurança.
Requisitos:
Exibir "Anel de Proteção" (% de preenchimento do perfil).
Cards de atalho para os 4 pilares (Bens, Docs, Legado, Diretivas).
Indicador visual de status ("Seguro", "Atenção").
Módulo 2: Inventário Patrimonial
User Story: Como usuário, quero cadastrar meus bens para que minha família saiba o que temos.
Requisitos Funcionais:
CRUD (Criar, Ler, Atualizar, Deletar) de ativos.
Categorias fixas: Imóveis, Veículos, Financeiro, Cripto, Dívidas.
Campo para valor estimado e upload de comprovante (PDF/JPG).
Cálculo automático de Patrimônio Líquido (Ativos - Dívidas).
Módulo 3: Cofre de Documentos
User Story: Como usuário, quero guardar cópias digitais de documentos importantes com segurança máxima.
Requisitos Funcionais:
Upload de arquivos (limite inicial 10MB/arquivo).
Criptografia na ponta do cliente (Client-side encryption) antes do upload.
Tags inteligentes: "Seguro de Vida", "Escritura", "Certidão".
Módulo 4: Protocolo de Emergência ("Dead Man's Switch")
User Story: Como usuário, quero definir quem acessa meus dados se eu faltar, sem dar acesso agora.
Requisitos Funcionais:
Cadastro de "Guardiões" (Nome, Email, Telefone).
Configuração de Timer de Inatividade (30, 60, 90 dias).
Fluxo de verificação de vida (Notificação Push + Email antes de liberar acesso).
Níveis de acesso: "Acesso Total" ou "Apenas Documentos".
Módulo 5: Legado Digital & Diretivas
User Story: Como usuário, quero definir o destino das minhas contas online e registrar meus desejos finais para orientar minha família.
Requisitos Funcionais (Legado Digital):
Catálogo de Contas: Lista pré-definida de serviços (Google, Apple, Instagram, Facebook, Bancos Digitais, Corretoras Crypto).
Instruções de Destino: Seletor para cada conta: "Excluir", "Memorializar" ou "Transferir Acesso".
Cofre de Credenciais: Campo seguro para armazenar credenciais mestras (Senha do Gerenciador de Senhas, Código de Recuperação 2FA, PIN do celular). Nota: Dados devem ter camada extra de criptografia.
Assinaturas Recorrentes: Lista de serviços a cancelar (Netflix, Spotify, Gympass) para estancar cobranças no cartão.
Requisitos Funcionais (Diretivas de Vontade):
Testamento Vital (Living Will): Formulário estruturado para preferências médicas (ex: reanimação, doação de órgãos).
Preferências de Funeral: Opções para Cremação/Sepultamento, local desejado, tipo de cerimônia.
Cápsula do Tempo (Mensagens): Funcionalidade para gravar texto, áudio ou vídeo com destinatário específico e data de liberação (ex: "Para minha filha nos seus 18 anos").

4. Requisitos Não-Funcionais (Técnicos & Qualidade)
Segurança & Privacidade (Crítico)
Criptografia: Todos os dados sensíveis devem ser criptografados em repouso (AES-256) e em trânsito (TLS 1.3).
Autenticação: Login obrigatório com 2FA (Dois Fatores) ou Biometria (FaceID/TouchID) em todo acesso.
Privacidade: O Elo (empresa) não deve ter acesso às chaves de descriptografia dos arquivos dos usuários (Arquitetura Zero-Knowledge preferível).
Design & UX (Diretrizes "Elo")
Tema: Dark Mode padrão ("Dark Luxury" - #121212 e Primary #5590a8, Secondary #4682B4).
Plataforma: Flutter (Código único para iOS e Android).
Acessibilidade: Contraste de cores aprovado na WCAG AA. Fontes grandes e legíveis.
Performance
Tempo de carregamento do Dashboard < 2 segundos.
Upload de documentos deve funcionar em background.

5. Métricas de Sucesso (KPIs)
Ativação: % de usuários que completam o cadastro de pelo menos 1 bem e 1 guardião.
Retenção: % de usuários que abrem o app pelo menos 1x ao mês (Check-in de vida).
Conversão: % de usuários Free que migram para Premium (se houver modelo freemium).

6. Plano de Lançamento (Roadmap Macro)
Fase 1 (Alpha): Desenvolvimento do Core (Cadastro + Inventário). Teste interno.
Fase 2 (Beta): Inclusão do Módulo de Emergência + Upload Seguro. Teste com 50 usuários "Friends & Family".
Fase 3 (V1.0): Polimento de UX, Auditoria de Segurança e Lançamento nas Lojas.

7. Questões em Aberto / A Definir
Qual será o modelo de monetização? (Assinatura mensal ou anual?) [A DEFINIR]
Qual provedor de Cloud usaremos para garantir a criptografia? (AWS KMS, Google Cloud?) [A DEFINIR]
Jurídico: O app terá validade legal como testamento ou é apenas informativo? (Consultar advogado) [A DEFINIR]

PRD: Elo v1.0 (MVP)
Metadados
Nome: Elo — Gestão de Legado Digital
Versão: 1.0 (MVP)
Status: Draft / Em Planejamento
Data: 27/11/2025
Público-alvo: Pessoas de 30–60 anos que buscam organização patrimonial e sucessória, com foco em segurança.
Visão, Proposta de Valor e Slogan
Visão: Ser o "Cofre da Vida" inteligente e confiável para organizar bens, documentos, legado digital e diretivas, garantindo amparo à família e redução de burocracia.
Proposta de Valor: Plataforma segura, zero-knowledge, que centraliza patrimônio, documentos e vontades, com protocolo de emergência confiável.
Slogan: O elo entre o que você construiu e quem você ama.
Objetivos e OKRs (MVP)
O1: Lançar app iOS/Android (Flutter) em 4 meses.

KR1.1: Aprovação nas lojas e 95% crash-free sessions.

O2: Atingir NPS ≥ 70 em 60 dias (foco em confiança).
KR2.1: ≥ 85% dos usuários entendem zero-knowledge (pesquisa in-app).
KR2.2: ≥ 70% concluem "Teste do Protocolo" com sucesso.

O3: Validar "Botão de Emergência" (Dead Man's Switch) com 500 usuários beta.
KR3.1: ≥ 60% ativam guardiões e janela de inatividade.
KR3.2: ≥ 40% executam "teste simulado".

Personas (simplificado)
P1 — Organizador (primária): 40 anos, casado(a), 2 filhos. Dor: falta de centralização e medo de deixar a família desamparada. Meta: centralizar bens, documentos e instruções.
P2 — Beneficiário (secundária): cônjuge/filho. Dor: burocracia no luto. Meta: acessar rapidamente informações críticas, com linguagem simples e guia.
Pilares de Navegação (uniformizados)
Bens (Inventário Patrimonial)
Documentos (Cofre de Documentos)
Legado Digital (Contas e credenciais mestras)
Diretivas (Vontades, Testamento Vital, Preferências de Funeral, Cápsula do Tempo)
Emergência (Protocolo + Guardiões) Nota: "Dashboard" (The Vault) é a tela inicial com checklist e status de segurança, mas os 5 pilares são as abas (Tab Bar). Terminologia é idêntica no Design System.

Escopo Funcional do MVP (Requisitos Funcionais com IDs)
Dashboard (The Vault)
ID
Requisito
FR-VAU-01
Exibir checklist de ativação (3 passos mínimos): adicionar 1 bem, adicionar 1 guardião, ativar verificação de vida (com CTA direto).
FR-VAU-02
Exibir status de segurança com mensagem orientada ("Falta: 1 guardião").
FR-VAU-03
Banner persistente para 2FA até estar ativo.
FR-VAU-04
"Cabeçalho de Confiança" com tooltip sobre criptografia client-side e zero-knowledge.

Bens (Inventário Patrimonial)
ID
Requisito
FR-BEN-01
CRUD de ativos com categorias fixas: Imóveis, Veículos, Financeiro, Cripto, Dívidas.
FR-BEN-02
Campo de valor estimado (máscara monetária, moeda local) e "valor desconhecido".
FR-BEN-03
Upload de comprovante (PDF/JPG) por item; indicação visual de comprovante presente.
FR-BEN-04
KPI de Patrimônio Líquido: Ativos – Dívidas (resumo).
FR-BEN-05
Busca e filtros por categoria e status de comprovante.

Documentos (Cofre)
ID
Requisito
FR-DOC-01
Upload de arquivos até 10MB (fila com reenvio automático; background upload).
FR-DOC-02
Criptografia client-side antes do envio; badge "Encrypted" e tooltip "Zero-knowledge".
FR-DOC-03
Tags inteligentes (Seguro de Vida, Escritura, Certidão) + chips de filtro.
FR-DOC-04
Ordenações (recentes, mais acessados, vencimento). Metadados: tamanho, data, validade opcional.
FR-DOC-05
Operações: mover, renomear, baixar, compartilhar link seguro (se aplicável ao MVP).

Legado Digital
ID
Requisito
FR-LEG-01
Catálogo de contas (Google, Apple, Instagram, Facebook, Bancos digitais, Corretoras crypto).
FR-LEG-02
Para cada conta, seletor: Excluir, Memorializar, Transferir Acesso (com confirmação).
FR-LEG-03
Cofre de Credenciais Mestras (senha do gerenciador, códigos 2FA, PIN do celular), protegido por step-up (biometria/senha mestra).
FR-LEG-04
Lista de assinaturas recorrentes (Netflix, Spotify, etc.) com opção "Marcar para cancelar em emergência" + campo instruções.

Diretivas (Vontades)
ID
Requisito
FR-DIR-01
Testamento Vital com presets (reanimação, doação de órgãos) + upload de documento legal.
FR-DIR-02
Preferências de Funeral (opções pré-definidas + notas).
FR-DIR-03
Cápsula do Tempo — criar mensagens (texto, áudio, vídeo) com destinatário e data de liberação; rascunho offline e envio posterior.
FR-DIR-04
Visão de agendamentos por ano; auditoria de criação/edição.

Emergência (Protocolo + Guardiões)
ID
Requisito
FR-EME-01
Cadastro de guardiões (nome, email, telefone) com verificação de contato.
FR-EME-02
Configurar janela de inatividade (30/60/90 dias) com explicação do que conta como atividade.
FR-EME-03
Verificação de vida (push + email; lembretes no dia 0, 3, 7).
FR-EME-04
Definir escopo de liberação: Acesso Total ou Apenas Documentos; granularidade futura por coleção.
FR-EME-05
Ativar protocolo com resumo e confirmação (step-up auth).
FR-EME-06
Timeline de eventos (detecção, aviso, resposta, concessão).
FR-EME-07
"Testar Protocolo (simulado)" sem liberar dados reais.

Requisitos Não Funcionais (NFRs) e Segurança
Segurança e Privacidade
ID
Requisito
NFR-SEC-01
Criptografia em repouso (AES-256) e em trânsito (TLS 1.3).
NFR-SEC-02
Client-side encryption para arquivos e cofres sensíveis; arquitetura zero-knowledge (empresa sem acesso às chaves).
NFR-SEC-03
2FA obrigatório para login; step-up para ações críticas (abrir Cofre de Credenciais Mestras, ativar Protocolo, ver documentos sensíveis).
NFR-SEC-04
Recuperação de conta com chave/seed de recuperação; fluxo educativo e teste de recuperação.
NFR-SEC-05
Logs e auditoria de acessos; encerrar sessões remotas.

Performance e Qualidade
ID
Requisito
NFR-PER-01
Dashboard inicial perceptível < 2s (skeletons).
NFR-PER-02
Upload resiliente com fila e reintentos; "aguardando Wi-Fi" quando configurado.
NFR-PER-03
95% crash-free sessions.

Acessibilidade e UX
ID
Requisito
NFR-UX-01
Contraste AA; alvos 44x44; suporte a Dynamic Type.
NFR-UX-02
Labels acessíveis (TalkBack/VoiceOver); foco visível.
NFR-UX-03
Terminologia consistente com pilares e microcópia de confiança.

Tecnologia e Plataforma
ID
Requisito
NFR-TEC-01
Flutter (iOS/Android) com arquitetura modular.
NFR-TEC-02
Theming suportado (Dark padrão, Light opcional).
NFR-TEC-03
Armazenamento seguro local para chaves (Secure Enclave/Keystore).

Fluxos Prioritários (MVP)
ID
Fluxo
FLX-01
Onboarding seguro: criar conta → 2FA → checklist (adicionar 1 bem, 1 guardião, configurar verificação de vida).
FLX-02
Upload seguro de documento: selecionar → criptografar → enviar → fila/retry → confirmar.
FLX-03
Configurar Protocolo: guardiões → janela → verificação de vida → escopo → ativar → testar simulado.
FLX-04
Definir destino de contas: selecionar conta → opção (Excluir/Memorializar/Transferir) → confirmação.
FLX-05
Criar mensagem da Cápsula: gravar → escolher destinatário/data → salvar rascunho → enviar quando online.

Métricas e Instrumentação
Métrica
Descrição
KPI-ATV
% usuários que completam checklist (1 bem + 1 guardião + verificação de vida).
KPI-RET
% usuários com check-in mensal (verificação de vida).
KPI-CONV
% que marcam 2+ pilares completos (gatilho para paywall/premium).
KPI-NPS
NPS in-app pós "Teste do Protocolo".
Eventos mínimos: onboarding steps, upload start/end, protocolo ativado/teste, diretivas salvas, legado definido.

Riscos e Mitigações
Risco
Mitigação
Perda de acesso por zero-knowledge
Onboarding com teste de recuperação.
Complexidade cognitiva
Checklist guiado; tooltips e "Saiba mais".
Confiança
"Trust Header", logs de auditoria e botão "Testar Protocolo".

Roadmap de MVP (macro)
Sprint 1–2: Fundações (auth/2FA, theming, storage seguro), Dashboard + Bens.
Sprint 3: Documentos (upload seguro, fila), tooltips de confiança.
Sprint 4: Emergência (guardiões, janela, verificação de vida, teste simulado).
Sprint 5: Legado Digital (seletores por conta) + Diretivas (Testamento Vital presets).
Sprint 6: Cápsula (texto/áudio; vídeo se viável) + hardening + A/B de checklist.
Critérios de Aceite Base (exemplos)
ID
Critério
CA-EME-01 (FR-EME-05)
Ao ativar protocolo, o usuário deve autenticar via biometria/2FA; exibir resumo; registrar evento em timeline.
CA-DOC-02 (FR-DOC-01/02)
Ao enviar documento offline, o app mantém em fila criptografada e publica automaticamente quando online; badge "Encrypted" visível após confirmação do servidor.
CA-VAU-03 (FR-VAU-03)
Enquanto 2FA não estiver ativo, banner de alerta aparece no topo do Dashboard com CTA direto para configuração.

Mapa de Navegação (Tab Bar)
Bens | Documentos | Legado | Diretivas | Emergência Nota: Home/Dashboard acessível pelo primeiro tab (Bens) ou via ícone "Home" ao centro (definir no Design).
Glossário
Zero-knowledge: arquitetura em que a empresa não detém chaves de decriptografia. Dead Man's Switch: protocolo que libera acesso se o titular não responder.
