class Message < Sequel::Model
  many_to_one :channel


  def self.random
    # start when we switched to libera.chat
    start_id = 81781052
    @msg = nil
    last = self.last.id
    while @msg.nil?
      id = rand(start_id..last)
      @msg = self[id]
    end
    return @msg
  end
end
