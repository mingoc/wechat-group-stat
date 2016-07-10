class CreateWorkouts < ActiveRecord::Migration
  def change
    create_table :workouts do |t|
      t.integer :msgId
      t.integer :msgSvrId, :limit => 8
      t.string :wxid
      t.string :name
      t.datetime :time
      t.string :detail

      t.timestamps null: false
    end
  end
end
