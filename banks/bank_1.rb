# frozen_string_literal: true

# https://github.com/ddollar/foreman/wiki/Missing-Output
$stdout.sync = true

require 'bunny'
require 'json'

INGRESS = 'bank1Queue'
EGRESS = 'bankReplyQueue'

connection = Bunny.new
connection.start

channel = connection.create_channel
ingress = channel.queue(INGRESS)

begin
  puts ' [*] Waiting for loan requests'

  ingress.subscribe(block: true) do |_delivery_info, _properties, body|
    payload = JSON.parse(body, symbolize_names: true)
    puts " [>] Received #{payload}"

    # Bank 1 always accept loans and always returns a 4% interest rate
    response = payload.merge(interest_rate: 0.04, approved: true)

    puts " [<] Replied #{response}"
    channel.default_exchange.publish(response.to_json, routing_key: EGRESS)
  end
rescue Interrupt => _e
  connection.close
end
