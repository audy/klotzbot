class Message < Sequel::Model
  many_to_one :channel
 
  def self.random
    id = rand(1..self.last.id)
    msg = self[id]
  end
end
