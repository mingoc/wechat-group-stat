class CreateMembers < ActiveRecord::Migration
  def change
    create_table :members do |t|
      t.string :wxid
      t.string :name
      t.string :nick
      t.string :status

      t.timestamps null: false
    end
  end
end
