class CreateWorkaouts < ActiveRecord::Migration
  def change
    drop_table :workaouts
    create_table :workaouts do |t|
      t.string :wxid
      t.string :name
      t.datetime :time
      t.string :detail

      t.timestamps null: false
    end
  end
end
