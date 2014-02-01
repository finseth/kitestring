class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.string :name, :null => false
      t.string :phone, :null => false
      t.integer :user_id, :null => false

      t.timestamps
    end

    change_column :contacts, :created_at, :datetime, :null => false
    change_column :contacts, :updated_at, :datetime, :null => false
  end
end
