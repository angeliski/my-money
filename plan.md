# PLANO DE REFATORAÇÃO DO FRONTEND - MY MONEY

**Status:** Em Progresso
**Início:** 2025-10-19
**Tema:** Escuro único
**Prioridade:** Transações → Home → Navegação → Refinamentos

---

## OBSERVAÇÕES IMPORTANTES

### Elementos a DESCONSIDERAR do protótipo:
- ✖ Nome "Mobills" (manter "My Money")
- ✖ Ícones "Gift" (presente) e "Rocket" no header da home
- ✖ Banner "Seja Premium!" (funcionalidade não implementada)
- ✖ Seção "Primeiros passos" com checklist de onboarding
- ✖ Funcionalidade de "Tags"
- ✖ Funcionalidade de "Lembretes"
- ✖ Funcionalidade de "Anexos"
- ✖ Funcionalidade de "Favoritar" transação
- ✖ Seção "Cartões de crédito" (ainda não implementada completamente)
- ✖ Planejamento e Relatórios (ainda não implementados)

---

## 1. ESTRUTURA GERAL E TEMA

### 1.1 Sistema de Cores - Tema Escuro Único
**Estado Atual:** Tema escuro padrão do Rails
**Estado Desejado:** Tema escuro consistente com paleta do protótipo

**Cores principais:**
- Primário roxo: `#7C3AED` (botões, destaques)
- Verde (receitas): `#10B981`
- Vermelho (despesas): `#EF4444`
- Azul (contas): `#3B82F6`
- Roxo (transferências): `#8B5CF6`
- Cinza (fundos): `#1E1E1E`, `#2D2D2D`, `#3D3D3D`

**Alterações:**
- [x] Consolidar variáveis CSS para tema escuro no Tailwind
- [x] Backgrounds: `#1E1E1E` (principal) / `#2D2D2D` (cards/elevação)
- [x] Texto: branco `#FFFFFF` / cinza claro `#E5E5E5` / cinza médio `#A3A3A3`

---

## FASE 1 - TRANSAÇÕES E FORMULÁRIOS ⭐ (PRIORIDADE MÁXIMA)

### 2. TELA DE TRANSAÇÕES

#### 2.1 Header da Tela de Transações
- [x] Background roxo (`#7C3AED`) para o header
- [x] Título "Transações" com dropdown (▼) para alternar contexto
- [x] Ícones à direita:
  - [x] Ícone de busca (lupa)
  - [x] Ícone de filtro (funil)
  - [x] Ícone de menu (3 pontos)
- [x] Navegador de mês logo abaixo:
  - [x] Setas < > para navegar entre meses
  - [x] Nome do mês centralizado (ex: "Outubro")

#### 2.2 Cards de Saldo (no topo da lista)
- [x] Card em cinza escuro (`#2D2D2D`)
- [x] Duas colunas:
  - [x] Coluna 1: "Saldo atual" + valor + ícone de cadeado
  - [x] Coluna 2: "Balanço mensal" + valor + ícone de carteira
- [x] Valores em verde (positivo) ou vermelho (negativo)

#### 2.3 Lista de Transações
- [x] Agrupar transações em 2 grupos:
  - [x] "Efetivadas" (transações já realizadas)
  - [x] "Pendentes" (transações futuras/não efetivadas)
- [x] Dentro de cada grupo, ordenar por data (mais recente primeiro)
- [x] Cada transação exibe:
  - [x] Ícone circular da categoria (com cor de fundo)
  - [x] Nome/descrição da transação
  - [x] Subcategorias separadas por "|" (Categoria | Conta)
  - [x] Data da transação (formato: "01 out., 2025")
  - [x] Valor à direita (verde para receitas, vermelho para despesas)
  - [x] Ícone de status à direita:
    - [x] Check verde = efetivada
    - [x] Ícone de alerta/relógio = pendente
    - [x] Ícone de loop = recorrente
- [ ] Transferências:
  - [ ] Mostrar ícone de setas bidirecionais (roxo/azul)
  - [ ] Texto: "Transferência entrada" (verde) ou "Transferência saída" (vermelho)
  - [ ] Mostrar origem e destino: "Conta A <= Conta B"

#### 2.4 Botão Flutuante de Adicionar (FAB)
- [x] Botão circular roxo grande com ícone "+"
- [x] Fixo no canto inferior direito (mobile)
- [x] Ao clicar, expandir menu radial com 4 opções:
  - [x] Receita (ícone seta para cima, verde)
  - [x] Despesa cartão (ícone cartão, ciano) - desabilitado
  - [x] Transferência (ícone setas bidirecionais, roxo)
  - [x] Despesa (ícone seta para baixo, vermelho)
- [x] Ao expandir, background escurece (overlay semi-transparente)
- [x] Clicar no X ou fora do menu fecha o menu
- [x] Animação suave de expansão/contração

### 3. FORMULÁRIOS DE TRANSAÇÃO

#### 3.1 Componente Base de Formulário
- [x] Criar componente `FormHeader` reutilizável
- [x] Criar componente `MoneyInput` com formatação BRL
- [x] Criar componente `ToggleSwitch` customizado
- [x] Criar botão de confirmação flutuante (check circle)

#### 3.2 Tela de Nova Receita
- [x] Background verde gradiente (`#10B981` to darker) na parte superior
- [x] Texto "Nova receita" e seta voltar em branco
- [x] Campo de valor grande e centralizado (BRL fixo)
- [x] Seção principal em cinza escuro (`#2D2D2D`) com bordas arredondadas
- [x] Toggle "Recebido" com switch verde
- [x] Campos do formulário:
  - [x] Data (ícone calendário, formato: "01 out., 2025")
  - [x] Descrição (ícone texto)
  - [x] Categoria (com ícone colorido, abre modal) - botão pronto, modal pendente
  - [x] Conta (com avatar, abre modal) - botão pronto, modal pendente
  - [x] Observação (ícone lápis, opcional)
  - [x] Toggle "Receita recorrente" (ícone loop)
- [x] Botão de confirmação flutuante (check verde)
- [x] Modal de recorrência (integrado no formulário):
  - [x] "Como sua transação se repete?"
  - [x] Quantidade (setas +/-, padrão 2)
  - [x] Período (dropdown: Mensal, Semanal, Diário, Anual)
  - [x] Integrado no formulário

#### 3.3 Tela de Nova Despesa
- [x] Background vermelho gradiente (`#EF4444` to darker)
- [x] Texto "Nova despesa"
- [x] Toggle "Pago" (ou "Não foi pago") com switch vermelho
- [x] Mesma estrutura de campos da receita
- [x] Toggle "Despesa recorrente"
- [x] Botão de confirmação vermelho (check)

#### 3.4 Tela de Nova Transferência
- [x] Background roxo gradiente (`#8B5CF6` to darker)
- [x] Texto "Nova transferência"
- [x] Campo de valor no topo
- [x] Campo "De conta" (com avatar) - botão pronto, modal pendente
- [x] Separador "Transferir para" com seta
- [x] Campo "Para conta" (com avatar) - botão pronto, modal pendente
- [x] Observação (opcional)
- [x] Toggle "Transferência recorrente"
- [x] Botão de confirmação roxo (check)

#### 3.5 Modal de Seleção de Categoria
- [ ] Header verde (receita) ou vermelho (despesa)
- [ ] Texto "Pesquisar categoria"
- [ ] Campo de busca com ícone de lupa
- [ ] Lista de categorias com:
  - [ ] Ícone circular colorido à esquerda
  - [ ] Nome da categoria
  - [ ] Radio button/check à direita
- [ ] Background: cinza escuro (`#2D2D2D`)
- [ ] Categorias de receita: Bonificação, Empréstimo, Investimento, Outros, Pix, Presente, Renda extra, Salário
- [ ] Categorias de despesa: Alimentação, Contas, Educação, Lazer, Moradia, Outros, Saúde, Transporte, Vestuário

#### 3.6 Modal de Seleção de Conta
- [ ] Similar ao modal de categoria
- [ ] Lista de contas com:
  - [ ] Avatar/ícone da conta
  - [ ] Nome da conta
  - [ ] Saldo atual (opcional, em cinza claro)
  - [ ] Radio button à direita

#### 3.7 Tela de Nova Conta
- [ ] Background azul gradiente (`#3B82F6` to darker)
- [ ] Texto "Nova Conta"
- [ ] Campo "Saldo atual da conta" no topo
- [ ] Campos:
  - [ ] Tipo da conta (com ícone, ex: Nubank)
  - [ ] Nome (com ícone de microfone - pode ficar desabilitado)
  - [ ] Tipo de conta (dropdown: "Conta corrente", "Investimentos")
  - [ ] Cor da conta (seletor: roxo, azul, verde, vermelho, ciano, amarelo)
  - [ ] Toggle "Incluir na soma da tela inicial" (default: ativado)
- [ ] Botão de confirmação azul (check)

### 4. DETALHES E EDIÇÃO DE TRANSAÇÃO

#### 4.1 Bottom Sheet de Detalhes
- [ ] Abrir ao clicar em uma transação
- [ ] Background: cinza escuro (`#2D2D2D`)
- [ ] Seção de ações no topo com botões circulares:
  - [ ] "Não foi recebido" / "Recebido" (vermelho/verde)
  - [ ] "Receita recorrente" (verde, ícone loop)
- [ ] Grid de informações (2 colunas):
  - [ ] Descrição + Valor
  - [ ] Data + Conta (com avatar)
  - [ ] Categoria + (espaço vazio, tags removidas)
  - [ ] Observação
- [ ] Botão "EDITAR RECEITA" (verde, outline)
- [ ] Botão "RECEBER" (verde, filled) - para pendentes
- [ ] Ícone de lixeira no topo direito

#### 4.2 Tela de Edição
- [ ] Mesmo layout da tela de criação
- [ ] Título "Editar" no header
- [ ] Ícone de lixeira no header
- [ ] Campos preenchidos com dados existentes
- [ ] Modal de exclusão para recorrentes:
  - [ ] "Apagar receita recorrente"
  - [ ] Opções: "Deletar somente esta", "Deletar todas pendentes", "Deletar todas (incluindo efetivadas)", "Cancelar"
- [ ] Botão "SALVAR E CONTINUAR" ou check flutuante

### 5. FILTROS E BUSCA

#### 5.1 Tela de Filtros
- [ ] Header roxo com "Filtrar" e seta voltar
- [ ] Seções de filtro:
  - [ ] Situação: Pills (Todos, Efetivadas, Pendentes)
  - [ ] Categorias: Botão "Todos" (abre modal de seleção múltipla)
  - [ ] Contas: Botão "Todos" (abre modal de seleção múltipla)
  - [ ] Filtrar período: Toggle switch
- [ ] Botão de confirmação roxo (check flutuante)
- [ ] Estado selecionado: pill roxo com texto branco
- [ ] Estado não selecionado: pill com borda cinza

---

## FASE 2 - HOME/DASHBOARD (PRIORIDADE MÉDIA)

### 6. TELA PRINCIPAL (HOME)

#### 6.1 Header da Home
- [ ] Dropdown de seleção de mês (formato: "Outubro ▼")
- [ ] Modal com grid de meses do ano
- [ ] Destacar mês atual (roxo)
- [ ] Navegação de ano com setas < 2025 >
- [ ] Avatar do usuário no canto superior esquerdo
- [ ] Usar bottom nav "Mais" para configurações

#### 6.2 Cards de Resumo Financeiro
- [ ] Criar seção de resumo abaixo do header
- [ ] Background da página: `#1E1E1E`
- [ ] Mobile: Cards empilhados verticalmente
- [ ] Desktop: Cards em linha horizontal
- [ ] Card 1: "Saldo em contas"
  - [ ] Card: `#2D2D2D`
  - [ ] Valor grande em branco
  - [ ] Ícone de banco/cofre (azul)
  - [ ] Botão de "olho" para mostrar/ocultar
- [ ] Card 2: "Receitas"
  - [ ] Valor em verde
  - [ ] Ícone de seta para cima (verde)
  - [ ] Link ">" para detalhes
- [ ] Card 3: "Despesas"
  - [ ] Valor em vermelho
  - [ ] Ícone de seta para baixo (vermelho)
  - [ ] Link ">" para detalhes

#### 6.3 Seção "Pendência e alertas"
- [ ] Criar card "Pendência e alertas"
- [ ] Card: `#2D2D2D` com borda sutil
- [ ] Badge circular com número de pendentes (ex: "+2")
- [ ] Ícone de seta para cima (verde)
- [ ] Texto: "Receitas pendentes"
- [ ] Valor em verde
- [ ] Clicável para transações filtradas

#### 6.4 Seção "Contas"
- [ ] Título "Contas"
- [ ] Cada conta exibe:
  - [ ] Ícone/avatar da conta (círculo colorido)
  - [ ] Nome da conta
  - [ ] Saldo atual (verde/vermelho)
  - [ ] Botão "+" para adicionar transação
- [ ] Linha "Total" no final
- [ ] Visual: cards em `#2D2D2D`
- [ ] Botão para adicionar nova conta

#### 6.5 Gráfico de Receitas por Categoria
- [ ] Seção "Receitas por categoria" (desktop)
- [ ] Gráfico donut com cores por categoria
- [ ] Valor total centralizado
- [ ] Legenda com categorias e percentuais
- [ ] Background: `#2D2D2D`
- [ ] Em mobile: oculto ou scroll horizontal

---

## FASE 3 - ESTRUTURA E NAVEGAÇÃO (PRIORIDADE MÉDIA)

### 7. COMPONENTES DE NAVEGAÇÃO

#### 7.1 Bottom Navigation (Mobile)
- [ ] Criar componente de Bottom Navigation fixo
- [ ] Items: "Principal" (Home), "Transações", Botão "+", "Planejamento" (desabilitado), "Mais"
- [ ] Botão central "+" abre menu de ações rápidas
- [ ] Ajustar layout para não ocultar conteúdo
- [ ] Apenas visível em mobile (< 768px)

#### 7.2 Sidebar (Desktop)
- [ ] Criar componente Sidebar para desktop (≥ 768px)
- [ ] Logo/Nome "My Money" no topo
- [ ] Botão "Novo" roxo em destaque
- [ ] Menu:
  - [ ] Dashboard
  - [ ] Contas
  - [ ] Transações
  - [ ] Cartões de crédito (desabilitado)
  - [ ] Planejamento (desabilitado)
  - [ ] Relatórios (desabilitado)
  - [ ] Mais opções
  - [ ] Configurações
  - [ ] Central de Ajuda (desabilitado)
- [ ] Sidebar fixa à esquerda
- [ ] Em mobile: drawer/offcanvas (menu hambúrguer)

#### 7.3 Layout Responsivo
- [ ] Mobile (< 768px): Bottom nav visível, sidebar como drawer
- [ ] Tablet (768px - 1024px): Sidebar visível (estreita), cards 2 colunas
- [ ] Desktop (> 1024px): Sidebar visível (larga), cards em linha, modais centralizados

---

## FASE 4 - REFINAMENTOS (PRIORIDADE BAIXA)

### 8. ANIMAÇÕES E INTERAÇÕES

#### 8.1 Transições
- [ ] Animação de slide para navegação entre telas
- [ ] Fade in/out para modais e overlays
- [ ] Animação de expansão para FAB menu
- [ ] Smooth scroll na lista de transações

#### 8.2 Feedback Visual
- [ ] Ripple effect nos botões (Material Design)
- [ ] Loading states para ações assíncronas
- [ ] Toast notifications para feedback (sucesso/erro)
- [ ] Skeleton screens durante carregamento

#### 8.3 Snackbar de Confirmação
- [ ] Ao efetivar transação: "Transação efetivada" com check
- [ ] Fundo roxo
- [ ] Aparecer na parte inferior

### 9. OTIMIZAÇÕES FINAIS

#### 9.1 Performance
- [ ] Lazy loading de componentes pesados
- [ ] Otimização de re-renders
- [ ] Debounce em campos de busca

#### 9.2 Acessibilidade
- [ ] Navegação por teclado
- [ ] Labels apropriados em formulários
- [ ] Contraste adequado (WCAG AA)
- [ ] ARIA labels onde necessário
- [ ] Focus states visíveis

#### 9.3 Polimento Visual
- [ ] Revisão de espaçamentos
- [ ] Consistência de bordas/raios
- [ ] Ajustes de tipografia
- [ ] Testes em diferentes dispositivos

---

## COMPONENTES REUTILIZÁVEIS

### Componentes a Criar
- [ ] `<BottomNav>` - Navegação inferior mobile
- [ ] `<Sidebar>` - Menu lateral desktop
- [ ] `<SummaryCard>` - Card de resumo financeiro
- [ ] `<TransactionItem>` - Item de transação na lista
- [ ] `<CategoryIcon>` - Ícone circular de categoria
- [ ] `<AccountAvatar>` - Avatar de conta
- [ ] `<FABMenu>` - Botão flutuante com menu expansível
- [ ] `<MonthSelector>` - Seletor de mês com modal
- [ ] `<FilterSheet>` - Bottom sheet de filtros
- [ ] `<DetailSheet>` - Bottom sheet de detalhes
- [ ] `<FormHeader>` - Header colorido dos formulários
- [ ] `<MoneyInput>` - Input de valor monetário (BRL fixo)
- [ ] `<ToggleSwitch>` - Switch customizado
- [ ] `<PillButton>` - Botão pill selecionável

---

## RESUMO EXECUTIVO

**Total de alterações:** ~95 itens
**Componentes novos:** 14
**Telas principais:** 10+
**Fases de implementação:** 4

**Tempo estimado:**
- Fase 1 (Transações + Formulários): 3-4 semanas ⭐
- Fase 2 (Home): 1-2 semanas
- Fase 3 (Navegação): 1 semana
- Fase 4 (Refinamentos): 1 semana
- **Total:** 6-8 semanas de trabalho focado

**Tecnologias:**
- CSS Framework: Tailwind CSS (tema escuro único)
- JavaScript: Stimulus para interações
- Ícones: Heroicons (SVG inline)
- Animações: Tailwind transitions + CSS animations
- Gráficos: Chartkick
- Moeda: BRL fixo

O plano mantém **100% da lógica backend intacta**, focando exclusivamente em melhorias visuais e de experiência do usuário.
