Sequel.migration do
  up do
    alter_table :messages do
      add_column :ip, String
    end
  end

  down do
    alter_table :messages do
      remove_column :ip, String
    end
  end
end
