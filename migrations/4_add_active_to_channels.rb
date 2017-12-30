Sequel.migration do
  up do
    alter_table :channels do
      add_column :active, TrueClass, default: true
    end
  end

  down do
    alter_table :channels do
      remove_column :active, TrueClass
    end
  end
end
