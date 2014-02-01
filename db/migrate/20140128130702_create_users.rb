class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :phone, :null => false
      t.string :name, :null => false
      t.string :password_salt, :null => false
      t.string :password_hash, :null => false
      t.datetime :checkpoint
      t.text :message
      t.boolean :pinged
      t.boolean :responded
      t.boolean :alerted

      t.timestamps
    end

    change_column :users, :created_at, :datetime, :null => false
    change_column :users, :updated_at, :datetime, :null => false
  end
end
