class CreateOauthRegistrations < ActiveRecord::Migration[8.0]
  def change
    create_table :oauth_registrations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :client_id, null: false
      t.string :client_name
      t.string :logo_uri
      t.string :client_uri
      t.string :redirect_uris, default: "[]", null: false
      t.timestamps
    end
    add_index :oauth_registrations, :client_id, unique: true
  end
end
