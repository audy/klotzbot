class Message < Sequel::Model
  many_to_one :channel
 
  def self.random
    id = rand(1..self.last.id)
    @msg = nil
    while @msg.nil?
      @msg = self[id]
    end
    return @msg
  end
end
