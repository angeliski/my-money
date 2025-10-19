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

  # Categories
  categories = [
    "Comida",
    "Transporte",
    "Moradia",
    "Saúde",
    "Entretenimento"
  ]

  categories.each do |category_name|
    Category.find_or_create_by!(name: category_name)
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
