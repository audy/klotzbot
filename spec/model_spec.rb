require 'spec_helper'

describe 'models' do
  let(:channel) { Channel.new name: '#test' }
  let(:message) { Message.new nick: 'test', message: 'test test test' }

  describe Channel do
    it '#new' do
      expect(channel).not_to eq(nil)
    end

    it '#save' do
      expect{channel.save}.not_to raise_error
    end
  end

  describe Message do
    it '#new' do
      expect(channel).not_to eq(nil)
    end

    it '#save' do
      expect{channel.save}.not_to raise_error
    end

    it '#channel' do
      expect{message.channel}.not_to raise_error
    end

    it '#channel=' do
      channel.save
      message.save
      expect{message.channel = channel}.not_to raise_error
      expect{message.save}.not_to raise_error
      expect(message.channel).to eq(channel)
    end

    it '#ip' do
      expect{message.ip}.to_not raise_error
      expect{message.update ip: '0.0.0.0'}.to_not raise_error
    end
  end
end
