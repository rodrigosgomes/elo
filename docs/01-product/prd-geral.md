# Elo — Gestão de Legado Digital

## Metadados

- Nome: Elo — Gestão de Legado Digital
- Versão: 1.0 (MVP)
- Status: Draft / Em Planejamento
- Data de Criação: 27/11/2025
- Público-alvo: Pessoas de 30–60 anos que buscam organização patrimonial e sucessória, com foco em segurança

---

## 1. Visão do Produto & Objetivo

- Visão: Ser o "Cofre da Vida" inteligente e confiável para organizar bens, documentos, legado digital e diretivas, garantindo amparo à família e redução de burocracia.
- Proposta de Valor: Plataforma segura, zero-knowledge, que centraliza patrimônio, documentos e vontades, com protocolo de emergência confiável.
- Slogan: O elo entre o que você construiu e quem você ama.
- Objetivos (OKRs) — MVP:
  - O1: Lançar app iOS/Android (Flutter) em 4 meses.
    - KR1.1: Aprovação nas lojas e 95% crash-free sessions.
  - O2: Atingir NPS ≥ 70 em 60 dias.
    - KR2.1: ≥ 85% dos usuários entendem zero-knowledge (pesquisa in-app).
    - KR2.2: ≥ 70% concluem "Teste do Protocolo" com sucesso.
  - O3: Validar "Botão de Emergência" com 500 usuários beta.
    - KR3.1: ≥ 60% ativam guardiões e janela de inatividade.
    - KR3.2: ≥ 40% executam "teste simulado".

---

## 2. Personas

- Persona A — Organizador (Primária)
  - Perfil: 40 anos, casado, 2 filhos. Tem seguros e investimentos dispersos.
  - Dor: "Se eu morrer amanhã, minha esposa não sabe nem a senha do banco."
  - Objetivo: Centralizar tudo em um lugar seguro.
- Persona B — Beneficiário (Secundária)
  - Perfil: Cônjuge ou filho do Organizador.
  - Dor: Burocracia e desconhecimento no luto.
  - Objetivo: Acessar informações críticas de forma rápida e guiada.

---

## 3. Funcionalidades do MVP (Escopo)

### Pilares de Navegação

- Bens (Inventário Patrimonial)
- Documentos (Cofre de Documentos)
- Legado Digital (Contas e credenciais mestras)
- Diretivas (Vontades, Testamento Vital, Preferências de Funeral, Cápsula do Tempo)
- Emergência (Protocolo + Guardiões)
- Dashboard (The Vault) — tela inicial com checklist e status

### Módulo 1 — Dashboard ("The Vault")

- Visão: Tela inicial com status de segurança.
- Requisitos principais:
  - Exibir "Anel de Proteção" (% de preenchimento).
  - Cards para os 4 pilares.
  - Indicador visual de status ("Seguro", "Atenção").
  - Checklist de ativação: adicionar 1 bem, 1 guardião, ativar verificação de vida.
  - Banner persistente para 2FA até estar ativo.
  - "Cabeçalho de Confiança" com tooltip sobre criptografia client-side.

### Módulo 2 — Inventário Patrimonial (Bens)

- User story: cadastrar bens para que a família saiba o que existe.
- Requisitos funcionais:
  - CRUD de ativos com categorias: Imóveis, Veículos, Financeiro, Cripto, Dívidas.
  - Campo de valor estimado (máscara monetária) + opção "valor desconhecido".
  - Upload de comprovante (PDF/JPG) por item; indicação visual.
  - Cálculo automático de Patrimônio Líquido (Ativos − Dívidas).
  - Busca e filtros por categoria e status de comprovante.

### Módulo 3 — Cofre de Documentos

- User story: guardar cópias digitais com segurança máxima.
- Requisitos funcionais:
  - Upload de arquivos até 10MB por arquivo (fila + reenvio automático; upload em background).
  - Criptografia client-side antes do upload; badge "Encrypted".
  - Tags inteligentes (ex.: Seguro de Vida, Escritura, Certidão) e chips de filtro.
  - Ordenações e metadados (tamanho, data, validade).
  - Operações: mover, renomear, baixar, compartilhar link seguro (se aplicável ao MVP).

### Módulo 4 — Protocolo de Emergência (Dead Man's Switch)

- User story: definir quem acessa dados se o usuário faltar.
- Requisitos funcionais:
  - Cadastro de guardiões (nome, email, telefone) com verificação de contato.
  - Configuração de Timer de Inatividade (30/60/90 dias).
  - Fluxo de verificação de vida (notificação push + email antes de liberar).
  - Níveis de acesso: "Acesso Total" ou "Apenas Documentos".
  - Fluxo de ativação com step-up auth e opção de testar simulado.
  - Timeline de eventos (detecção, aviso, resposta, concessão).

### Módulo 5 — Legado Digital & Diretivas

- Legado Digital:
  - Catálogo de contas (Google, Apple, redes sociais, bancos, corretoras).
  - Para cada conta: opção Excluir / Memorializar / Transferir Acesso.
  - Cofre de Credenciais Mestras com camada extra de criptografia e step-up (biometria/senha mestra).
  - Lista de assinaturas recorrentes com opção "Marcar para cancelar em emergência".
- Diretivas (Vontades):
  - Testamento Vital (presets para preferências médicas) + upload de documento legal.
  - Preferências de Funeral (opções pré-definidas + notas).
  - Cápsula do Tempo: criar mensagens (texto, áudio, vídeo) com destinatário e data de liberação; rascunhos offline.

---

## 4. Requisitos Não-Funcionais (Técnicos & Qualidade)

### Segurança & Privacidade (Crítico)

- NFR-SEC-01: Criptografia em repouso (AES-256) e em trânsito (TLS 1.3).
- NFR-SEC-02: Client-side encryption e arquitetura zero-knowledge (empresa sem acesso às chaves).
- NFR-SEC-03: 2FA obrigatório; step-up para ações críticas.
- NFR-SEC-04: Recuperação de conta com chave/seed de recuperação; fluxo educativo.
- NFR-SEC-05: Logs e auditoria de acessos; encerrar sessões remotas.

### Performance & Qualidade

- NFR-PER-01: Dashboard perceptível em < 2s (skeletons).
- NFR-PER-02: Upload resiliente com fila e reintentos; opção "aguardando Wi‑Fi".
- NFR-PER-03: 95% crash-free sessions.

### Acessibilidade & UX

- NFR-UX-01: Contraste WCAG AA; alvos 44×44; suporte a Dynamic Type.
- NFR-UX-02: Labels acessíveis (TalkBack/VoiceOver); foco visível.
- NFR-UX-03: Terminologia consistente com pilares e microcópia de confiança.
- Theme: Dark Mode padrão ("Dark Luxury" — #121212; Primary #5590a8; Secondary #4682B4).

### Tecnologia & Plataforma

- NFR-TEC-01: Flutter (iOS/Android) com arquitetura modular.
- NFR-TEC-02: Theming suportado (Dark padrão, Light opcional).
- NFR-TEC-03: Armazenamento seguro local para chaves (Secure Enclave / Keystore).

---

## 5. Métricas de Sucesso (KPIs) & Instrumentação

- KPI-ATV: % usuários que completam checklist (1 bem + 1 guardião + verificação de vida).
- KPI-RET: % usuários com check-in mensal (verificação de vida).
- KPI-CONV: % que marcam 2+ pilares completos (gatilho para paywall/premium).
- KPI-NPS: NPS in-app pós "Teste do Protocolo".
- Eventos mínimos a instrumentar: onboarding steps, upload start/end, protocolo ativado/teste, diretivas salvas, legado definido.

---

## 6. Plano de Lançamento (Roadmap Macro)

- Fase 1 (Alpha): Core (auth/2FA, theming, storage seguro), Dashboard + Bens. Teste interno.
- Fase 2 (Beta): Documentos (upload seguro, fila) + Protocolo de Emergência. Teste com ~50 usuários.
- Fase 3 (V1.0): Polimento UX, auditoria de segurança, lançamento nas lojas.

Roadmap por sprints (macro):

- Sprint 1–2: Fundações (auth/2FA, theming, storage seguro), Dashboard + Bens.
- Sprint 3: Documentos (upload seguro, fila), tooltips de confiança.
- Sprint 4: Emergência (guardiões, janela, verificação de vida, teste simulado).
- Sprint 5: Legado Digital + Diretivas.
- Sprint 6: Cápsula (texto/áudio; vídeo se viável), hardening, A/B de checklist.

---

## 7. Questões em Aberto / A Definir

- Modelo de monetização: assinatura mensal ou anual? [A DEFINIR]
- Provedor de Cloud / gestão de chaves (AWS KMS, Google Cloud KMS?) [A DEFINIR]
- Validade legal das diretivas/testamento: terá valor legal ou será informativo? (Consultar jurídico) [A DEFINIR]

---

## Requisitos Funcionais — IDs (resumo)

- Dashboard
  - FR-VAU-01: Checklist de ativação (1 bem, 1 guardião, verificação de vida).
  - FR-VAU-02: Exibir status com mensagem orientada.
  - FR-VAU-03: Banner para 2FA.
  - FR-VAU-04: Tooltip sobre criptografia client-side.
- Bens
  - FR-BEN-01 a FR-BEN-05: CRUD, valor estimado, upload comprovante, patrimônio líquido, filtros.
- Documentos
  - FR-DOC-01 a FR-DOC-05: Upload até 10MB, criptografia client-side, tags inteligentes, ordenações, operações.
- Legado
  - FR-LEG-01 a FR-LEG-04: Catálogo de contas, opções por conta, cofre de credenciais, assinaturas recorrentes.
- Diretivas
  - FR-DIR-01 a FR-DIR-04: Testamento Vital, preferências de funeral, cápsula do tempo, visão por ano.
- Emergência
  - FR-EME-01 a FR-EME-07: Guardiões, janela de inatividade, verificação de vida, escopo de liberação, ativação com step-up, timeline, testar simulado.

---

## Critérios de Aceite (exemplos)

- CA-EME-01 (FR-EME-05): Ao ativar protocolo, autenticar via biometria/2FA; exibir resumo; registrar evento.
- CA-DOC-02 (FR-DOC-01/02): Envio offline mantém em fila criptografada e publica automaticamente quando online; badge "Encrypted" visível.
- CA-VAU-03 (FR-VAU-03): Enquanto 2FA não estiver ativo, banner de alerta aparece no topo do Dashboard com CTA.

---

## Riscos & Mitigações

- Perda de acesso por arquitetura zero-knowledge → onboarding com teste de recuperação.
- Complexidade cognitiva → checklist guiado, tooltips e "Saiba mais".
- Falta de confiança → "Trust Header", logs de auditoria, botão "Testar Protocolo".

---

## Glossário

- Zero-knowledge: arquitetura em que a empresa não detém chaves de decriptografia.
- Dead Man's Switch: protocolo que libera acesso se o titular não responder.
