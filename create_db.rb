# frozen_string_literal: true

require 'sqlite3'
require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db.db')

ActiveRecord::Migration.class_eval do
  create_table :users do |t|
    t.string :name
  end

  create_table :avatars do |t|
    t.references :user
    t.string :filename
  end
end
