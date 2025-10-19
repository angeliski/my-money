# Feature Specification: Gestão de Contas Financeiras

**Feature Branch**: `001-account-management`
**Created**: 2025-10-18
**Status**: Draft
**Input**: User description: "funcionalidade de contas Leia o PRD.md e vamos preparar a funcionalide de contas para ser implementada. A gestão de familias será automatica e invisivel para o usuário nesse momento. Ele não deve saber que esse conceito existe, apenas o backend vai ter ciência desse dado."

## Clarifications

### Session 2025-10-18

- Q: When should the family entity be created in the system lifecycle? → A: Family is created automatically when the first user registers (during user signup flow)
- Q: What should be the maximum allowed length for account names? → A: 50 characters
- Q: Should the system allow accounts to have negative balances? → A: Yes, accounts can have negative balances (reflects real overdraft scenarios)
- Q: What values should be allowed for initial balance when creating an account? → A: Any value allowed (positive, zero, or negative)
- Q: How should the system handle concurrent edits to the same account by different family members? → A: Last-write-wins (simpler edit overwrites earlier one, audit trail shows who changed what)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Criar primeira conta financeira (Priority: P1)

Usuário acessa o aplicativo pela primeira vez após o cadastro e precisa criar sua primeira conta financeira (corrente ou investimentos) para começar a registrar transações. O sistema automaticamente associa a conta à família do usuário sem que ele perceba.

**Why this priority**: É o ponto de entrada fundamental para uso do aplicativo. Sem ao menos uma conta, o usuário não pode registrar transações. Esta é a funcionalidade mínima viável que desbloqueia todo o resto do sistema.

**Independent Test**: Pode ser totalmente testado criando uma conta e verificando que ela aparece na listagem, tem saldo inicial correto e está pronta para receber transações. Entrega valor imediato ao permitir que o usuário comece a organizar suas finanças.

**Acceptance Scenarios**:

1. **Given** usuário está autenticado no aplicativo, **When** acessa a tela de contas pela primeira vez, **Then** vê uma tela vazia com opção de criar nova conta
2. **Given** usuário clica em "Nova Conta", **When** preenche nome "Nubank", tipo "Corrente" e saldo inicial "R$ 1.500,00", **Then** conta é criada com sucesso e aparece na listagem com ícone 🏦 azul
3. **Given** usuário cria conta tipo "Investimentos", **When** confirma a criação, **Then** conta é criada com ícone 📈 verde (#10B981)
4. **Given** usuário criou conta com saldo inicial de R$ 1.500,00, **When** visualiza a conta, **Then** saldo inicial não é contabilizado como receita nos relatórios

---

### User Story 2 - Visualizar lista de contas com saldos (Priority: P1)

Usuário quer ver todas as suas contas financeiras em um só lugar, com saldos atualizados e total de patrimônio consolidado, para ter visão rápida de sua situação financeira.

**Why this priority**: Visão consolidada das contas é essencial para tomada de decisões financeiras diárias. Usuários precisam saber "quanto tenho disponível" rapidamente. Funcionalidade independente que entrega valor mesmo sem outras features.

**Independent Test**: Pode ser testado criando múltiplas contas e verificando que todas aparecem na lista com saldos corretos, indicadores visuais apropriados e totalização geral funcionando. Usuário já consegue acompanhar seu patrimônio.

**Acceptance Scenarios**:

1. **Given** usuário possui múltiplas contas cadastradas, **When** acessa tela de contas, **Then** vê lista ordenada com nome, tipo (ícone + cor), e saldo atual de cada conta
2. **Given** usuário possui conta com saldo positivo e outra com negativo, **When** visualiza lista, **Then** vê indicador visual verde para saldo positivo e vermelho para saldo negativo
3. **Given** usuário possui 3 contas (2 correntes + 1 investimentos), **When** visualiza lista, **Then** vê totalização geral do patrimônio somando todos os saldos
4. **Given** usuário seleciona uma conta da lista, **When** clica nela, **Then** acessa tela de detalhes com histórico de transações daquela conta

---

### User Story 3 - Editar informações de conta existente (Priority: P2)

Usuário percebe que errou o nome ou saldo inicial de uma conta e precisa corrigir essas informações sem perder o histórico de transações já registradas.

**Why this priority**: Essencial para manutenção de dados, mas não bloqueia o uso inicial. Usuários podem começar a usar o app sem precisar editar contas imediatamente. Prioridade P2 porque complementa P1.

**Independent Test**: Pode ser testado criando uma conta, editando seus dados e verificando que alterações foram salvas e histórico foi preservado. Funcionalidade standalone que não depende de outras features.

**Acceptance Scenarios**:

1. **Given** usuário está na tela de detalhes de uma conta, **When** clica em "Editar", **Then** consegue alterar nome e saldo inicial, mantendo tipo de conta inalterado
2. **Given** usuário edita saldo inicial de R$ 1.000 para R$ 1.500, **When** salva alterações, **Then** saldo é recalculado mantendo todas as transações existentes
3. **Given** usuário tenta salvar conta com nome vazio, **When** confirma, **Then** recebe mensagem de erro indicando que nome é obrigatório
4. **Given** usuário edita conta e salva, **When** retorna à lista, **Then** vê informações atualizadas imediatamente

---

### User Story 4 - Arquivar conta não utilizada (Priority: P2)

Usuário fechou uma conta bancária na vida real e quer removê-la da visualização ativa, mas precisa manter o histórico para consultas futuras e integridade dos relatórios passados.

**Why this priority**: Importante para organização de longo prazo, mas não crítica para MVP inicial. Usuários podem conviver com contas inativas visíveis por algum tempo. Arquivamento preserva integridade histórica.

**Independent Test**: Pode ser testado criando conta, registrando transações, arquivando e verificando que ela some da lista ativa mas histórico permanece acessível. Funcionalidade independente de gerenciamento de dados.

**Acceptance Scenarios**:

1. **Given** usuário possui conta com transações históricas, **When** escolhe arquivar a conta, **Then** recebe confirmação alertando que conta será ocultada mas histórico será preservado
2. **Given** usuário confirma arquivamento, **When** retorna à lista de contas, **Then** conta arquivada não aparece mais na listagem principal
3. **Given** usuário possui conta arquivada, **When** acessa filtro "Mostrar arquivadas", **Then** consegue visualizar contas arquivadas em seção separada (apenas leitura)
4. **Given** usuário visualiza relatórios de períodos antigos, **When** conta estava ativa naquele período, **Then** transações da conta arquivada continuam aparecendo nos relatórios históricos

---

### User Story 5 - Criar múltiplas contas de tipos diferentes (Priority: P1)

Usuário possui conta corrente, poupança e investimentos na vida real e quer replicar essa estrutura no app para acompanhar cada uma separadamente e entender distribuição de patrimônio.

**Why this priority**: Reflete realidade financeira comum dos usuários. Maioria das pessoas tem mais de uma conta. Fundamental para oferecer utilidade real desde o MVP. Habilita uso completo do sistema.

**Independent Test**: Pode ser testado criando contas de diferentes tipos e verificando que cada uma mantém suas características (ícone, cor) e saldos independentes. Demonstra flexibilidade do sistema.

**Acceptance Scenarios**:

1. **Given** usuário já possui conta "Corrente", **When** cria nova conta "Investimentos", **Then** ambas aparecem na lista com ícones e cores distintas
2. **Given** usuário possui 2 contas correntes ("Nubank" e "Bradesco"), **When** visualiza lista, **Then** ambas aparecem com mesmo ícone 🏦 azul mas nomes diferentes
3. **Given** usuário possui conta corrente e conta investimentos, **When** visualiza totalização, **Then** saldo total soma ambas as contas corretamente
4. **Given** usuário cria 5 contas diferentes, **When** acessa lista, **Then** todas aparecem ordenadas por data de criação (mais recente primeiro)

---

### Edge Cases

- **O que acontece quando usuário tenta criar conta com nome duplicado?** Sistema deve permitir (pode ter duas contas com mesmo nome em bancos diferentes), mas idealmente mostrar aviso amigável.
- **O que acontece quando usuário tenta criar conta com nome muito longo?** Sistema deve rejeitar nomes com mais de 50 caracteres e exibir mensagem de validação clara.
- **Usuário pode criar conta com saldo inicial zero ou negativo?** Sim, sistema aceita qualquer valor para saldo inicial (positivo, zero ou negativo) para refletir situação real da conta no momento do cadastro.
- **Contas podem ter saldo negativo?** Sim, sistema permite saldos negativos para refletir cenários reais de overdraft ou descoberto. Indicador visual vermelho sinaliza a situação.
- **Como sistema calcula saldo quando há apenas transações futuras (recorrentes não efetivadas)?** Saldo atual considera apenas transações com data passada ou presente, ignorando futuras.
- **O que acontece se usuário tentar arquivar sua única conta ativa?** Sistema deve permitir, pois usuário pode querer começar do zero, mas mostrar confirmação clara.
- **Como fica totalização quando todas as contas estão arquivadas?** Totalização mostra R$ 0,00 e sugere criação de nova conta.
- **Usuário pode desarquivar conta?** Sim, através da visualização de contas arquivadas, pode reativar conta.
- **O que acontece com tipo de conta (Corrente/Investimentos) após criação?** Tipo é imutável após criação para manter integridade, pois cada tipo tem regras diferentes de movimentação.
- **Como sistema lida com múltiplos usuários da mesma família criando contas simultaneamente?** Sistema deve sincronizar em tempo real, mostrando novas contas imediatamente para todos os membros.
- **O que acontece quando dois usuários editam a mesma conta ao mesmo tempo?** Sistema usa estratégia last-write-wins: a última alteração salva sobrescreve a anterior. Audit trail registra quem fez cada mudança e quando.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Sistema DEVE criar automaticamente uma família durante o cadastro (signup) do primeiro usuário
- **FR-002**: Sistema DEVE permitir criação de conta financeira com campos obrigatórios: nome, tipo (Corrente ou Investimentos), e saldo inicial (aceitando valores positivos, zero ou negativos)
- **FR-003**: Sistema DEVE associar automaticamente cada conta criada à família do usuário autenticado, sem exibir essa informação na interface
- **FR-004**: Sistema DEVE atribuir automaticamente ícone 🏦 e cor azul (#2563EB) para contas tipo "Corrente"
- **FR-005**: Sistema DEVE atribuir automaticamente ícone 📈 e cor verde (#10B981) para contas tipo "Investimentos"
- **FR-006**: Sistema DEVE tornar tipo de conta imutável após criação (não pode ser alterado posteriormente)
- **FR-007**: Sistema DEVE calcular saldo atual da conta automaticamente baseado em: saldo inicial + receitas - despesas (permitindo saldos negativos)
- **FR-008**: Sistema DEVE excluir saldo inicial do cálculo de receitas/despesas nos relatórios (apenas ajusta saldo da conta)
- **FR-009**: Sistema DEVE exibir lista de contas mostrando: nome, ícone/cor do tipo, e saldo atual
- **FR-010**: Sistema DEVE exibir totalização geral de patrimônio somando saldos de todas as contas ativas (não arquivadas), incluindo contas com saldo negativo
- **FR-011**: Sistema DEVE mostrar indicador visual verde para saldos positivos e vermelho para saldos negativos
- **FR-012**: Sistema DEVE permitir edição de nome e saldo inicial de conta existente, preservando histórico de transações
- **FR-013**: Sistema DEVE recalcular saldo atual ao editar saldo inicial, mantendo todas as transações
- **FR-014**: Sistema DEVE validar que nome da conta não seja vazio e tenha no máximo 50 caracteres ao criar ou editar
- **FR-015**: Sistema DEVE permitir arquivamento de conta (soft delete) ao invés de exclusão permanente
- **FR-016**: Sistema DEVE remover contas arquivadas da listagem principal de contas ativas
- **FR-017**: Sistema DEVE manter histórico de transações de contas arquivadas acessível para relatórios históricos
- **FR-018**: Sistema DEVE permitir visualização de contas arquivadas em seção separada com modo somente leitura
- **FR-019**: Sistema DEVE permitir desarquivamento de conta, tornando-a ativa novamente
- **FR-020**: Sistema DEVE ordenar lista de contas por data de criação (mais recente primeiro)
- **FR-021**: Sistema DEVE permitir acesso rápido ao histórico de transações ao selecionar uma conta da lista
- **FR-022**: Sistema DEVE sincronizar criação/edição de contas em tempo real para todos os membros da mesma família
- **FR-023**: Sistema DEVE usar estratégia last-write-wins para edições simultâneas da mesma conta (última alteração salva sobrescreve versões anteriores)
- **FR-024**: Sistema DEVE registrar qual usuário criou cada conta para fins de auditoria (dado não visível na interface)
- **FR-025**: Sistema DEVE registrar qual usuário editou cada conta e quando, para fins de auditoria (dado não visível na interface)
- **FR-026**: Sistema DEVE exibir mensagem de confirmação clara antes de arquivar conta
- **FR-027**: Sistema DEVE mostrar tela vazia com call-to-action para criar primeira conta quando usuário não possui contas ativas

### Key Entities

- **Conta (Account)**: Representa uma conta financeira da família
  - **Atributos essenciais**: nome (texto, 1-50 caracteres), tipo (enum: Corrente/Investimentos), saldo inicial (monetário), ícone (emoji), cor (hex), status (ativa/arquivada), data de criação, data de arquivamento
  - **Relacionamentos**: pertence a uma Família, possui múltiplas Transações, criada por Usuário, editada por Usuário(s)
  - **Comportamentos**: saldo calculado automaticamente, arquivamento soft delete, tipo imutável após criação

- **Família (Family)**: Representa grupo de usuários que compartilham dados financeiros (invisível para usuário)
  - **Atributos essenciais**: identificador único, data de criação
  - **Relacionamentos**: possui múltiplos Usuários, possui múltiplas Contas, possui múltiplas Categorias, possui múltiplos Investimentos
  - **Comportamentos**: criada automaticamente durante o signup do primeiro usuário (antes de qualquer conta ser criada), agrupa todos os dados financeiros compartilhados, primeiro usuário é automaticamente associado como administrador da família

- **Tipo de Conta (Account Type)**: Enumeração dos tipos possíveis de conta
  - **Valores**: Corrente (🏦, #2563EB), Investimentos (📈, #10B981)
  - **Comportamentos**: cada tipo tem ícone e cor fixos, determina regras de movimentação (investimentos têm lógica especial)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Usuário consegue criar sua primeira conta financeira em menos de 30 segundos após acessar a funcionalidade
- **SC-002**: Sistema exibe lista de contas com atualização de saldos em tempo real (menos de 2 segundos após transação)
- **SC-003**: 100% das contas criadas são automaticamente associadas à família correta sem intervenção do usuário
- **SC-004**: Usuário visualiza totalização de patrimônio consolidada com precisão de 100% (soma exata de todas as contas ativas)
- **SC-005**: Sistema suporta criação de no mínimo 50 contas por família sem degradação de performance na listagem
- **SC-006**: Edição de conta reflete mudanças imediatamente para todos os membros da família (sincronização em menos de 3 segundos)
- **SC-007**: 100% das contas arquivadas mantêm histórico de transações preservado e acessível em relatórios
- **SC-008**: Indicadores visuais de saldo (positivo/negativo) são exibidos corretamente em 100% dos casos
- **SC-009**: Sistema previne 100% das tentativas de salvar conta com dados inválidos (nome vazio) antes de persistir
- **SC-010**: Usuário consegue localizar e acessar detalhes de qualquer conta em menos de 5 segundos na lista
