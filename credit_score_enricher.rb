require 'bunny'
require 'json'
require_relative 'recipient_list'

CREDIT_SCORES_DB = {
  '123 45 6789' => 820, # Jane Doe
  '234 56 7891' => 540, # Jack Doe
  '345 67 8912' => 750  # John Doe
}.freeze

connection = Bunny.new
connection.start

channel = connection.create_channel

loan_request_queue = channel.queue('loanRequestQueue')
bank_queues = BANKS_DB.map do |bank_name|
  channel.queue("#{bank_name}Queue")
end

def bank_queue(bank_name)
  "#{bank_name}Queue"
end

def credit_score(social_security_number)
  CREDIT_SCORES_DB.fetch(social_security_number, 0)
end

begin
  puts ' [*] Waiting for messages. To exit press CTRL+C'

  loan_request_queue.subscribe(block: true) do |_delivery_info, _properties, body|
    payload = JSON.parse(body, symbolize_key: true)
    puts " [x] Received #{payload}"

    # enrich with the credit score
    payload[:credit_score] = credit_score(payload[:social_security_number])

    # get the bank recipients list
    banks = bank_recipients(payload[:credit_score])

    # add the expected banks response to the message
    payload[:expected_bank_replies] = banks.size

    # fan out to all the banks on the list
    banks.each do |bank_name|
      channel.default_exchange.publish(payload.to_json, routing_key: bank_queue(bank_name))
    end
  end
rescue Interrupt => _e
  connection.close
  exit(0)
end
