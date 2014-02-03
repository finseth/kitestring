include ApplicationHelper

class NormalizePhoneNumbers < ActiveRecord::Migration
  def up
    remove_column :users, :phone_index
    add_index :users, :phone
    User.all.each do |user|
      user.update_attributes!(:phone => normalize_phone(user.phone))
    end
    Contact.all.each do |contact|
      begin
        contact.update_attributes!(:phone => normalize_phone(contact.phone))
      rescue
      end
    end
  end

  def down
    add_column :users, :phone_index, :string
    User.all.each do |user|
      user.update_attributes!(:phone_index => normalize_phone(user.phone))
    end
    change_column :users, :phone_index, :string, :null => false
    add_index :users, :phone_index
    remove_index :users, :phone
  end
end
