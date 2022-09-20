class CreateReports < ActiveRecord::Migration[7.0]
  def change
    create_table :reports do |t|
      t.string  :name
      t.string  :description
      t.text    :options
      t.boolean :activated, default: true

      t.timestamps
    end

    add_index  :reports, :name
    add_index  :reports, :activated
  end
end
