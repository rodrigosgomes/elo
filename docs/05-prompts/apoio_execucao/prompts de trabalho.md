# Prompts de trabalho

Você é um especialista em desenvolvimento ágil de produtos digitais.
Vamos trabalhar juntos para montar um documento que reflita a criação de uma primeira versão do nosso produto para validação.
Para isso, já pensei em alguns pontos, e quero sua ajuda para duas coisas.

1. Para entender se existe alguma ambiguidade ou dúvida no que escrevi,
2. Para apontar se estou esquecendo de algo, ou algo está muito abrangente ainda.
   Segue aqui o que pensei (tire dúvidas):

## Objetivo e sucesso

Desenvolver um aplicativo de planejamento financeiro pessoal que funcione como um “planejador financeiro de bolso” para usuários jovens, guiando o usuário passo a passo na organização da sua vida financeira, com base nos princípios do CFP® (Certified Financial Planner). O Fluir deve promover educação financeira, autonomia nas decisões, e confiança na gestão do dinheiro, ajudando o usuário a construir um futuro sólido e equilibrado por meio de uma experiência digital intuitiva, segura e personalizada.

## Dúvidas

Faz sentido eu nichar mais do que isso? Que opções eu tenho?

## Quem vai usar

1. Adultos em fase de organização financeira
   Pessoas que desejam entender melhor sua situação atual, controlar gastos e começar a poupar.
   Geralmente têm renda estável, mas enfrentam dificuldades em manter um orçamento ou lidar com dívidas.
2. Jovens profissionais iniciando a vida financeira
   Recém-formados ou em início de carreira que buscam construir hábitos saudáveis desde cedo.
   Interessados em metas como reserva de emergência, compra de imóvel ou aposentadoria.

## Jobs / Funções

1. Cadastro de Perfil Financeiro
   Permitir ao usuário inserir dados como renda, dívidas, investimentos e contas bancárias.
   Aplicar onboarding progressivo para facilitar o início e personalizar recomendações.
2. Painel Financeiro Unificado
   Exibir uma visão geral da situação financeira: contas, gastos por categoria, metas e saldo disponível.
   Utilizar gráficos e indicadores visuais para facilitar a compreensão.
3. Ferramentas de Orçamento e Controle de Gastos
   Registrar receitas e despesas, categorizá-las e definir orçamentos mensais.
   Emitir alertas ao ultrapassar limites e sugerir cortes em gastos excessivos.
4. Definição de Metas e Projeções
   Permitir o cadastro de metas financeiras (ex.: aposentadoria, viagem, quitação de dívidas).
   Calcular quanto poupar por mês e acompanhar o progresso com visualizações motivadoras.
5. Segurança e Privacidade
   Implementar criptografia, autenticação forte (biometria/Face ID) e conformidade com LGPD/GDPR.
   Oferecer suporte acessível e alertas de segurança para garantir confiança do usuário.

## Dúvidas adicionais

Será que está faltando algo?

## Métricas de acompanhamento

O que deveriamos medir?

## O que não precisamos fazer agora, mas pode ser que faça sentido um dia

1. Planejamento Sucessório e Legado
   Funcionalidades como armazenamento seguro de documentos (testamento, procurações) e lembretes para revisar beneficiários.
   Parcerias com serviços de elaboração de testamento online.
2. Simuladores Avançados de Impostos e Investimentos
   Comparação de cenários tributários (investimento A vs B após impostos).
   Sugestões de alocação fiscalmente vantajosa com base no perfil do usuário.
3. Integração com Instituições Financeiras
   Importação automática de saldos e transações bancárias.
   Transferências diretas para contas de poupança ou investimento.
4. Gamificação Social e Comunidade
   Fóruns ou grupos dentro do app para troca de experiências.
   Desafios coletivos (ex.: “30 dias sem compras por impulso”) com rankings e recompensas.
5. Assistente de Voz e Chatbot Financeiro
   Consulta rápida por comandos de voz (“Qual meu saldo?”).
   Chatbot para tirar dúvidas sobre conceitos financeiros ou uso do app.

---

## 1. Contexto – Plano de Prompts

O documento a seguir é um PRD (Product Requirements Document) para uma nova aplicação de software. Ele precisa ser refinado e quebrado em um plano de desenvolvimento. O plano consistirá em uma lista ordenada de nomes de prompts, que serão enviados sequencialmente a um assistente de IA, como o Codex via VSCode, para construir a aplicação passo a passo.

## 2. Objetivo – Plano de Prompts

Gere a lista de prompts e grave no arquivo plano_prompts_implementacao.md, que devem ser enviados a cada vez, seguindo as regras e o exemplo de saída a seguir.

## 3. Regras – Plano de Prompts

Para criar a lista, você deve seguir estritamente os seguintes critérios pragmáticos e objetivos para o sequenciamento e agrupamento das funcionalidades:
O Modelo de Dados é Sempre o Primeiro: A sequência de prompts deve, invariavelmente, começar com o prompt de "Definição do Modelo de Dados", que abrange a análise de todo o escopo do PRD.

Agrupar por Jornada de Usuário: Todas as funcionalidades de interface e lógica subsequentes devem ser agrupadas em blocos que representem uma "Jornada de Usuário" completa e coesa. Se uma jornada for excessivamente complexa (especialmente em layout), ela deve ser dividida em prompts menores e mais focados.

Ordenar por Dependência Técnica: A ordem dos prompts de jornada deve seguir estritamente esta hierarquia de prioridade para garantir que cada bloco seja construído sobre uma fundação já funcional:

1. Jornada da Avaliação da Situação Atual – Diagnóstico financeiro que busca entender o usuário com o mapeamento de seus ativos e dívidas.
2. Jornada de Definição de Objetivos Financeiros – Momento que o usuário irá descrever Metas SMART e realizar a priorização.
3. Jornanda da Elaboração do Plano Financeiro – Parte mais importante do fluxo onde será feito o Orçamento, a estratégias de dívida e investimento.
4. Jornada de Implementação – Fornecer mecanismos de Acompanhamento mensal e execução do plano, permitindo sentir a evolução.
5. Jornanda de Monitoramento e Revisão Contínua – Formar de Ajustar os objetivos e 0 plano financeiro conforme mudanças de vida.

Nomenclatura: Os nomes dos prompts devem ser curtos, intuitivos e descrever a principal entrega do bloco.

## 4. Exemplo de Saída – Plano de Prompts

Prompt 1: Definição do Modelo de Dados
Prompt 2: Criação das Telas de Descoberta (Home e Busca)
Prompt 3: Criação da Página de Detalhes do Imóvel
Prompt 4: Implementação do Sistema de Autenticação
Prompt 5: Implementação da Jornada do Proprietário
Prompt 6: Implementação do Fluxo de Reserva
Prompt 7: Implementação do Sistema de Mensagens
Prompt 8: Implementação do Sistema de Avaliações

---

Crie o arquivo prompt_modelo_dados.md segundo as instruções:

## 1. Contexto – Prompt Modelo de Dados

Os documentos são partes de um PRD (Product Requirements Document). A primeira e mais fundamental etapa do refinamento técnico é extrair todos os requisitos de dados para criar um Modelo de Dados completo. Este modelo servirá como a estrutura de banco de dados para toda a aplicação e será a base para todos os prompts de desenvolvimento de funcionalidades.

## 2. Objetivo – Prompt Modelo de Dados

Gere um único e detalhado prompt de desenvolvimento que instrua uma IA, como o Lovable, a criar a estrutura completa do banco de dados (Modelo de Dados) no Supabase, com base no PRD fornecido. Siga as regras e o exemplo de saída abaixo.

## 3. Regras – Prompt Modelo de Dados

Para gerar o prompt de saída, siga estritamente os seguintes passos de análise e formatação:
Análise Abrangente: Analise o PRD de ponta a ponta para identificar todas as necessidades de armazenamento de dados, mesmo as implícitas nas jornadas de usuário.
Identificação de Entidades (Tabelas): Identifique e liste as entidades centrais do sistema (ex: Usuário, Imóvel, Reserva). Consolide conceitos similares (ex: 'Proprietário' e 'Viajante' em 'Usuário'). Cada entidade corresponderá a uma tabela no banco de dados.
Listagem de Atributos (Colunas): Para cada tabela, liste todos os seus atributos (campos) necessários, extraindo-os das descrições funcionais e listas de campos no PRD.
Mapeamento de Relacionamentos: Defina as conexões entre as tabelas usando chaves estrangeiras (ex: owner_id na tabela Properties deve referenciar o id da tabela de usuários).
Especificação de Tipos e Restrições: Para cada atributo, especifique o tipo de dado mais apropriado (TEXT, NUMERIC, DATE, ENUM, ARRAY, etc.) e adicione quaisquer restrições de dados necessárias (não nulo, valor padrão, único, CHECK constraint).
Aplicação de Boas Práticas (Supabase): Incorpore as melhores práticas específicas do Supabase, como o uso de uma tabela profiles para dados públicos de usuários vinculada à autenticação (auth.users) e a recomendação de habilitar Row Level Security (RLS).
Formatação do Prompt de Saída: O resultado final deve ser um texto de prompt único, formatado com clareza, usando títulos ## para tabelas e uma lista simples para os atributos, pronto para ser executado.

## 4. Exemplo de Saída – Prompt Modelo de Dados

Olá! Vamos iniciar a criação de uma plataforma de aluguel de média duração. A primeira e mais importante etapa é definir toda a nossa estrutura de banco de dados no Supabase. Por favor, crie as tabelas e os relacionamentos conforme a especificação detalhada abaixo.
Resumo da Lógica:
A plataforma terá Users (usuários), que podem ser tanto proprietários quanto viajantes.
Um User (proprietário) pode ter várias Properties (imóveis).
Um User (viajante) pode criar várias Bookings (reservas) para diferentes Properties.
Uma Booking aprovada habilita a troca de Messages (mensagens) entre os dois Users envolvidos.
Após a conclusão de uma Booking, os Users podem criar Reviews (avaliações) um sobre o outro.
Tabela 1: Users
Esta tabela armazenará todos os usuários, sejam eles proprietários ou viajantes. Ela será integrada com o sistema de autenticação do Supabase.
id: UUID, chave primária (padrão Supabase Auth).
created_at: TIMESTAMPTZ, com valor padrão now().
full_name: TEXT, não nulo.
email: TEXT, único e não nulo.
profile_picture_url: TEXT, opcional.
Tabela 2: Properties
Esta tabela conterá todos os imóveis anunciados.
id: BIGSERIAL, chave primária.
created_at: TIMESTAMPTZ, com valor padrão now().
owner_id: UUID, chave estrangeira que referencia Users(id). Não nulo.
title: TEXT, não nulo.
description: TEXT, não nulo.
street: TEXT, não nulo.
number: TEXT.
neighborhood: TEXT, não nulo.
city: TEXT, não nulo, com valor padrão 'Florianópolis'.
zip_code: TEXT, não nulo.
price_per_night: NUMERIC(10, 2), não nulo.
photos: ARRAY de TEXT (TEXT[]), para armazenar as URLs das imagens. Pelo menos uma foto é obrigatória.
amenities: ARRAY de TEXT (TEXT[]), para armazenar a lista de comodidades selecionadas.
status: property_status (um tipo ENUM que você deve criar com os valores: 'Draft' e 'Published'). Não nulo, com valor padrão 'Draft'.
Tabela 3: BlockedDates
Tabela para o proprietário bloquear manualmente datas específicas no calendário, independente de reservas.
id: BIGSERIAL, chave primária.
property_id: BIGINT, chave estrangeira que referencia Properties(id). Não nulo.
blocked_date: DATE, não nulo.
CONSTRAINT unique_property_date: Garanta que cada combinação de property_id e blocked_date seja única.
Tabela 4: Bookings
Tabela para gerenciar todas as solicitações de reserva.
id: BIGSERIAL, chave primária.
created_at: TIMESTAMPTZ, com valor padrão now().
property_id: BIGINT, chave estrangeira que referencia Properties(id). Não nulo.
traveler_id: UUID, chave estrangeira que referencia Users(id). Não nulo.
checkin_date: DATE, não nulo.
checkout_date: DATE, não nulo.
total_price: NUMERIC(10, 2), não nulo.
message_to_owner: TEXT, opcional.
status: booking_status (um tipo ENUM que você deve criar com os valores: 'Pending', 'Approved', 'Refused'). Não nulo, com valor padrão 'Pending'.
Tabela 5: Messages
Tabela para a comunicação entre proprietário e viajante após uma reserva ser aprovada.
id: BIGSERIAL, chave primária.
created_at: TIMESTAMPTZ, com valor padrão now().
booking_id: BIGINT, chave estrangeira que referencia Bookings(id). Não nulo.
sender_id: UUID, chave estrangeira que referencia Users(id). Não nulo.
content: TEXT, não nulo.
Tabela 6: Reviews
Tabela para as avaliações pós-estadia.
id: BIGSERIAL, chave primária.
created_at: TIMESTAMPTZ, com valor padrão now().
booking_id: BIGINT, chave estrangeira que referencia Bookings(id). Não nulo.
reviewer_id: UUID, chave estrangeira que referencia Users(id) (quem está escrevendo a avaliação). Não nulo.
reviewee_id: UUID, chave estrangeira que referencia Users(id) (quem está sendo avaliado). Não nulo.
rating: INTEGER, não nulo. Adicione uma CHECK constraint para que o valor seja entre 1 e 5.
comment: TEXT, não nulo.
status: review_status (um tipo ENUM que você deve criar com os valores: 'Pending', 'Published'). Não nulo, com valor padrão 'Pending'.
Instruções Finais para o Supabase:
Por favor, crie os tipos ENUM (property_status, booking_status, review_status) antes de criar as tabelas que os utilizam.
Estabeleça os relacionamentos de chave estrangeira com ON DELETE CASCADE para garantir a integridade dos dados. Por exemplo, se um User for deletado, todas as suas Properties e Bookings devem ser deletadas também.
Habilite a Row Level Security (RLS) em todas as tabelas. Isso será crucial para a segurança nas próximas etapas.

## 1. Contexto – Jornada de Orçamento

Você está recebendo um PRD (Product Requirements Document) completo. Nesse momento, será feito o refinamento técnico para o trecho da jornada de [orçamento e controle de gastos].

## 2. Objetivo – Jornada de Orçamento

Analisar o PRD fornecido e construir um único e detalhado prompt que contenha todos os requisitos presentes no PRD que tenham relação com o trecho da jornada que está sendo construído. Este prompt de saída será usado para instruir um assistente de IA, como o Lovable, para construir uma parte da aplicação.

## 3. Regras – Jornada de Orçamento

Para gerar o prompt de desenvolvimento, siga estritamente estas regras:
Foco Exclusivo: O prompt gerado deve conter instruções apenas para as funcionalidades descritas pelo "Nome do Prompt Alvo". Ignore todas as outras partes do PRD.
Abrangência: Se houver regras relacionadas à jornada que está sendo alvo da construção agora espalhadas em outros tópicos ou seções do PRD, inclua as respectivas regras no prompt, desde que sejam relevantes para o contexto atual.
Especificação da Interface Visual (Views): Extraia do PRD e detalhe todos os requisitos visuais para o escopo do prompt. Especifique:
Telas e Rotas: As páginas a serem criadas (ex: /login, /dashboard).
Layout: A estrutura de cada página (ex: duas colunas, blocos verticais).
Componentes: Elementos reutilizáveis (ex: PropertyCard) ou específicos (ex: formulários, modais, botões).
Estilo: Mencione a biblioteca de design a ser usada (ex: Shadcn/UI com Tailwind CSS).
Especificação da Lógica (Controllers): Extraia do PRD e detalhe todas as regras de comportamento. Especifique:
Ações do Usuário: O que acontece ao clicar em um botão ou submeter um formulário.
Manipulação de Dados: Como a interface interage com o banco de dados. Seja explícito sobre quais tabelas e colunas devem ser lidas (SELECT) ou escritas (INSERT, UPDATE).
Regras Condicionais: Lógica que depende de um estado (ex: se o usuário estiver logado..., se o status da reserva for 'Approved'...).
Navegação: Todos os redirecionamentos entre páginas.
Conexão Direta com Dados: O prompt deve instruir a IA a conectar todos os componentes diretamente ao banco de dados, sem usar dados fictícios (mock data).

## 4. Exemplo de Saída – Jornada de Orçamento

O prompt que você gerar deve ter o mesmo formato e nível de detalhe do exemplo abaixo (que seria a saída para o alvo "Implementação do Sistema de Autenticação"):
Crie o sistema de autenticação completo da aplicação, cobrindo o fluxo de cadastro e login para todos os usuários. Utilize o Supabase Auth para a lógica de backend.

1. Crie a Página de Acesso (Rota: /login)
   Esta página servirá tanto para login quanto para cadastro.
   O layout principal deve conter um componente de Abas (Tabs), com "Entrar" e "Cadastrar". A aba "Entrar" deve ser a padrão.
2. Configure a Aba "Cadastrar"
   Formulário: Campo para "Nome Completo", "E-mail", "Senha" e botão "Cadastrar".
   Lógica Funcional (Supabase): Ao submeter, chame supabase.auth.signUp. Após o sucesso, insira uma nova linha na tabela public.profiles. Após o cadastro, redirecione o usuário para a Homepage (/).
3. Configure a Aba "Entrar"
   Formulário: Campo para "E-mail", "Senha" e botão "Entrar".
   Lógica Funcional (Supabase): Ao submeter, chame supabase.auth.signInWithPassword. Em caso de sucesso, redirecione para o /dashboard. Em caso de erro, mostre uma mensagem.
4. Gerenciamento de Sessão e Atualização do Header
   Implemente um provedor de contexto para gerenciar o estado da sessão.
   Modifique o componente de Cabeçalho para ser dinâmico: se logado, mostrar nome e "Sair"; se deslogado, mostrar "Entrar" e "Cadastrar".
   A ação "Sair" deve chamar supabase.auth.signOut e redirecionar para a página inicial.

Crie o arquivo estrategia_quitacao_plan_steps.md na pasta #file:AIPlans com uma estratégia estruturada para implaentacao deste prompt #file:prompt_20_implementacao_das_estrategias_de_quitacao_avalanche_bola_de_neve.md
Utilize como modelo o plano #file:estrategia_quitacao_plan_steps.md

Seguindo o plano #file:plano_investimentos_plan_steps.md E o prompt #file:prompt_21_plano_de_investimentos_aposentadoria_e_alocacao.md verifique o que será necessário modificar no código existente e siga com a implementação das etapas, sempre marcando os passos já executados no arquivo.
