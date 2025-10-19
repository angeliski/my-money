class CreateTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :transactions do |t|
      # Core transaction data
      t.string :transaction_type, null: false
      t.integer :amount_cents, null: false
      t.string :currency, default: 'BRL', null: false
      t.date :transaction_date, null: false
      t.text :description, null: false

      # Relationships
      t.references :account, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      # Recurring/Template fields
      t.boolean :is_template, default: false, null: false
      t.string :frequency
      t.date :start_date
      t.date :end_date
      t.references :parent_transaction, foreign_key: { to_table: :transactions }
      t.datetime :effectuated_at

      # Transfer linking
      t.references :linked_transaction, foreign_key: { to_table: :transactions }

      # Audit trail
      t.references :editor, foreign_key: { to_table: :users }
      t.datetime :edited_at

      t.timestamps
    end

    # Performance indexes (references already create indexes for foreign keys)
    add_index :transactions, :transaction_date
    add_index :transactions, :transaction_type
    add_index :transactions, [:is_template, :parent_transaction_id]
  end
end
