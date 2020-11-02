# frozen_string_literal: true

# https://github.com/ddollar/foreman/wiki/Missing-Output
$stdout.sync = true

require 'bunny'
require 'json'

INGRESS = 'bank2Queue'
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

    # Bank 2 always accept loans, but returns different interest rates
    interest_rate = payload[:amount_loan] < 10_000 ? 0.06 : 0.03
    response = payload.merge(interest_rate: interest_rate, approved: true, bank: 'Bank 2')

    puts " [<] Replied #{response}"
    channel.default_exchange.publish(response.to_json, routing_key: EGRESS)
  end
rescue Interrupt => _e
  connection.close
end
