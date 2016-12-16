class CreateAllotments < ActiveRecord::Migration
  def change
    create_table :allotments do |t|
      t.datetime :date
      t.integer :position
      t.references :user, index: true, foreign_key: true
      t.references :place, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
