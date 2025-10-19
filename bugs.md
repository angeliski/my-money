# Bugs Encontrados - Transaction Management

## 🔴 Crítico

### 1. JavaScript Controllers Não Carregam
**Arquivo:** Console do navegador
**Erro:** `Failed to resolve module specifier "@hotwired/stimulus". Relative references must start with either "/", "./", or "../".`

**Impacto:**
- Filtros não funcionam (dependem do `filter_controller.js`)
- Modais podem ter problemas (dependem do `modal_controller.js`)
- Formulários de transação podem ter comportamento incorreto (`transaction_form_controller.js`)

**Controladores Afetados:**
- `controllers/modal_controller.js`
- `controllers/transaction_form_controller.js`
- `controllers/filter_controller.js`

**Causa Provável:**
- Importmap não está resolvendo corretamente `@hotwired/stimulus`
- Tentativa de correção com `bin/importmap pin @hotwired/stimulus` foi feita mas não resolveu

**User Stories Afetadas:**
- User Story 2: Filtros não funcionam via interface
- User Story 3: Opção de criar template/recorrente não aparece (campos hidden aguardam JavaScript)

---

## 🟡 Médio

### 2. Totais Não Atualizam em Tempo Real Após Criar Transação
**Arquivo:** `app/controllers/transactions_controller.rb` (create action)

**Comportamento Atual:**
- Após criar transação, a lista é atualizada mas os totais permanecem em 0
- Apenas após recarregar a página (F5) os totais aparecem corretos

**Comportamento Esperado:**
- Totais deveriam atualizar automaticamente via Turbo Stream após criar transação

**Impacto:**
- UX confusa - usuário não vê reflexo imediato nos totais
- Não impede funcionalidade, apenas requer refresh manual

---

## 🟢 Baixo

*(Nenhum bug de baixa prioridade encontrado ainda)*

---

## ✅ Validações Concluídas

### User Story 1: Cadastro de Transação Pontual
- ✅ Botão "Nova Transação" visível e acessível
- ✅ Formulário carrega corretamente
- ✅ Criar despesa funciona
- ✅ Criar receita funciona
- ✅ Transações aparecem na lista
- ✅ Totais calculados corretamente (após refresh)

### User Story 1.5: Transferência entre Contas
- ✅ Botão "Nova Transferência" visível e acessível
- ✅ Formulário carrega corretamente
- ✅ Cria duas transações vinculadas automaticamente
- ✅ Transferências não contam em receitas/despesas
- ✅ Ambas transações aparecem na lista com categoria "Transferência"

### User Story 5: Exclusão de Transações
- ✅ Botões de exclusão (🗑️) visíveis em cada transação
- ✅ Diálogo de confirmação aparece ao clicar
- ✅ Exclusão funciona corretamente
- ✅ Transação removida da lista
- ✅ Totais atualizados (após refresh)

### Edição de Transações (parte da User Story 4)
- ✅ Botões de edição (✏️) visíveis em cada transação
- ✅ Formulário de edição carrega com dados preenchidos
- ✅ Permite editar todos os campos
- ✅ Atualização funciona corretamente
- ✅ Transação atualizada aparece na lista

## ❌ Validações com Problemas

### User Story 2: Visualização e Filtragem
- ❌ **Filtros não funcionam** - dependem de JavaScript quebrado
- ✅ Navegação de meses funciona (botões anterior/próximo)
- ✅ Lista de transações aparece corretamente
- ✅ Totais são exibidos (receitas, despesas, total de transações)

### User Story 3: Cadastro de Transação Recorrente (Template)
- ❌ **Opção de template não aparece na interface** - campos estão hidden aguardando JavaScript
- ❌ Checkbox "Tornar recorrente" não visível
- ❌ Campos de frequência, data início/fim não acessíveis

### User Story 4: Edição de Template Recorrente
- ❌ **Não foi possível testar** - não há como criar templates pela interface
