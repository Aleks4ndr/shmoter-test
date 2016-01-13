class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.references :partner
      t.string :title
      t.string :partner_item_id
      t.boolean :availiable_in_store

      t.timestamps null: false
    end
  end
end
