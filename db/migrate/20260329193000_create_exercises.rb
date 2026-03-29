class CreateExercises < ActiveRecord::Migration[8.1]
  def change
    create_table :exercises do |t|
      t.string :public_id, null: false
      t.string :name, null: false
      t.string :movement_category
      t.string :primary_muscle_group
      t.string :equipment_type
      t.text :notes

      t.timestamps
    end

    add_index :exercises, :public_id, unique: true
    add_index :exercises, :name, unique: true
    add_index :exercises, :movement_category
    add_index :exercises, :primary_muscle_group
    add_index :exercises, :equipment_type
  end
end
