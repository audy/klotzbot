Sequel.migration do

  up do

    create_table :channels do
      primary_key :id
      String :channel
    end

    alter_table :messages do
      add_foreign_key :channel_id, :channels
    end

  end

  down do
    drop_table :channels
  end

end
