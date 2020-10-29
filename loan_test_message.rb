# frozen_string_literal: true

require 'bunny'
require 'json'

connection = Bunny.new
connection.start

channel = connection.create_channel
queue = channel.queue('loanRequestQueue')

payload = {
  customer_name: 'Jane Doe',
  social_security_number: '123 45 6789',
  amount_loan: 10_000
}

channel.default_exchange.publish(payload.to_json, routing_key: queue.name)
