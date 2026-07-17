require 'ostruct'

class User
  FAKE_USER = OpenStruct.new(
    id: '1',
    email: 'user@example.com',
    first_name: 'Fake',
    last_name: 'User',
    role: 'admin',
    session_number: nil
  ).freeze

  attr_accessor :id, :email, :first_name, :last_name, :role, :session_number, :password_details
  attr_reader :user_oauth

  def initialize(attrs = {})
    attrs.each { |k, v| send("#{k}=", k.to_sym == :password_details ? v : v) rescue nil }
    @password_details = {}
  end

  def enabled?
    true
  end

  def get_or_create_user_oauth
    @user_oauth ||= UserOauth.create!(user: self)
  end

  def as_json(options = {})
    { id: id, first_name: first_name, last_name: last_name, email: email }
  end

  def self.find(id)
    new(FAKE_USER.to_h.merge(id: id.to_s))
  end

  def self.find_by(id: nil, session_number: nil, **)
    return nil unless id.present?
    new(FAKE_USER.to_h.merge(id: id.to_s))
  end
end
