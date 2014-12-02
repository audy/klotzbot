require './environment.rb'

Bundler.require :web

set :server, 'thin'
set :sockets, []

def tail &block
  DB.loggers = []
  last_time = Time.now
  puts "listening for new messages..."
  Thread.new {
    while true do
      msgs = Message.last(10).keep_if { |m| m.created_at > last_time }
      last_time = Time.now unless msgs.size == 0
      msgs.each do |m|
        block.yield "#{m.channel.name}\t#{m.nick}: #{m.message}"
      end
      sleep 1
    end
  }
end

get '/' do

  unless request.websocket?
    erb :index
  else
    request.websocket do |ws|
      ws.onopen do
        ws.send("Hello, World!")
        settings.sockets << ws
      end

      tail do |msg|
        puts "new message: #{msg}"
        EM.next_tick { settings.sockets.each { |s| s.send(msg) } }
      end

      ws.onclose do
        warn "websocket closed"
        settings.sockets.delete(ws)
      end

    end

  end
end

__END__
@@ index
<html>

  <body>
     <div id="msgs"></div>
  </body>

  <script type="text/javascript">
    window.onload = function(){
      (function(){
        var show = function(el){
          return function(msg){ el.innerHTML = msg + '<br />' + el.innerHTML; }
        }(document.getElementById('msgs'));

        var ws       = new WebSocket('ws://' + window.location.host + window.location.pathname);
        ws.onopen    = function()  { show('websocket opened'); };
        ws.onclose   = function()  { show('websocket closed'); }
        ws.onmessage = function(m) { show('websocket message: ' +  m.data); };

        var sender = function(f){
          var input     = document.getElementById('input');
          input.onclick = function(){ input.value = "" };
          f.onsubmit    = function(){
            ws.send(input.value);
            input.value = "send a message";
            return false;
          }
        }(document.getElementById('form'));
      })();
    }
  </script>
</html>
