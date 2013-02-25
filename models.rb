class Message
  include MongoMapper::Document

  key :text, String
  key :user, String
  key :channel, String
  key :date, Time

  before_save :save_time

  def save_time
    self.date = Time.now
  end

  def pretty
    "#{self.user}: #{self.text} [#{self.date.localtime.strftime('%d/%m/%Y @ %Hh%M')}]"
  end
end
