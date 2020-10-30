require 'bunny'
require 'json'

CREDIT_SCORES_DB = {
  '123 45 6789' => 820, # Jane Doe
  '234 56 7891' => 540, # Jack Doe
  '345 67 8912' => 750  # John Doe
}.freeze

INGRESS_QUEUE = 'creditRequestQueue'.freeze
EGRESS_QUEUE = 'creditReplyQueue'.freeze

connection = Bunny.new(hostname: 'broker')

puts 'hmmmm, la bd'

begin
  puts 'Connecting to broker'
  connection.start
rescue Bunny::Exception => e
  puts "Could not connect to Broker: #{e}"
  sleep(1)
  retry
end

channel = connection.create_channel
loan_request_queue = channel.queue(INGRESS_QUEUE)

begin
  puts ' [*] Waiting for messages. To exit press CTRL+C'
  loan_request_queue.subscribe(block: true) do |_delivery_info, _properties, body|
    puts " [>] Received #{body}"

    # parse the message body
    loan_request = JSON.parse(body, symbolize_keys: true)

    # fetch the credit score based on the social security number
    ssn = loan_request[:social_security_number]
    credit_score = CREDIT_SCORES_DB.fetch(ssn, 0)
    puts " [.] Retrieved credit score (#{credit_score}) for SSN #{ssn}"

    # enrich the payload and add the message to the reply queue
    reply = loan_request.merge(credit_score: credit_score)

    channel.default_exchange.publish(reply.to_json, routing_key: EGRESS_QUEUE)
    puts " [<] Replied to #{EGRESS_QUEUE}"
  end
rescue Interrupt => _e
  connection.close
  exit(0)
end
