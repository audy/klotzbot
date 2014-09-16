Sequel.migration do

  up do

    create_table :channels do
      primary_key :id
      String :channel
    end
    
    alter_table :messages do
      add_foreign_key :channel_id, :channels
    end

    self[:channels].insert([:channel_id],
      self[:messages].select(:id, :channel_id).exclude(channel_id: nil))

  end

  down do
    drop_table :channels
  end

end
