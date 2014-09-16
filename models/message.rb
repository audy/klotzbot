class Message < Sequel::Model
  many_to_one :channel
end
