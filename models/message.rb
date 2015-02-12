class Message < Sequel::Model
  many_to_one :channel
 
  def self.random
    id = rand(1..self.count)
    msg = self[id]
  end
end
