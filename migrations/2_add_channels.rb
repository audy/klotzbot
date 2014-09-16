Sequel.migration do

  create_table :channels do
    primary_key :id
    String :channel
  end

  modify_table :messages do
    foreign_key :channels, :channel_id
  end

end
