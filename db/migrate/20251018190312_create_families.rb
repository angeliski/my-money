class CreateFamilies < ActiveRecord::Migration[7.2]
  def change
    create_table :families do |t|
      t.timestamps
    end

    add_index :families, :created_at
  end
end
