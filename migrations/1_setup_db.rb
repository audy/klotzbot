Sequel.migration do

  up do

    create_table? :messages do
      primary_key :id

      String :nick
      String :channel
      String :message

      DateTime :created_at
    end

  end

  down do
    drop_table :messages
  end

end
