# frozen_string_literal: true

# https://github.com/ddollar/foreman/wiki/Missing-Output
$stdout.sync = true

require 'bunny'
require 'json'

INGRESS_QUEUE = 'creditRequestQueue'
EGRESS_QUEUE = 'creditReplyQueue'

# In a real world, we would connect to a database of sort
# but this will do as an example
CREDIT_SCORES_DB = {
  '123 45 6789' => 824,
  '234 56 7891' => 542,
  '345 67 8912' => 738,
  '456 78 9123' => 434
}.freeze

# Connect to RabbitMQ
connection = Bunny.new
connection.start

# Create the channel to subscribe to (note: this operation is idempotent
# so another process might already have created the queue)
channel = connection.create_channel
ingress = channel.queue(INGRESS_QUEUE)

begin
  puts ' [*] Waiting for credit requests'

  ingress.subscribe(block: true) do |_delivery_info, _properties, body|
    payload = JSON.parse(body, symbolize_names: true)
    puts " [>] Received #{payload}"

    credit_score = CREDIT_SCORES_DB.fetch(payload[:social_security_number], 0)
    response = payload.merge(credit_score: credit_score)

    puts " [<] Replied with #{response}"
    channel.default_exchange.publish(response.to_json, routing_key: EGRESS_QUEUE)
  end
rescue Interrupt => _e
  connection.close
end
