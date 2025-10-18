# PRD - Aplicativo de Controle Financeiro Familiar

## 1. Visão Geral do Produto

### 1.1 Objetivo
Criar um aplicativo mobile de controle financeiro pessoal que permita famílias gerenciarem suas finanças de forma intuitiva, visual e organizada, com funcionalidades de gestão de transações, categorização, recorrências e acompanhamento de investimentos.

### 1.2 Público-Alvo
- Famílias que buscam organizar suas finanças pessoais
- Usuários de 25-55 anos com renda estável
- Pessoas que desejam ter visibilidade sobre gastos e investimentos
- Usuários com conhecimento básico a intermediário em finanças

### 1.3 Proposta de Valor
- **Simplicidade**: Interface intuitiva e fluxos descomplicados
- **Visibilidade**: Dashboards e relatórios visuais sobre a saúde financeira
- **Organização**: Categorização e recorrências automatizadas
- **Acompanhamento**: Evolução de investimentos simplificada

---

## 2. Funcionalidades Core

### 2.1 Gestão de Contas

#### 2.1.1 Cadastro de Contas
**Descrição**: Permite criar e gerenciar diferentes contas financeiras.

**Campos obrigatórios:**
- Nome da conta
- Tipo de conta (Corrente ou Investimentos)
- Saldo inicial

**Tipos de Conta com Ícones e Cores Fixos:**

| Tipo | Ícone | Cor |
|------|-------|-----|
| Corrente | 🏦 | Azul (#2563EB) |
| Investimentos | 📈 | Verde (#10B981) |

**Regras de negócio:**
- Cada conta deve ter um saldo calculado automaticamente baseado nas transações
- Contas podem ser arquivadas (não excluídas) para manter histórico
- Saldo inicial não entra no cálculo de receitas/despesas dos relatórios
- Ícone e cor são definidos automaticamente pelo tipo de conta

#### 2.1.2 Visualização de Contas
- Lista de contas com saldo atual
- Indicador visual de saldo positivo/negativo
- Acesso rápido às transações de cada conta
- Totalização geral de patrimônio

---

### 2.2 Gestão de Transações

#### 2.2.1 Cadastro de Transações
**Descrição**: Permite registrar receitas e despesas.

**Campos obrigatórios:**
- Tipo (Receita/Despesa)
- Valor
- Data
- Categoria
- Conta relacionada
- Descrição

**Tipos de transação:**
1. **Pontual**: Transação única
2. **Recorrente (Template)**: Serve como modelo para criação automática de transações futuras
   - Frequência: Mensal, Bimestral, Trimestral, Semestral, Anual
   - Data de início
   - Data de término (opcional - se vazio, recorrência indefinida)
   - Opção de editar: **apenas transações futuras (ainda não efetivadas)**

#### 2.2.2 Regras de Transações Recorrentes
- **Transações recorrentes são templates** que geram automaticamente transações futuras
- Sistema cria automaticamente as transações futuras (até 12 meses à frente)
- Uma vez que a transação é efetivada (data chegou), ela se torna independente e não pode mais ser editada pelo template
- Editar o template recorrente afeta **apenas as transações futuras** (não efetivadas)
- Notificação antes do vencimento de despesas recorrentes
- Possibilidade de marcar como paga/recebida
- Objetivo: facilitar o dia a dia e ter uma projeção simples da gestão financeira

#### 2.2.3 Listagem de Transações
**Funcionalidades:**
- Ordenação por data (padrão: mais recentes primeiro)
- Filtros:
  - Período (hoje, semana, mês, ano, customizado)
  - Tipo (receita/despesa/todas)
  - Categoria
  - Conta
  - Status (realizada/pendente para recorrentes)
- Busca por descrição
- Indicadores visuais claros de receita (verde) e despesa (vermelho)

---

### 2.3 Categorias

#### 2.3.1 Categorias Pré-definidas (Seed inicial da conta)

**Despesas:**
- 🏠 Moradia (aluguel, condomínio, IPTU)
- ⚡ Contas (água, luz, gás, internet)
- 🍽️ Alimentação (mercado, delivery, restaurantes)
- 🚗 Transporte (combustível, manutenção, transporte público)
- 🏥 Saúde (plano de saúde, farmácia, consultas)
- 🎓 Educação (escola, cursos, material)
- 👕 Vestuário
- 🎮 Lazer (entretenimento, viagens, hobbies)
- 📱 Assinaturas (streaming, apps)
- 💳 Taxas e Impostos
- 🎁 Outros

**Receitas:**
- 💼 Salário
- 💰 Freelance/Extras
- 📈 Rendimentos
- 🎁 Presentes/Bonificações
- 💵 Outros

**Observação:** Estas categorias são criadas automaticamente quando o usuário cria sua conta pela primeira vez (seed).

#### 2.3.2 Gestão de Categorias
- Criar categorias customizadas
- Editar nome e ícone de categorias
- Arquivar categorias (não excluir para manter histórico)
- Definir orçamento mensal por categoria (feature futura)

---

### 2.4 Conta de Investimentos

#### 2.4.1 Funcionalidades Específicas
**Descrição**: Acompanhamento simplificado de investimentos sem integração com corretoras.

**Tipos de movimentação:**
1. **Aporte**: Entrada de capital novo
2. **Rendimento**: Ganhos/juros do investimento
3. **Resgate**: Retirada de valores

**Informações exibidas:**
- Saldo total atual
- Total aportado (soma de aportes - resgates)
- Total de rendimentos
- Rentabilidade (%) = (Rendimentos / Total Aportado) × 100
- Gráfico de evolução temporal

**Regras:**
- Aportes e resgates devem ter origem/destino em outra conta (transferência)
- Rendimentos não afetam outras contas (são ganhos)
- Histórico completo de movimentações

#### 2.4.2 Dashboard de Investimentos
- Card visual com informações principais
- Gráfico de evolução do saldo
- Separação visual: Aportado vs Rendimentos
- Indicador de performance (positivo/negativo)

---

### 2.5 Relatórios e Dashboards

#### 2.5.1 Dashboard Principal (Home)
**Elementos:**
- Saldo total consolidado
- Resumo do mês atual:
  - Total de receitas
  - Total de despesas
  - Balanço (receitas - despesas)
- Principais categorias de despesa (top 5)
- Próximas contas a vencer
- Acesso rápido para nova transação

#### 2.5.2 Relatórios Detalhados
**Tela de Relatórios com:**

1. **Visão Geral**
   - Período selecionável
   - Gráfico de receitas vs despesas (barras/linhas)
   - Evolução patrimonial

2. **Análise por Categoria**
   - Gráfico pizza/donut mostrando distribuição de despesas
   - Lista ordenada por valor
   - % do total por categoria

3. **Análise Temporal**
   - Comparação mês a mês
   - Tendências (gastos aumentando/diminuindo)
   - Média de gastos por categoria

4. **Fluxo de Caixa**
   - Projeção baseada em recorrências
   - Visualização de meses futuros
   - Alertas de possível saldo negativo

5. **Investimentos**
   - Evolução do patrimônio em investimentos
   - Rentabilidade período
   - Comparação aportes vs rendimentos

**Filtros disponíveis:**
- Período (último mês, 3 meses, 6 meses, ano, customizado)
- Contas específicas
- Categorias específicas

---

## 3. Requisitos Não-Funcionais

### 3.1 Design e UX

#### 3.1.1 Princípios de Design
- **Mobile First**: Interface otimizada para smartphones
- **Visual Moderno**: Design contemporâneo, clean, com uso de cards e espaçamento generoso
- **Microinterações**: Feedbacks visuais em ações (botões, swipes, confirmações)
- **Cores intuitivas**: Verde para receitas, vermelho para despesas, azul para neutro
- **Modo escuro**: Opção de tema claro e escuro

#### 3.1.2 Componentes Visuais
- Gráficos interativos e animados
- Cards com shadows suaves
- Bottom navigation para navegação principal
- Floating Action Button (FAB) para adicionar transações
- Pull-to-refresh nas listagens
- Skeleton screens durante carregamento

#### 3.1.3 Fluxos Intuitivos
- Onboarding simplificado (3-4 telas máximo)
- Cadastro de transação em no máximo 2 telas
- Acesso rápido às ações principais
- Confirmações visuais de ações importantes
- Gestos intuitivos (swipe para deletar, long press para editar)

### 3.2 Performance
- Carregamento inicial < 3 segundos
- Transições e animações a 60fps
- Otimização de imagens e assets
- Paginação/lazy loading em listas longas

### 3.3 Segurança
- Opção de ocultar valores sensíveis


## 8. Critérios de Aceite do MVP

- ✅ Usuário consegue criar conta e fazer login
- ✅ Usuário consegue cadastrar múltiplas contas financeiras (Corrente e Investimentos)
- ✅ Sistema cria automaticamente categorias pré-definidas no primeiro acesso
- ✅ Usuário consegue adicionar transações pontuais e recorrentes
- ✅ Transações recorrentes funcionam como templates que geram transações futuras
- ✅ Edição de templates recorrentes afeta apenas transações futuras não efetivadas
- ✅ Usuário consegue categorizar transações
- ✅ Usuário visualiza dashboard com resumo financeiro
- ✅ Usuário acessa relatórios básicos com gráficos
- ✅ Usuário consegue filtrar e buscar transações
- ✅ App funciona offline completamente
- ✅ App possui autenticação por PIN ou biometria
- ✅ Interface responsiva e fluida em diferentes dispositivos
