class AddAttributesToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :role, :string, null: false, default: 'member'
    add_column :users, :name, :string
  end
end
