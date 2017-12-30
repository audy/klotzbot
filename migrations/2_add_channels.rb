Sequel.migration do

  up do

    create_table :channels do
      primary_key :id
      String :channel_name
      index :channel_name, unique: true
    end

    alter_table :messages do
      rename_column :channel, :channel_name
      add_foreign_key :channel_id, :channels
    end

    # this code no longer maintained. Sequel changed their API and I only
    # needed to run this migration once back in 2014 so I'm not going to fix it
#    # generate a new channel for each unique channel name
#    self[:channels].insert([:channel_name],
#      self[:messages].distinct.select(:channel_name))
#
#    # replace channel with channel_id in messages
#    channel_map = self[:channels].select_hash(:id, :channel_name)
#
#    # add channel_id to messages
#    self[:messages].
#      update(channel_id: self[:channels].
#             select(:id).
#             where(channel_name: :messages__channel_name))

    # delete channel_name from messages
    drop_column :messages, :channel_name
    rename_column :channels, :channel_name, :name
  end

  down do

    alter_table :messages do
      add_column :channel_name, String
    end

    # this code no longer maintained. Sequel changed their API and I only
    # needed to run this migration once back in 2014 so I'm not going to fix it
#    # replace channel with name
#    self[:messages].
#      update(channel_name: self[:channels].
#             select(:channel_name).
#             where(channel_name: :messages__channel_name))

    alter_table :messages do
      rename_column :channel_name, :channel
      drop_column :channel_id
    end

    drop_table :channels
  end

end
