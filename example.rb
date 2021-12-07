# frozen_string_literal: true

require 'sqlite3'
require 'active_record'
require 'reform'
require 'reform/form/dry'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db.db')

class User < ActiveRecord::Base
  has_one :avatar,
          inverse_of: :user,
          autosave: true # need for `mark_for_destruction`
end

class Avatar < ActiveRecord::Base
  belongs_to :user,
             inverse_of: :avatar
end

class AvatarForm < Reform::Form
  feature Reform::Form::Dry

  property :_destroy, virtual: true
  property :filename
end

class UserForm < Reform::Form
  feature Reform::Form::Dry

  property :name
  property :avatar,
           populator: :find_or_build_or_mark_destroy,
           form: AvatarForm

  def find_or_build_or_mark_destroy(model:, fragment:, **)
    if model
      model.model.mark_for_destruction if fragment[:_destroy] == '1'
      model
    else
      self.avatar = Avatar.new
    end
  end
end

def log_state(user, avatar)
  puts "user persisted: #{user.persisted?}"
  puts "avatar persisted: #{avatar.persisted?}"
  puts "user name: #{user.name}"
  puts "avatar filename: #{avatar.filename}"
end

# transaction for db cleanup at the end
ActiveRecord::Base.transaction do
  form = UserForm.new(User.new)
  form.validate(name: 'Alastor', avatar: { filename: 'radio_demon.png' })
  form.save

  user = form.model
  avatar = user.avatar

  log_state(user, avatar)
  puts '===='

  destroy_form = UserForm.new(user)
  destroy_form.validate(name: 'Radio Demon', avatar: { _destroy: '1' })
  destroy_form.save

  log_state(user, avatar)

  raise ActiveRecord::Rollback
end
