# frozen_string_literal: true

require 'bunny'
require 'json'

connection = Bunny.new
connection.start

channel = connection.create_channel

payload = {
  customer_name: 'Jane Doe',
  social_security_number: '123 45 6789',
  loan_amount: 10_000
}

channel.default_exchange.publish(payload.to_json, routing_key: 'loanRequestQueue')
