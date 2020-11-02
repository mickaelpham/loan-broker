# frozen_string_literal: true

Thread.new do
  redis = Redis.new

  channel = $connection.create_channel
  bank_reply = channel.queue(BANK_REPLY)

  puts ' [*] Waiting for bank replies'
  bank_reply.subscribe(block: true) do |_delivery_info, _properties, body|
    payload = JSON.parse(body, symbolize_names: true)
    puts " [>] Bank Reply: Received #{payload}"

    # Push the body (JSON string) to Redis using the Correlation ID as Key
    num_bank_replied = redis.lpush(payload[:correlation_id], body)
    puts " [*] Persisted offer in storage (#{num_bank_replied} of " \
         "#{payload[:expected_bank_replies]}) for #{payload[:correlation_id]}"

    if num_bank_replied == payload[:expected_bank_replies]
      # https://redis.io/commands/lrange#consistency-with-range-functions-in-various-programming-languages
      redis_last_element_index = payload[:expected_bank_replies] - 1

      offers = redis
               .lrange(payload[:correlation_id], 0, redis_last_element_index)
               .map { |offer| JSON.parse(offer, symbolize_names: true) }

      puts " [<] All offers received, sending to translator"
      Translator.new(offers).call
    end
  end
end
