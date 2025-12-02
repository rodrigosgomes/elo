# 1. Contexto

Você está recebendo um PRD (Product Requirements Document) completo #prd-geral.md e um protipo da tela #03-design/prototype. Nesse momento, será feito o refinamento técnico para o trecho da jornada de Dashboard (The Vault) — tela inicial com checklist e status.

# 2. Objetivo

Analisar o PRD e o Prototipo fornecido e construir um único e detalhado prompt em markdown que contenha todos os requisitos presentes no PRD que tenham relação com o trecho da jornada que está sendo construído. Mantenhaa interface do usuário extremamente similar ao prototipo. Este prompt de saída será usado para instruir um assistente de IA, como o Codex no VSCode, para construir uma parte da aplicação.

# 3. Regras

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

# 4. Exemplo de Saída

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
