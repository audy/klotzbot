Sequel.migration do

  create_table :messages do

    primary_key :id

    String :nick
    String :channel
    String :message

    DateTime :created_at, :index => true

  end

end
