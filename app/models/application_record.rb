class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  
  default_scope { order(:created_at) }

  def initialize_id
    self.id ||= SecureRandom.uuid
  end

  def as_json(options = nil)
    {id: id, created_at: created_at, updated_at: updated_at}
  end

end
