# frozen_string_literal: true

# https://github.com/ddollar/foreman/wiki/Missing-Output
$stdout.sync = true

require 'bunny'
require 'json'

LOAN_REQUEST = 'loanRequestQueue'
CREDIT_REQUEST = 'creditRequestQueue'
CREDIT_REPLY = 'creditReplyQueue'

# Connect to RabbitMQ
connection = Bunny.new
connection.start

# Create the channel to subscribe to (note: this operation is idempotent
# so another process might already have created the queue)
channel = connection.create_channel

loan_request = channel.queue(LOAN_REQUEST)
credit_reply = channel.queue(CREDIT_REPLY)

# Spawn two processes for the content enricher:
#   1. to send requests to the credit bureau
#   2. to consume responses from the credit bureau

# Loan Requests Queue
Thread.new do
  puts ' [*] Waiting for loan requests. To exit press CTRL+C'

  loan_request.subscribe(block: true) do |_delivery_info, _properties, body|
    payload = JSON.parse(body, symbolize_names: true)
    puts " [>] Loan Request: Received #{payload}"

    puts ' [<] Loan Request: Sending a Credit Request'
    channel.default_exchange.publish(payload.to_json, routing_key: CREDIT_REQUEST)
  end
end

# Credit Reply Queue (Main Process)
begin
  puts ' [*] Waiting for credit replies. To exit press CTRL+C'

  credit_reply.subscribe(block: true) do |_delivery_info, _properties, body|
    payload = JSON.parse(body, symbolize_names: true)
    puts " [>] Credit Reply: Received #{payload}"
  end
rescue Interrupt => _e
  connection.close
end
