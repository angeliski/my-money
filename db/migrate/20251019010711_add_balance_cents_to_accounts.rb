class AddBalanceCentsToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :balance_cents, :integer, default: 0, null: false

    # Initialize balance_cents with initial_balance_cents for existing accounts
    reversible do |dir|
      dir.up do
        execute "UPDATE accounts SET balance_cents = initial_balance_cents"
      end
    end
  end
end
