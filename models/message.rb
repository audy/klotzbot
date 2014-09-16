class Message < Sequel::Model
  many_to_one :channels
end
