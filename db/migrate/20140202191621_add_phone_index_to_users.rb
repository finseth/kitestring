include ApplicationHelper

class AddPhoneIndexToUsers < ActiveRecord::Migration
  def up
    add_column :users, :phone_index, :string
    User.all.each do |user|
      user.update_attributes!(:phone_index => normalize_phone(user.phone))
    end
    change_column :users, :phone_index, :string, :null => false
    add_index :users, :phone_index
  end

  def down
     remove_column :users, :phone_index
  end
end
