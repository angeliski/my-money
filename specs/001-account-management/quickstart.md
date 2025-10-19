# Quickstart Guide: Account Management Implementation

**Feature**: 001-account-management
**Branch**: `001-account-management`
**Date**: 2025-10-18

## Overview

This quickstart guide provides step-by-step instructions for implementing the Account Management feature. Follow the sequence exactly to ensure proper database schema, model associations, and feature functionality.

**Estimated Time**: 4-6 hours (including testing)

---

## Prerequisites

Ensure you have:
- [x] Ruby 3.3+ installed
- [x] Rails 7.2.2+ installed
- [x] Git repository initialized
- [x] Branch `001-account-management` checked out
- [x] Development database accessible
- [x] RSpec test suite configured

**Verify Setup**:
```bash
ruby -v          # Should show 3.3+
rails -v         # Should show 7.2.2+
bundle exec rspec --version  # Should run without error
```

---

## Implementation Phases

### Phase 1: Database Schema (30 minutes)

#### Step 1.1: Generate Family Model

```bash
bundle exec rails generate model Family
```

**Edit Migration** (`db/migrate/XXXXXX_create_families.rb`):
```ruby
class CreateFamilies < ActiveRecord::Migration[7.2]
  def change
    create_table :families do |t|
      t.timestamps
    end

    add_index :families, :created_at
  end
end
```

#### Step 1.2: Add Family Reference to Users

```bash
bundle exec rails generate migration AddFamilyToUsers family:references
```

**Edit Migration** (`db/migrate/XXXXXX_add_family_to_users.rb`):
```ruby
class AddFamilyToUsers < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :family, null: false, foreign_key: true, index: true

    # For existing users, create individual families
    reversible do |dir|
      dir.up do
        User.reset_column_information
        User.find_each do |user|
          user.update!(family: Family.create!)
        end
      end
    end
  end
end
```

#### Step 1.3: Generate Account Model

```bash
bundle exec rails generate model Account \
  name:string \
  account_type:integer \
  initial_balance_cents:integer \
  icon:string \
  color:string \
  archived_at:datetime \
  family:references
```

**Edit Migration** (`db/migrate/XXXXXX_create_accounts.rb`):
```ruby
class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.integer :account_type, null: false, default: 0
      t.integer :initial_balance_cents, null: false, default: 0
      t.string :icon, null: false
      t.string :color, null: false
      t.datetime :archived_at
      t.references :family, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :accounts, :archived_at
    add_index :accounts, [:family_id, :archived_at]
    add_index :accounts, :created_at
  end
end
```

#### Step 1.4: Run Migrations

```bash
bundle exec rails db:migrate
bundle exec rails db:test:prepare
```

**Verify**:
```bash
bundle exec rails dbconsole
> .schema families
> .schema accounts
> .schema users  # Should have family_id column
> .exit
```

---

### Phase 2: Models & Business Logic (45 minutes)

#### Step 2.1: Implement Family Model

**Edit** `app/models/family.rb`:
```ruby
class Family < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :accounts, dependent: :restrict_with_error
end
```

#### Step 2.2: Extend User Model

**Edit** `app/models/user.rb` (add to existing model):
```ruby
class User < ApplicationRecord
  # Existing Devise configuration...

  belongs_to :family
  has_many :accounts, through: :family

  before_validation :create_family_if_needed, on: :create

  private

  def create_family_if_needed
    self.family ||= Family.create!
  end
end
```

#### Step 2.3: Implement Account Model

**Edit** `app/models/account.rb`:
```ruby
class Account < ApplicationRecord
  # Associations
  belongs_to :family

  # Enums
  enum account_type: { checking: 0, investment: 1 }

  # Validations
  validates :name, presence: true, length: { maximum: 50 }
  validates :account_type, presence: true
  validates :initial_balance_cents, presence: true, numericality: { only_integer: true }
  validates :icon, presence: true
  validates :color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be valid hex color" }
  validates :family_id, presence: true

  # Money-rails integration
  monetize :initial_balance_cents, with_model_currency: :currency

  # Scopes
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :ordered_by_creation, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :set_icon_and_color, on: :create

  # Instance methods
  def current_balance
    # For now, return initial balance (no transactions yet)
    Money.new(initial_balance_cents, 'BRL')
  end

  def positive_balance?
    current_balance.positive?
  end

  def archive!
    update(archived_at: Time.current)
  end

  def unarchive!
    update(archived_at: nil)
  end

  def archived?
    archived_at.present?
  end

  def type_with_icon
    "#{icon} #{account_type.humanize}"
  end

  def currency
    'BRL'
  end

  private

  def set_icon_and_color
    case account_type
    when 'checking'
      self.icon ||= '🏦'
      self.color ||= '#2563EB'
    when 'investment'
      self.icon ||= '📈'
      self.color ||= '#10B981'
    end
  end
end
```

#### Step 2.4: Run Model Specs

Create basic model specs to verify setup:

**Create** `spec/models/family_spec.rb`:
```ruby
require 'rails_helper'

RSpec.describe Family, type: :model do
  describe 'associations' do
    it { should have_many(:users).dependent(:restrict_with_error) }
    it { should have_many(:accounts).dependent(:restrict_with_error) }
  end
end
```

**Create** `spec/models/account_spec.rb`:
```ruby
require 'rails_helper'

RSpec.describe Account, type: :model do
  describe 'associations' do
    it { should belong_to(:family) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(50) }
    it { should validate_presence_of(:account_type) }
    it { should validate_presence_of(:initial_balance_cents) }
  end

  describe 'enums' do
    it { should define_enum_for(:account_type).with_values(checking: 0, investment: 1) }
  end

  describe 'scopes' do
    let(:family) { create(:family) }
    let!(:active_account) { create(:account, family: family, archived_at: nil) }
    let!(:archived_account) { create(:account, family: family, archived_at: 1.day.ago) }

    it 'returns only active accounts' do
      expect(Account.active).to include(active_account)
      expect(Account.active).not_to include(archived_account)
    end

    it 'returns only archived accounts' do
      expect(Account.archived).to include(archived_account)
      expect(Account.archived).not_to include(active_account)
    end
  end

  describe '#archive!' do
    let(:account) { create(:account) }

    it 'sets archived_at timestamp' do
      expect { account.archive! }.to change { account.archived_at }.from(nil)
    end
  end

  describe '#current_balance' do
    let(:account) { create(:account, initial_balance_cents: 150_000) }

    it 'returns Money object' do
      expect(account.current_balance).to be_a(Money)
    end

    it 'returns initial balance in BRL' do
      expect(account.current_balance.cents).to eq(150_000)
      expect(account.current_balance.currency.iso_code).to eq('BRL')
    end
  end
end
```

**Create Factories** `spec/factories/families.rb`:
```ruby
FactoryBot.define do
  factory :family do
    # No attributes needed, just timestamps
  end
end
```

**Create Factories** `spec/factories/accounts.rb`:
```ruby
FactoryBot.define do
  factory :account do
    name { Faker::Bank.name }
    account_type { :checking }
    initial_balance_cents { rand(-100_000..500_000) }
    icon { '🏦' }
    color { '#2563EB' }
    association :family

    trait :checking do
      account_type { :checking }
      icon { '🏦' }
      color { '#2563EB' }
    end

    trait :investment do
      account_type { :investment }
      icon { '📈' }
      color { '#10B981' }
    end

    trait :archived do
      archived_at { 1.month.ago }
    end

    trait :negative_balance do
      initial_balance_cents { -50_000 }
    end
  end
end
```

**Run Tests**:
```bash
bundle exec rspec spec/models/
```

---

### Phase 3: Controllers & Routes (1 hour)

#### Step 3.1: Generate Controller

```bash
bundle exec rails generate controller Accounts index new create show edit update
```

#### Step 3.2: Configure Routes

**Edit** `config/routes.rb`:
```ruby
Rails.application.routes.draw do
  # Existing routes...

  resources :accounts, except: [:destroy] do
    member do
      delete :archive
      patch :unarchive
    end
  end
end
```

**Verify Routes**:
```bash
bundle exec rails routes | grep accounts
```

#### Step 3.3: Implement AccountsController

**Edit** `app/controllers/accounts_controller.rb`:
```ruby
class AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: [:show, :edit, :update, :archive, :unarchive]

  def index
    @accounts = current_user.family.accounts.active.ordered_by_creation
    @archived_accounts = current_user.family.accounts.archived.ordered_by_creation if params[:show_archived]
  end

  def show
  end

  def new
    @account = current_user.family.accounts.build
  end

  def create
    @account = current_user.family.accounts.build(account_params)

    respond_to do |format|
      if @account.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("accounts-list", partial: "accounts/account", locals: { account: @account }),
            turbo_stream.replace("accounts-total", partial: "accounts/total")
          ]
        end
        format.html { redirect_to accounts_path, notice: t('.success') }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("account-form", partial: "accounts/form", locals: { account: @account })
        end
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @account.update(account_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(dom_id(@account), partial: "accounts/account", locals: { account: @account }),
            turbo_stream.replace("accounts-total", partial: "accounts/total")
          ]
        end
        format.html { redirect_to account_path(@account), notice: t('.success') }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("account-form", partial: "accounts/form", locals: { account: @account })
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def archive
    @account.archive!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(dom_id(@account)),
          turbo_stream.replace("accounts-total", partial: "accounts/total")
        ]
      end
      format.html { redirect_to accounts_path, notice: t('.success') }
    end
  end

  def unarchive
    @account.unarchive!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.prepend("accounts-list", partial: "accounts/account", locals: { account: @account }),
          turbo_stream.replace("accounts-total", partial: "accounts/total")
        ]
      end
      format.html { redirect_to accounts_path, notice: t('.success') }
    end
  end

  private

  def set_account
    @account = current_user.family.accounts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to accounts_path, alert: t('accounts.not_found')
  end

  def account_params
    params.require(:account).permit(:name, :account_type, :initial_balance)
  end
end
```

#### Step 3.4: Create Helper Method

**Edit** `app/helpers/accounts_helper.rb`:
```ruby
module AccountsHelper
  def total_net_worth(family)
    total_cents = family.accounts.active.sum { |account| account.current_balance.cents }
    number_to_currency(Money.new(total_cents, 'BRL'), locale: :'pt-BR')
  end

  def format_balance(account)
    number_to_currency(account.current_balance, locale: :'pt-BR')
  end

  def balance_class(account)
    account.positive_balance? ? 'text-green-600' : 'text-red-600'
  end
end
```

---

### Phase 4: Views & Frontend (1.5 hours)

#### Step 4.1: Create I18n Translations

**Create** `config/locales/pt-BR/accounts.yml`:
```yaml
pt-BR:
  accounts:
    index:
      title: "Minhas Contas"
      new_account: "Nova Conta"
      net_worth: "Patrimônio Total"
      empty_state: "Você ainda não possui contas cadastradas"
      show_archived: "Mostrar arquivadas"
    new:
      title: "Nova Conta"
    edit:
      title: "Editar Conta"
    form:
      name: "Nome da Conta"
      account_type: "Tipo"
      initial_balance: "Saldo Inicial"
      submit_create: "Criar Conta"
      submit_update: "Salvar Alterações"
      cancel: "Cancelar"
      account_types:
        checking: "🏦 Corrente"
        investment: "📈 Investimentos"
    create:
      success: "Conta criada com sucesso"
    update:
      success: "Conta atualizada com sucesso"
    archive:
      success: "Conta arquivada com sucesso"
      confirm: "Tem certeza que deseja arquivar esta conta? O histórico será preservado."
    unarchive:
      success: "Conta reativada com sucesso"
    not_found: "Conta não encontrada"
```

#### Step 4.2: Implement Views

**Create** `app/views/accounts/index.html.erb`:
```erb
<div id="accounts-page" class="container mx-auto px-4 py-6">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold text-white"><%= t('.title') %></h1>
    <%= link_to t('.new_account'), new_account_path, class: "bg-cyan-600 hover:bg-cyan-700 text-white font-semibold py-2 px-4 rounded", data: { turbo_frame: "account-form" } %>
  </div>

  <%= render partial: "accounts/total" %>

  <div id="accounts-list" class="space-y-4">
    <%= turbo_stream_from "family_#{current_user.family_id}_accounts" %>

    <% if @accounts.empty? %>
      <div id="empty-state" class="bg-slate-800 border border-slate-700 rounded-lg p-12 text-center">
        <p class="text-gray-400 mb-4"><%= t('.empty_state') %></p>
        <%= link_to t('.new_account'), new_account_path, class: "bg-cyan-600 hover:bg-cyan-700 text-white font-semibold py-2 px-4 rounded inline-block" %>
      </div>
    <% else %>
      <%= render @accounts %>
    <% end %>
  </div>

  <% if @archived_accounts.present? %>
    <div id="archived-accounts-list" class="mt-8">
      <h2 class="text-xl font-bold text-white mb-4">Contas Arquivadas</h2>
      <%= render @archived_accounts %>
    </div>
  <% end %>

  <turbo-frame id="account-form"></turbo-frame>
</div>
```

**Create** `app/views/accounts/_total.html.erb`:
```erb
<div id="accounts-total" class="bg-slate-800 border border-slate-700 rounded-lg p-6 mb-6">
  <h2 class="text-sm text-gray-400 mb-2"><%= t('accounts.index.net_worth') %></h2>
  <span class="text-3xl font-bold text-white"><%= total_net_worth(current_user.family) %></span>
</div>
```

**Create** `app/views/accounts/_account.html.erb`:
```erb
<div id="<%= dom_id(account) %>" class="bg-slate-800 border border-slate-700 rounded-lg p-6 hover:border-cyan-600 transition">
  <div class="flex items-center justify-between">
    <div class="flex items-center space-x-4">
      <span class="text-3xl"><%= account.icon %></span>
      <div>
        <h3 class="text-lg font-semibold text-white"><%= account.name %></h3>
        <span class="text-sm text-gray-400"><%= account.account_type.humanize %></span>
      </div>
    </div>

    <div class="text-right">
      <p class="text-2xl font-bold <%= balance_class(account) %>">
        <%= format_balance(account) %>
      </p>
      <div class="mt-2 space-x-2">
        <%= link_to "Editar", edit_account_path(account), class: "text-cyan-400 hover:text-cyan-300 text-sm", data: { turbo_frame: "account-form" } %>
        <% unless account.archived? %>
          <%= link_to "Arquivar", archive_account_path(account), method: :delete, data: { turbo_method: :delete, turbo_confirm: t('accounts.archive.confirm') }, class: "text-red-400 hover:text-red-300 text-sm" %>
        <% else %>
          <%= link_to "Reativar", unarchive_account_path(account), method: :patch, data: { turbo_method: :patch }, class: "text-green-400 hover:text-green-300 text-sm" %>
        <% end %>
      </div>
    </div>
  </div>
</div>
```

**Create** `app/views/accounts/new.html.erb`:
```erb
<turbo-frame id="account-form" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
  <div class="bg-slate-800 rounded-lg p-6 max-w-md w-full mx-4">
    <h2 class="text-xl font-bold text-white mb-4"><%= t('.title') %></h2>
    <%= render partial: "form", locals: { account: @account } %>
  </div>
</turbo-frame>
```

**Create** `app/views/accounts/_form.html.erb`:
```erb
<%= form_with model: account, data: { controller: "account-form" } do |f| %>
  <% if account.errors.any? %>
    <div class="bg-red-900 border border-red-700 text-red-200 px-4 py-3 rounded mb-4">
      <ul class="list-disc list-inside">
        <% account.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="mb-4">
    <%= f.label :name, t('accounts.form.name'), class: "block text-sm font-semibold text-gray-300 mb-2" %>
    <%= f.text_field :name, maxlength: 50, required: true, class: "w-full bg-slate-900 border border-slate-700 text-white rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-cyan-600", data: { account_form_target: "name", action: "blur->account-form#validateName" } %>
    <span class="hidden text-red-400 text-sm mt-1" data-account-form-target="nameError"></span>
  </div>

  <div class="mb-4">
    <%= f.label :account_type, t('accounts.form.account_type'), class: "block text-sm font-semibold text-gray-300 mb-2" %>
    <%= f.select :account_type, options_for_select([
      [t('accounts.form.account_types.checking'), 'checking'],
      [t('accounts.form.account_types.investment'), 'investment']
    ], account.account_type), { prompt: "Selecione..." }, { required: true, class: "w-full bg-slate-900 border border-slate-700 text-white rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-cyan-600", disabled: account.persisted? } %>
    <% if account.persisted? %>
      <small class="text-gray-400 text-sm mt-1 block">Tipo não pode ser alterado após criação</small>
    <% end %>
  </div>

  <div class="mb-6">
    <%= f.label :initial_balance, t('accounts.form.initial_balance'), class: "block text-sm font-semibold text-gray-300 mb-2" %>
    <%= f.text_field :initial_balance, placeholder: "0,00", required: true, class: "w-full bg-slate-900 border border-slate-700 text-white rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-cyan-600", data: { account_form_target: "balance", action: "blur->account-form#validateBalance" } %>
    <span class="hidden text-red-400 text-sm mt-1" data-account-form-target="balanceError"></span>
    <small class="text-gray-400 text-sm mt-1 block">Pode ser positivo, zero ou negativo</small>
  </div>

  <div class="flex space-x-3">
    <%= f.submit account.persisted? ? t('accounts.form.submit_update') : t('accounts.form.submit_create'), class: "flex-1 bg-cyan-600 hover:bg-cyan-700 text-white font-semibold py-2 px-4 rounded" %>
    <%= link_to t('accounts.form.cancel'), accounts_path, class: "flex-1 bg-slate-700 hover:bg-slate-600 text-white font-semibold py-2 px-4 rounded text-center" %>
  </div>
<% end %>
```

**Create remaining views** (edit.html.erb, show.html.erb) following the same pattern.

---

### Phase 5: Testing & Quality Gates (1-2 hours)

#### Step 5.1: Run Full Test Suite

```bash
bundle exec rspec
```

#### Step 5.2: Run Quality Gates

```bash
bin/check
```

This runs:
- RSpec tests
- Rubocop linting
- Brakeman security scan

Fix any issues before proceeding.

#### Step 5.3: Browser Testing with Playwright

Test all user stories from spec.md using Playwright MCP:
1. Create first account
2. View account list with balances
3. Edit account
4. Archive account
5. Create multiple account types

---

### Phase 6: Seed Data & Manual Testing (30 minutes)

#### Step 6.1: Update Seeds

**Edit** `db/seeds.rb`:
```ruby
# Create test family with accounts
if Rails.env.development?
  family = Family.create!
  user = User.find_or_create_by!(email: 'test@example.com') do |u|
    u.password = 'password123'
    u.family = family
    u.role = :admin
    u.status = :active
  end

  Account.create!([
    { name: 'Nubank', account_type: :checking, initial_balance_cents: 150_000, family: family },
    { name: 'Bradesco', account_type: :checking, initial_balance_cents: 500_000, family: family },
    { name: 'Tesouro Direto', account_type: :investment, initial_balance_cents: 1_000_000, family: family }
  ])

  puts "✓ Seeded test user: test@example.com / password123"
  puts "✓ Seeded #{family.accounts.count} accounts"
end
```

#### Step 6.2: Run Seeds

```bash
bundle exec rails db:seed
```

#### Step 6.3: Start Development Server

```bash
bin/dev
```

Navigate to http://localhost:3000/accounts and verify:
- Account list displays correctly
- Create new account works
- Edit account works
- Archive/unarchive works
- Mobile responsive (test at 375px viewport)

---

## Troubleshooting

### Common Issues

**Issue**: Migration fails with "PG::UndefinedTable"
**Solution**: Ensure migrations run in order. Check `schema_migrations` table.

**Issue**: Tests fail with "FactoryBot not found"
**Solution**: Add `require 'factory_bot_rails'` to `spec/rails_helper.rb`

**Issue**: Money-rails formatting incorrect
**Solution**: Verify `config/initializers/money.rb` sets `default_currency = :brl`

**Issue**: Turbo Streams not working
**Solution**: Ensure `<%= turbo_stream_from %>` in view and Action Cable configured

**Issue**: 403 Forbidden on account access
**Solution**: Verify family scoping in controller: `current_user.family.accounts.find(params[:id])`

---

## Verification Checklist

Before marking implementation complete:

- [ ] All migrations ran successfully
- [ ] All model tests pass
- [ ] All request tests pass
- [ ] All system tests pass
- [ ] `bin/check` passes without errors
- [ ] Manual browser testing completed
- [ ] Mobile viewport (375px) tested
- [ ] Desktop viewport (1280px) tested
- [ ] All 5 user stories from spec.md validated
- [ ] Real-time updates working (test with multiple browsers)
- [ ] Archived accounts excluded from main list
- [ ] Total net worth calculation correct
- [ ] Visual consistency with existing design system
- [ ] I18n translations complete (pt-BR)
- [ ] Code written in English (variables, methods, classes)
- [ ] Routes follow RESTful conventions

---

## Next Steps

After completing this feature:

1. **Code Review**: Request PR review from team
2. **Merge**: Merge branch to main after approval
3. **Deploy**: Deploy to staging environment
4. **User Testing**: Validate with real users
5. **Monitor**: Check for errors in production logs
6. **Next Feature**: Move to transaction management feature

---

## Additional Resources

- **Data Model**: See `specs/001-account-management/data-model.md`
- **API Contracts**: See `specs/001-account-management/contracts/routes.md`
- **Research**: See `specs/001-account-management/research.md`
- **Constitution**: See `.specify/memory/constitution.md`
- **PRD**: See `docs/PRD.md`

---

**Status**: Quickstart guide complete, ready for implementation
