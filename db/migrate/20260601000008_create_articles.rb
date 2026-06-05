class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string  :title, null: false
      t.string  :category
      t.string  :author
      t.text    :summary
      t.text    :body
      t.integer :read_minutes
      t.string  :tag
      t.string  :hero_color
      t.date    :published_on

      t.timestamps
    end

    add_index :articles, :category
  end
end
