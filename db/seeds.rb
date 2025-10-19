# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

if Rails.env.development?
  # Admin user
  admin = User.find_or_create_by!(email: "admin@mymoney.com") do |user|
    user.name = "Admin"
    user.password = "123456"
    user.role = :admin
    user.status = :active
  end

  # Categories - Despesas (Expenses)
  expense_categories = [
    { name: "Moradia", icon: "🏠", category_type: "expense" },
    { name: "Contas", icon: "💡", category_type: "expense" },
    { name: "Alimentação", icon: "🍔", category_type: "expense" },
    { name: "Transporte", icon: "🚗", category_type: "expense" },
    { name: "Saúde", icon: "🏥", category_type: "expense" },
    { name: "Educação", icon: "📚", category_type: "expense" },
    { name: "Lazer", icon: "🎮", category_type: "expense" },
    { name: "Vestuário", icon: "👕", category_type: "expense" },
    { name: "Pets", icon: "🐕", category_type: "expense" },
    { name: "Outros Despesas", icon: "💸", category_type: "expense" },
    { name: "Transferência", icon: "↔️", category_type: "transfer" }  # Required for transfers
  ]

  # Categories - Receitas (Income)
  income_categories = [
    { name: "Salário", icon: "💼", category_type: "income" },
    { name: "Freelance", icon: "💻", category_type: "income" },
    { name: "Rendimentos", icon: "📈", category_type: "income" },
    { name: "Presentes", icon: "🎁", category_type: "income" },
    { name: "Outros Receitas", icon: "💵", category_type: "income" }
  ]

  (expense_categories + income_categories).each do |category_data|
    Category.find_or_create_by!(name: category_data[:name]) do |category|
      category.icon = category_data[:icon]
      category.category_type = category_data[:category_type]
    end
  end

  # Accounts for admin user's family
  unless admin.family.accounts.exists?
    puts "Creating sample accounts for #{admin.email}..."

    # Checking accounts
    Account.create!([
      {
        name: "Nubank",
        account_type: :checking,
        initial_balance_cents: 150_000,  # R$ 1,500.00
        family: admin.family
      },
      {
        name: "Bradesco",
        account_type: :checking,
        initial_balance_cents: 500_000,  # R$ 5,000.00
        family: admin.family
      },
      {
        name: "Inter",
        account_type: :checking,
        initial_balance_cents: -20_000,  # -R$ 200.00 (negative balance example)
        family: admin.family
      }
    ])

    # Investment accounts
    Account.create!([
      {
        name: "Tesouro Direto",
        account_type: :investment,
        initial_balance_cents: 1_000_000,  # R$ 10,000.00
        family: admin.family
      },
      {
        name: "XP Investimentos",
        account_type: :investment,
        initial_balance_cents: 5_000_000,  # R$ 50,000.00
        family: admin.family
      }
    ])

    # Archived account (for testing archived view)
    Account.create!(
      name: "Conta Antiga Itaú",
      account_type: :checking,
      initial_balance_cents: 0,
      archived_at: 1.month.ago,
      family: admin.family
    )

    puts "✓ Created #{admin.family.accounts.active.count} active accounts"
    puts "✓ Created #{admin.family.accounts.archived.count} archived account"
    puts "✓ Total net worth: #{Money.new(admin.family.accounts.active.sum(&:initial_balance_cents), 'BRL').format}"
  end

  puts "\n=== Development Seeds Loaded ==="
  puts "Email: admin@mymoney.com"
  puts "Password: 123456"
  puts "Accounts: #{admin.family.accounts.count} (#{admin.family.accounts.active.count} active, #{admin.family.accounts.archived.count} archived)"
  puts "================================\n"
end
