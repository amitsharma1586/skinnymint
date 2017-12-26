class DropSpreePermissions < ActiveRecord::Migration
  def change
    drop_table :spree_permissions do |t|
      t.string :title, :null => false, :unique => true
      t.integer :priority, :default => 0
      t.boolean :visible, :boolean, :default => true
      t.timestamps null: false
    end
    drop_table :spree_roles_permissions, :id => false do |t|
      t.integer :role_id, :null => false
      t.integer :permission_id, :null => false
    end
    remove_column :spree_roles, :editable, :boolean, :default => true
    remove_column :spree_roles, :is_default, :boolean, :default => false
    remove_index :spree_roles, :name if index_exists?(:spree_roles, :name)
  end
end
