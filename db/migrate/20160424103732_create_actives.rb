class CreateActives < ActiveRecord::Migration
  def change
    create_table :actives do |t|
      t.string :name
      t.datetime :time
      t.string :detail

      t.timestamps null: false
    end
  end
end
