# Feature Specification: Gestão de Transações

**Feature Branch**: `002-transaction-management`
**Created**: 2025-10-18
**Status**: Draft
**Input**: User description: "funcionalidade de transações Leia o PRD.md e vamos preparar a funcionalidade de transações para ser implementada. Nesse momento só vamos focar no cadastro e nas visualizações. A parte analitica vira em outro momento."

## Clarifications

### Session 2025-10-18

- Q: Transfer Type - Referências UX mostram três tipos (Expense, Income, Transfer). Como devemos modelar transferências entre contas? → A: Manter apenas Receita/Despesa e tratar transferências como duas transações separadas (uma despesa na conta origem + uma receita na conta destino)
- Q: Monthly Grouping in Transaction List - Como as transações devem ser agrupadas visualmente na listagem? → A: Agrupar por dia com cabeçalhos "DD DE MÊS DE YYYY • N", com navegação mensal no topo (seletor de mês) para visualizar transações de um mês específico por vez
- Q: Details Field in Transaction Form - Referências UX mostram seção "DETAILS" expansível. Quais campos opcionais devemos incluir? → A: Adiar campos adicionais opcionais para fase futura, manter apenas os 5 campos essenciais (valor, data, categoria, conta, descrição) para manter foco no MVP
- Q: Recurring Transfers - Transferências entre contas devem suportar recorrência? → A: Permitir transferências recorrentes - template gera automaticamente pares de transações vinculadas nos períodos configurados (mesma lógica de templates para transações normais)
- Q: Mark as Paid/Received for Recurring Transactions - PRD menciona "marcar como paga/recebida". Como isso funciona além da efetivação automática por data? → A: Adicionar ação manual "Marcar como Pago/Recebido" que permite marcar transação pendente como realizada antes da data chegar (casos reais: esquecimento de pagamento, salário atrasado, rendimento adiado)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cadastro de Transação Pontual (Priority: P1)

Um membro da família precisa registrar uma despesa única (como uma compra no mercado) ou uma receita única (como um salário recebido) para manter o controle financeiro atualizado.

**Why this priority**: Este é o caso de uso mais fundamental - sem a capacidade de registrar transações básicas, o sistema não tem utilidade. Forma a base para todas as outras funcionalidades.

**Independent Test**: Pode ser testado completamente criando uma transação, verificando que ela aparece na lista e que o saldo da conta é atualizado corretamente. Entrega valor imediato permitindo controle financeiro básico.

**Acceptance Scenarios**:

1. **Given** um usuário autenticado com pelo menos uma conta cadastrada, **When** ele registra uma despesa pontual com valor, data, categoria, conta e descrição, **Then** a transação é salva, o saldo da conta é reduzido, e a transação aparece na listagem
2. **Given** um usuário autenticado com pelo menos uma conta cadastrada, **When** ele registra uma receita pontual com valor, data, categoria, conta e descrição, **Then** a transação é salva, o saldo da conta é aumentado, e a transação aparece na listagem
3. **Given** um usuário tentando cadastrar uma transação, **When** ele não preenche um campo obrigatório (valor, data, categoria, conta ou descrição), **Then** o sistema exibe mensagem de erro indicando o campo faltante e não permite salvar
4. **Given** uma transação pontual já cadastrada, **When** o usuário edita qualquer campo da transação, **Then** as alterações são salvas, o saldo da conta é recalculado, e o sistema registra qual usuário fez a edição

---

### User Story 1.5 - Transferência entre Contas (Priority: P1)

Usuários precisam mover dinheiro entre suas próprias contas (por exemplo, transferir da conta corrente para investimentos, ou sacar de investimentos para conta corrente) sem que isso seja contabilizado como receita ou despesa.

**Why this priority**: Transferências entre contas são operações comuns e fundamentais para gestão de múltiplas contas. Sem isso, usuários precisariam criar manualmente duas transações separadas e garantir valores idênticos, gerando risco de erros.

**Independent Test**: Pode ser testado criando uma transferência e verificando que ambas as contas têm saldos atualizados corretamente (redução na origem, aumento no destino) sem afetar totais de receita/despesa. Entrega valor permitindo movimentação segura entre contas.

**Acceptance Scenarios**:

1. **Given** um usuário com pelo menos duas contas cadastradas, **When** ele cria uma transferência especificando conta origem, conta destino, valor, data e descrição, **Then** o sistema cria automaticamente duas transações vinculadas: uma despesa na origem e uma receita no destino, ambas com categoria "Transferência"
2. **Given** um usuário criando uma transferência, **When** ele seleciona a mesma conta como origem e destino, **Then** o sistema exibe erro de validação impedindo a operação
3. **Given** uma transferência cadastrada (par de transações vinculadas), **When** o usuário edita valor ou data de uma delas, **Then** o sistema atualiza automaticamente a transação vinculada para manter consistência
4. **Given** uma transferência cadastrada, **When** o usuário exclui uma das transações, **Then** o sistema exclui automaticamente a transação vinculada após confirmação
5. **Given** relatórios de receita/despesa, **When** o sistema calcula totais, **Then** transações com categoria "Transferência" são excluídas dos cálculos de receita e despesa

---

### User Story 2 - Visualização e Filtragem de Transações (Priority: P1)

Usuários precisam visualizar suas transações de forma organizada, com capacidade de filtrar por período, tipo, categoria e conta para encontrar informações específicas rapidamente.

**Why this priority**: Complementa P1 - depois de registrar transações, visualizá-las e filtrá-las é essencial para obter valor do sistema. Sem isso, as transações são registradas mas não consultáveis de forma útil.

**Independent Test**: Pode ser testado independentemente criando várias transações de tipos diferentes e verificando que os filtros retornam os resultados corretos. Entrega valor permitindo análise básica do histórico financeiro.

**Acceptance Scenarios**:

1. **Given** um usuário com transações cadastradas, **When** ele acessa a listagem de transações, **Then** vê um seletor de mês no topo mostrando o mês atual, transações agrupadas por dia com cabeçalhos (ex: "17 DE OUTUBRO DE 2025 • 3"), e totais consolidados (quantidade, receitas, despesas) do mês
2. **Given** um usuário na listagem de transações, **When** ele navega para mês anterior ou próximo usando as setas do seletor, **Then** a listagem atualiza mostrando apenas transações do mês selecionado com totais recalculados
3. **Given** transações cadastradas nos últimos 2 dias, **When** o usuário visualiza a listagem, **Then** os cabeçalhos dos dias mostram "Today" e "Yesterday" ao invés da data completa
4. **Given** um usuário visualizando transações agrupadas por dia, **When** há múltiplas transações no mesmo dia, **Then** todas aparecem sob o mesmo cabeçalho ordenadas por horário de criação (mais recentes primeiro)
5. **Given** um usuário na listagem de transações, **When** ele aplica filtro de período (hoje, semana, mês, ano ou customizado), **Then** apenas transações dentro do período selecionado são exibidas
6. **Given** um usuário na listagem de transações, **When** ele filtra por tipo (receita/despesa/todas), **Then** apenas transações do tipo selecionado são exibidas
7. **Given** um usuário na listagem de transações, **When** ele filtra por categoria específica, **Then** apenas transações da categoria selecionada são exibidas
8. **Given** um usuário na listagem de transações, **When** ele filtra por conta específica, **Then** apenas transações da conta selecionada são exibidas
9. **Given** um usuário na listagem de transações, **When** ele busca por texto na descrição, **Then** apenas transações cuja descrição contém o texto buscado são exibidas
10. **Given** um usuário com múltiplos filtros aplicados, **When** ele limpa os filtros, **Then** todas as transações do mês selecionado são exibidas novamente

---

### User Story 3 - Cadastro de Transação Recorrente (Template) (Priority: P2)

Usuários precisam configurar transações que se repetem regularmente (como aluguel, salário, assinaturas) sem precisar cadastrá-las manualmente todo mês.

**Why this priority**: Feature de conveniência importante que economiza tempo significativo, mas não é essencial para o uso básico. Usuários podem começar com transações pontuais.

**Independent Test**: Pode ser testado criando um template recorrente e verificando que transações futuras são geradas automaticamente nos meses seguintes. Entrega valor reduzindo trabalho manual repetitivo.

**Acceptance Scenarios**:

1. **Given** um usuário autenticado, **When** ele cria uma transação recorrente especificando frequência (mensal, bimestral, trimestral, semestral ou anual), data de início e dados da transação, **Then** o sistema cria o template e gera automaticamente transações futuras até 12 meses à frente
2. **Given** um template recorrente com data de término definida, **When** o sistema gera transações futuras, **Then** para de gerar transações após a data de término especificada
3. **Given** um template recorrente sem data de término, **When** o sistema gera transações futuras, **Then** continua gerando até atingir o limite de 12 meses à frente
4. **Given** transações geradas por um template, **When** a data da transação chega ou passa (efetivação automática), **Then** a transação se torna independente e permanece inalterada mesmo se o template for editado
5. **Given** uma transação recorrente com data futura (pendente), **When** o usuário executa ação "Marcar como Pago/Recebido", **Then** a transação é marcada como realizada manualmente, torna-se independente do template, e o saldo da conta é atualizado
6. **Given** uma transação recorrente marcada manualmente como realizada, **When** o usuário executa ação "Desmarcar" antes da data chegar, **Then** a transação volta ao status pendente e o saldo da conta é recalculado
7. **Given** uma transação recorrente marcada manualmente como realizada, **When** a data da transação chega, **Then** o sistema mantém o status de realizada sem duplicar a efetivação
8. **Given** um usuário na listagem de transações, **When** ele filtra por status (realizada/pendente), **Then** vê transações no status selecionado (pendente = data futura não marcada; realizada = data passada/atual OU marcada manualmente)

---

### User Story 4 - Edição de Template Recorrente (Priority: P2)

Usuários precisam atualizar informações de transações recorrentes (como mudança no valor do aluguel ou da assinatura) e ter essas mudanças refletidas apenas nas transações futuras.

**Why this priority**: Complementa P2 - sem capacidade de editar templates, qualquer mudança em despesas recorrentes requer deletar e recriar tudo. Importante mas depende de templates existirem primeiro.

**Independent Test**: Pode ser testado criando um template, editando-o, e verificando que apenas transações futuras não efetivadas são alteradas. Entrega valor permitindo manutenção fácil de recorrências.

**Acceptance Scenarios**:

1. **Given** um template recorrente existente com transações futuras não efetivadas, **When** o usuário edita o valor do template, **Then** apenas transações com data futura (ainda não efetivadas) têm o valor atualizado
2. **Given** um template recorrente existente com transações futuras não efetivadas, **When** o usuário edita a categoria do template, **Then** apenas transações com data futura (ainda não efetivadas) têm a categoria atualizada
3. **Given** um template recorrente existente com transações futuras não efetivadas, **When** o usuário edita a descrição do template, **Then** apenas transações com data futura (ainda não efetivadas) têm a descrição atualizada
4. **Given** um template recorrente com transações já efetivadas (data passada), **When** o usuário edita o template, **Then** transações efetivadas permanecem inalteradas
5. **Given** um usuário editando uma transação individual gerada por template, **When** a transação ainda não foi efetivada, **Then** ele pode editá-la normalmente e a edição desvincula essa transação do template (não será mais afetada por edições futuras do template)
6. **Given** um usuário tentando editar uma transação individual gerada por template, **When** a transação já foi efetivada, **Then** ele pode editá-la normalmente como qualquer transação independente

---

### User Story 5 - Exclusão de Transações (Priority: P3)

Usuários precisam corrigir erros removendo transações cadastradas por engano, seja pontuais ou recorrentes.

**Why this priority**: Feature de manutenção importante mas não crítica para MVP. Usuários podem conviver inicialmente com transações incorretas ou editá-las para valor zero.

**Independent Test**: Pode ser testado criando transações e deletando-as, verificando que são removidas e saldos recalculados. Entrega valor permitindo correção de erros de cadastro.

**Acceptance Scenarios**:

1. **Given** uma transação pontual cadastrada, **When** o usuário solicita exclusão e confirma a ação, **Then** a transação é removida, o saldo da conta é recalculado, e a transação não aparece mais na listagem
2. **Given** um template recorrente, **When** o usuário solicita exclusão do template e confirma, **Then** o template e todas as transações futuras não efetivadas são removidas, mas transações já efetivadas permanecem
3. **Given** uma transação individual gerada por template (ainda não efetivada), **When** o usuário exclui apenas essa transação específica, **Then** apenas ela é removida, o template permanece e continua gerando futuras transações
4. **Given** um usuário tentando excluir uma transação, **When** solicita exclusão, **Then** o sistema exibe confirmação clara antes de executar para prevenir exclusões acidentais

---

### Edge Cases

- **Transações com data futura**: Transações pontuais com data futura atualizam o saldo imediatamente para permitir projeção de fluxo de caixa (ver Assumptions #1)
- **Limite de geração de recorrências**: Templates ativos com menos de 12 meses de transações futuras serão regenerados automaticamente por job noturno (ver Assumptions #2)
- **Edição simultânea**: Modelo "last write wins" - última edição sobrescreve, com registro em auditoria (ver Assumptions #3)
- **Exclusão de conta com transações**: Contas não podem ser deletadas, apenas arquivadas. Transações da conta arquivada permanecem e continuam acessíveis no histórico
- **Templates sem categoria válida**: Templates com categorias arquivadas continuam funcionando mas exibem aviso na interface para atualização (ver Assumptions #7)
- **Transações de valor zero**: Sistema NÃO permite transações com valor zero - validação mínima de R$ 0,01 (ver Assumptions #8)
- **Limites de valor**: Valor máximo de R$ 999.999.999,99 por transação (ver Assumptions #9)
- **Precisão decimal**: Valores armazenados em centavos (integers) com até 2 casas decimais, usando money-rails com arredondamento ROUND_HALF_UP (ver Assumptions #5)
- **Fuso horário**: Timezone America/Sao_Paulo usado para determinar efetivação de transações recorrentes (ver Assumptions #6)

## Requirements *(mandatory)*

### Functional Requirements

**Cadastro de Transações Pontuais:**

- **FR-001**: Sistema MUST permitir cadastrar transação pontual com tipo (Receita ou Despesa)
- **FR-002**: Sistema MUST exigir valor, data, categoria, conta e descrição como campos obrigatórios para transações
- **FR-003**: Sistema MUST atualizar automaticamente o saldo da conta ao criar, editar ou excluir transação
- **FR-004**: Sistema MUST validar que valor da transação é maior que zero e possui no máximo 2 casas decimais
- **FR-005**: Sistema MUST validar que categoria e conta selecionadas existem e não estão arquivadas
- **FR-006**: Sistema MUST registrar qual usuário criou a transação para fins de auditoria
- **FR-007**: Sistema MUST registrar qual usuário editou a transação e quando, para fins de auditoria

**Transferências entre Contas:**

- **FR-007a**: Sistema MUST permitir criar transferência entre contas gerando automaticamente um par de transações vinculadas (despesa na conta origem + receita na conta destino)
- **FR-007b**: Sistema MUST usar categoria especial "Transferência" (criada automaticamente no seed) para transações de transferência, não contabilizando em relatórios de receita/despesa
- **FR-007c**: Sistema MUST vincular as duas transações de uma transferência para que edições/exclusões afetem ambas simultaneamente
- **FR-007d**: Sistema MUST validar que conta origem e conta destino são diferentes em transferências
- **FR-007e**: Sistema MUST garantir que valor, data e descrição sejam idênticos em ambas as transações do par de transferência
- **FR-007f**: Sistema MUST permitir criar transferências recorrentes que funcionam como templates gerando automaticamente pares de transações vinculadas nos períodos configurados (mesma lógica de templates para transações normais)

**Transações Recorrentes (Templates):**

- **FR-008**: Sistema MUST permitir criar template de transação recorrente com frequência (mensal, bimestral, trimestral, semestral, anual)
- **FR-009**: Sistema MUST exigir data de início para templates recorrentes
- **FR-010**: Sistema MUST permitir data de término opcional para templates recorrentes
- **FR-011**: Sistema MUST gerar automaticamente transações futuras até 12 meses à frente ao criar template
- **FR-012**: Sistema MUST parar de gerar transações após data de término se especificada no template
- **FR-013**: Sistema MUST marcar transação recorrente como "efetivada" quando sua data chega ou passa (efetivação automática)
- **FR-013a**: Sistema MUST permitir ação manual "Marcar como Pago/Recebido" em transações recorrentes pendentes (data futura) para marcar como realizada antes da data chegar
- **FR-013b**: Sistema MUST permitir ação manual "Desmarcar" em transações recorrentes marcadas manualmente para reverter para status pendente (apenas se data ainda não chegou)
- **FR-013c**: Sistema MUST distinguir visualmente transações efetivadas automaticamente (por data) de transações marcadas manualmente como realizadas
- **FR-013d**: Sistema MUST impedir edição de template para transações marcadas manualmente como realizadas (mesmo comportamento de efetivadas)
- **FR-014**: Sistema MUST manter transações efetivadas independentes do template (imunes a edições do template)
- **FR-015**: Sistema MUST atualizar apenas transações futuras não efetivadas E não marcadas manualmente quando template é editado
- **FR-016**: Sistema MUST permitir editar transação individual gerada por template, desvinculando-a do template
- **FR-017**: Sistema MUST permitir excluir template e automaticamente remover todas as transações futuras não efetivadas E não marcadas manualmente
- **FR-018**: Sistema MUST manter transações efetivadas e marcadas manualmente mesmo quando template é excluído

**Visualização e Filtragem:**

- **FR-019**: Sistema MUST exibir seletor de mês no topo da listagem de transações permitindo navegação entre meses (anterior/próximo)
- **FR-019a**: Sistema MUST mostrar transações do mês atualmente selecionado por padrão (mês corrente ao abrir pela primeira vez)
- **FR-019b**: Sistema MUST agrupar transações visualmente por dia com cabeçalhos no formato "DD DE MÊS DE YYYY • N" onde N é o número de transações do dia
- **FR-019c**: Sistema MUST usar labels contextuais "Today" e "Yesterday" nos cabeçalhos quando aplicável (transações dos últimos 2 dias)
- **FR-020**: Sistema MUST listar transações dentro de cada grupo de dia ordenadas por horário de criação (mais recentes primeiro)
- **FR-021**: Sistema MUST exibir indicadores visuais distinguindo receitas (verde) de despesas (vermelho)
- **FR-022**: Sistema MUST exibir totais consolidados no topo: quantidade total de transações, total de receitas (Income), total de despesas (Expenses) do mês selecionado
- **FR-023**: Sistema MUST permitir filtrar transações por período: hoje, semana, mês, ano, ou intervalo customizado
- **FR-024**: Sistema MUST permitir filtrar transações por tipo (receita/despesa/todas)
- **FR-025**: Sistema MUST permitir filtrar transações por categoria
- **FR-026**: Sistema MUST permitir filtrar transações por conta
- **FR-027**: Sistema MUST permitir filtrar transações recorrentes por status (realizada/pendente)
- **FR-028**: Sistema MUST permitir buscar transações por texto contido na descrição
- **FR-029**: Sistema MUST permitir combinar múltiplos filtros simultaneamente
- **FR-030**: Sistema MUST exibir para cada transação: tipo, valor, data, categoria, conta, descrição, e status (para recorrentes)

**Exclusão:**

- **FR-031**: Sistema MUST exibir confirmação antes de excluir qualquer transação
- **FR-032**: Sistema MUST permitir excluir transação pontual e recalcular saldo da conta
- **FR-033**: Sistema MUST permitir excluir template recorrente sem afetar transações já efetivadas
- **FR-034**: Sistema MUST permitir excluir transação individual gerada por template sem afetar o template
- **FR-035**: Sistema MUST excluir automaticamente ambas as transações vinculadas ao excluir uma transferência

**Cálculo de Saldo:**

- **FR-036**: Sistema MUST calcular saldo da conta como: saldo inicial + soma(receitas) - soma(despesas)
- **FR-037**: Sistema MUST excluir transações com categoria "Transferência" do cálculo de receitas/despesas para fins de relatórios
- **FR-038**: Sistema MUST excluir saldo inicial do cálculo de receitas/despesas para fins de relatórios (conforme PRD)
- **FR-039**: Sistema MUST recalcular saldo sempre que transação é criada, editada ou excluída na conta

### Key Entities

- **Transaction (Transação)**: Representa uma movimentação financeira (receita ou despesa). Atributos: tipo (receita/despesa), valor (em centavos), data, descrição, categoria, conta, usuário que criou, usuário que editou, timestamps. Para recorrentes: flag indicando se é template, frequência, data início, data término, status (pendente/realizada), flag indicando se foi marcada manualmente como realizada, referência ao template pai. Para transferências: referência à transação vinculada (par de transferência).

- **Category (Categoria)**: Agrupa transações por finalidade. Atributos: nome, ícone/emoji, tipo (despesa/receita), flag de arquivada. Relacionamento: uma transação pertence a uma categoria.

- **Account (Conta)**: Armazena dinheiro e registra transações. Atributos: nome, tipo (corrente/investimentos), saldo inicial, saldo calculado, flag de arquivada. Relacionamento: uma transação pertence a uma conta.

- **User (Usuário)**: Membro da família que interage com o sistema. Relacionamento: registra quem criou/editou cada transação para auditoria.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Usuários conseguem cadastrar uma transação pontual completa em menos de 30 segundos
- **SC-002**: Sistema atualiza saldo da conta em menos de 1 segundo após salvar transação
- **SC-003**: Filtros na listagem de transações retornam resultados em menos de 2 segundos para até 10.000 transações
- **SC-004**: Usuários conseguem configurar uma recorrência mensal e ver as próximas 12 transações geradas imediatamente (menos de 2 segundos)
- **SC-005**: 95% dos usuários conseguem cadastrar sua primeira transação sem consultar documentação ou ajuda
- **SC-006**: Edição de template recorrente atualiza todas as transações futuras não efetivadas em menos de 3 segundos
- **SC-007**: Sistema mantém integridade: 100% das transações efetivadas permanecem inalteradas quando template é editado
- **SC-008**: Usuários conseguem encontrar uma transação específica usando filtros em menos de 10 segundos
- **SC-009**: Interface visual permite distinguir receitas de despesas em menos de 1 segundo (reconhecimento por cor)
- **SC-010**: Zero perda de dados: todas as exclusões requerem confirmação e são registradas em auditoria

## Assumptions

1. **Saldo de transações futuras pontuais**: Assumimos que transações pontuais com data futura atualizam o saldo imediatamente (projeção), similar ao comportamento de recorrentes. Permite visualização de fluxo de caixa futuro.

2. **Regeneração de recorrências**: Assumimos que sistema terá processo automatizado (job noturno ou similar) para regenerar próximas transações quando templates ativos atingem menos de 12 meses de transações futuras.

3. **Edição simultânea**: Assumimos modelo "last write wins" - última edição salva sobrescreve anterior. Sistema registra em auditoria qual usuário fez a última alteração.

4. **Paginação**: Assumimos implementação de paginação ou scroll infinito para listagens com mais de 50 transações, garantindo performance.

5. **Valores monetários**: Assumimos armazenamento em centavos (integers) usando biblioteca money-rails conforme já configurado no projeto, com moeda BRL e arredondamento ROUND_HALF_UP.

6. **Localização**: Assumimos timezone America/Sao_Paulo para determinar quando transações recorrentes são efetivadas (quando data chega).

7. **Categorias arquivadas**: Assumimos que templates com categorias arquivadas continuam funcionando mas exibem aviso na interface, permitindo que usuário atualize a categoria.

8. **Transações de valor zero**: Assumimos que sistema NÃO permite transações de valor zero (validação mínima de R$ 0,01).

9. **Limite de valor**: Assumimos limite máximo de R$ 999.999.999,99 por transação (suficiente para casos de uso pessoal/familiar).

10. **Performance de filtros**: Assumimos índices de banco de dados em colunas frequentemente filtradas (data, tipo, categoria_id, conta_id, status) para garantir performance.
