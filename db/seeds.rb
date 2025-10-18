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
end
