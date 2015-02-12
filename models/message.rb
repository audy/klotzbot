class Message < Sequel::Model
  many_to_one :channel
 
  def self.random
    @msg = nil
    last = self.last.id
    while @msg.nil?
      id = rand(1..last)
      @msg = self[id]
    end
    return @msg
  end
end
