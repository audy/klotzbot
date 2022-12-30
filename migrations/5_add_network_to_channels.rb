Sequel.migration do
  up do
    alter_table :channels do
      add_column :network, String, default: 'irc.freenode.net'
    end
  end

  down do
    alter_table :channels do
      remove_column :network, String
    end
  end
end
