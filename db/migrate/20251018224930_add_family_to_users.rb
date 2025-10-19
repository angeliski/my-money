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
