class AddProviderToMessages < ActiveRecord::Migration[8.1]
  def change
    # The staff member (provider) a thread is with. A conversation is the pair
    # (member, provider). Nullable so existing rows remain valid; backfilled in seeds.
    add_reference :messages, :provider, foreign_key: { to_table: :users }
    add_index :messages, [ :member_id, :provider_id, :created_at ],
              name: "index_messages_on_member_provider_created"
  end
end
