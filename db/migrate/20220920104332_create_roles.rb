class CreateRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :roles do |t|
      t.string        :name
      t.json          :permissions
      t.string        :description

      t.timestamps
    end
  end
end
