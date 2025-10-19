# Bugs Encontrados - Transaction Management

## ✅ Resolvido

### 1. JavaScript Controllers Não Carregam ✅
**Causa:** Controllers importavam `@hotwire/stimulus` (sem "d") ao invés de `@hotwired/stimulus`
**Solução:** Corrigido imports em todos os controllers:
- `modal_controller.js`: ✅
- `transaction_form_controller.js`: ✅
- `filter_controller.js`: ✅

### 2. Filtros Não Funcionavam ✅
**Causa 1:** Formulário não tinha `filter_target` para conectar com o Stimulus controller
**Solução:** Adicionado `data: { filter_target: "form" }` em `_filters.html.erb`

**Causa 2:** Query de busca usava `ILIKE` (PostgreSQL-only)
**Solução:** Mudado para `LOWER(description) LIKE LOWER(?)` que funciona em SQLite e PostgreSQL (transaction.rb:70)

### 3. Modal Navigation Issue ✅
**Causa:** Botão "Cancelar" com `data: { turbo_frame: "_top" }` causava navegação completa
**Solução:** Substituído por botão com `data-action="click->modal#close"` que apenas fecha o modal via JavaScript
**Arquivos:** `_form.html.erb` (transactions e transfers)

### 4. Totais Não Atualizavam em Tempo Real ✅
**Causa:** Turbo Stream responses não incluíam atualização dos totais
**Solução:**
- Adicionado `id="transactions_totals"` no wrapper dos totais (_totals.html.erb:1)
- Adicionado `turbo_stream.update("transactions_totals")` nas actions create, update e destroy
- Totais agora são recalculados e atualizados automaticamente

---

## 🟡 Médio

*(Nenhum bug médio pendente)*

---

## 🟢 Baixo

*(Nenhum bug de baixa prioridade encontrado)*

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
