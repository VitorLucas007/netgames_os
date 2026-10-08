# Documentação de Requisitos - Sistema de Ordem de Serviço (OS)

## 1. Visão Geral do Projeto
Sistema de gerenciamento de Ordens de Serviço focado em assistência técnica de TI e Videogames. O objetivo é fornecer uma ferramenta ágil para um profissional autônomo (técnico) gerenciar seus serviços e permitir que os clientes acompanhem o progresso do conserto de forma transparente e digital.

**Stack Tecnológico Escolhido:**
*   **Frontend/Mobile:** Dart / Flutter (Cross-platform para web e mobile).
*   **Backend / Banco de Dados / Autenticação:** Backend-as-a-Service (Supabase ou Firebase).

---

## 2. Atores (Perfis de Usuário)
*   **Técnico/Admin (Profissional Autônomo):** Possui acesso total ao sistema. Responsável por cadastrar clientes, equipamentos, gerenciar status, gerar orçamentos, tirar fotos e finalizar ordens de serviço.
*   **Cliente:** Acesso restrito e sem necessidade de criação de conta (login). Acessa exclusivamente a sua própria Ordem de Serviço através de um link de rastreio único ou inserindo CPF + Número da OS em um portal web.

---

## 3. Requisitos Funcionais (RF)

### 3.1. Gestão de Clientes e Equipamentos
*   **RF01 - Cadastro Simplificado de Cliente:** O sistema deve registrar Nome, WhatsApp, CPF e E-mail do cliente.
*   **RF02 - Cadastro Detalhado de Equipamento:** O sistema deve registrar os dados do aparelho deixado:
    *   Tipo (Notebook, Desktop, Console, Controle, etc.).
    *   Marca e Modelo.
    *   Número de Série (Obrigatório para segurança).
    *   Acessórios deixados (ex: cabos, fontes, jogos).
    *   Condição física / Avarias pré-existentes.
    *   Senha de acesso ao sistema (PIN/Senha do Windows/Mac).
*   **RF03 - Histórico do Equipamento:** O sistema deve identificar se um equipamento (pelo Número de Série) já esteve na assistência anteriormente e listar os serviços prestados.

### 3.2. Ciclo de Vida da Ordem de Serviço
*   **RF04 - Abertura Rápida de OS:** Interface unificada para vincular cliente, equipamento e a "Reclamação/Defeito relatado".
*   **RF05 - Gestão de Mídia (Fotos):** O sistema deve permitir o upload de fotos do equipamento no recebimento (estado inicial) e na finalização do conserto.
*   **RF06 - Gestão de Orçamento e Laudo:** O técnico deve poder registrar o laudo técnico, peças necessárias e valor da mão de obra.
*   **RF07 - Aprovação de Orçamento:** O sistema deve registrar a decisão do cliente (Orçamento Aprovado ou Recusado).

### 3.3. Portal do Cliente (Acompanhamento)
*   **RF08 - Página de Rastreio Web:** O cliente deve visualizar em tempo real:
    *   Dados básicos do seu aparelho.
    *   Status atual em formato de linha do tempo.
    *   Valor do orçamento (quando disponível).
*   **RF09 - Aprovação Online (Opcional):** Botão na página de rastreio para o cliente aprovar ou recusar o orçamento digitalmente.

### 3.4. Saída, Relatórios e Comunicação
*   **RF10 - Geração de Documentos (PDF):** Geração e exportação de Termo de Recebimento (Entrada) e Recibo/Termo de Garantia (Saída).
*   **RF11 - Integração de Comunicação:** Botão para abrir o WhatsApp automaticamente com mensagens pré-configuradas contendo o link da OS e atualizações de status.

---

## 4. Fluxo de Status da Ordem de Serviço
A OS deve transitar, obrigatoriamente, pelos seguintes status lógicos para exibição ao cliente:
1.  **Recebido na Assistência:** Aparelho deu entrada.
2.  **Em Análise:** Diagnóstico em andamento.
3.  **Aguardando Aprovação:** Orçamento gerado e enviado ao cliente.
4.  **Em Manutenção:** Orçamento aprovado, conserto em execução.
5.  **Aguardando Peça:** Pausa na manutenção à espera de componentes.
6.  **Pronto para Retirada:** Conserto concluído e aparelho testado.
7.  **Entregue / Finalizado:** Cliente retirou o equipamento e o pagamento foi realizado.
8.  **Devolvido sem Conserto:** Orçamento recusado ou aparelho sem reparo possível.

---

## 5. Requisitos Não Funcionais (RNF)
*   **RNF01 - Mobile-First (Técnico):** A interface do técnico (em Flutter) deve ser perfeitamente utilizável em smartphones, facilitando o uso na bancada e o uso da câmera do dispositivo para fotos.
*   **RNF02 - Responsividade Web (Cliente):** O portal de rastreio deve se adaptar a qualquer tamanho de tela (mobile e desktop).
*   **RNF03 - Segurança e Privacidade (LGPD):** Senhas de dispositivos não devem ficar expostas na tela de rastreio pública. A página de rastreio não deve ser indexada por motores de busca (Google, Bing).
*   **RNF04 - Disponibilidade em Nuvem:** Os dados e as imagens devem ser armazenados de forma segura na nuvem (Supabase Storage/Firebase Storage) garantindo disponibilidade 24/7 para o acesso dos clientes.
