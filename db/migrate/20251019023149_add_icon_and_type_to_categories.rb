class AddIconAndTypeToCategories < ActiveRecord::Migration[7.2]
  def change
    add_column :categories, :icon, :string, default: "💰"
    add_column :categories, :category_type, :string, default: "expense"
  end
end
