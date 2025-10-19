class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.integer :account_type, null: false, default: 0
      t.integer :initial_balance_cents, null: false, default: 0
      t.string :icon, null: false
      t.string :color, null: false
      t.datetime :archived_at
      t.references :family, null: false, foreign_key: true

      t.timestamps
    end

    add_index :accounts, :archived_at
    add_index :accounts, [ :family_id, :archived_at ]
    add_index :accounts, :created_at
  end
end
