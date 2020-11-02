# frozen_string_literal: true

# https://github.com/ddollar/foreman/wiki/Missing-Output
$stdout.sync = true

require 'bunny'
require 'json'

INGRESS = 'bank4Queue'
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

    # Bank 4 always returns a 1.5% interest rate but does not accept amounts
    # less than or equal to $5,000
    approved = payload[:loan_amount] >= 5_000
    response = payload.merge(interest_rate: 0.015, approved: approved)

    puts " [<] Replied #{response}"
    channel.default_exchange.publish(response.to_json, routing_key: EGRESS)
  end
rescue Interrupt => _e
  connection.close
end
