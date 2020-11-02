# frozen_string_literal: true

# Spawn two processes for the content enricher:
#   1. to send requests to the credit bureau
#   2. to consume responses from the credit bureau

# Loan Requests Queue
Thread.new do
  # Create a channel for the thread
  channel = $connection.create_channel

  # Create the queue to subscribe to (note: this operation is idempotent, so it won't create
  # the queue if it already exists)
  loan_request = channel.queue(LOAN_REQUEST)
  puts ' [*] Waiting for loan requests. To exit press CTRL+C'

  loan_request.subscribe(block: true) do |_delivery_info, _properties, body|
    payload = JSON.parse(body, symbolize_names: true)
    puts " [>] Loan Request: Received #{payload}"

    puts ' [<] Loan Request: Sending a Credit Request'
    channel.default_exchange.publish(payload.to_json, routing_key: CREDIT_REQUEST)
  end
end

# Credit Reply Queue
Thread.new do
  # Create a channel for the thread
  channel = $connection.create_channel

  credit_reply = channel.queue(CREDIT_REPLY)
  puts ' [*] Waiting for credit replies. To exit press CTRL+C'

  credit_reply.subscribe(block: true) do |_delivery_info, _properties, body|
    payload = JSON.parse(body, symbolize_names: true)
    puts " [>] Credit Reply: Received #{payload}"

    # Get the recipient list and publish a request on each bank on the list
    banks = bank_recipients(payload[:credit_score])

    banks.each do |bank|
      bank_queue = "#{bank}Queue"

      puts " [<] Loan Request: Sending a request on behalf of #{payload[:customer_name]} to #{bank}"
      channel.default_exchange.publish(payload.to_json, routing_key: bank_queue)
    end
  end
end
