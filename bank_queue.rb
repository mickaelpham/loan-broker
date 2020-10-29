require 'bunny'
require 'json'

connection = Bunny.new
connection.start

channel = connection.create_channel
queue = channel.queue('bank1Queue')

begin
  puts ' [*] Waiting for messages. To exit press CTRL+C'

  queue.subscribe(block: true) do |_delivery_info, _properties, body|
    payload = JSON.parse(body, symbolize_key: true)
    puts " [x] Received #{payload}"
  end
rescue Interrupt => _e
  connection.close
  exit(0)
end
