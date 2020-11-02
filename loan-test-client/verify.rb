# frozen_string_literal: true

# https://github.com/ddollar/foreman/wiki/Missing-Output
$stdout.sync = true

require 'bunny'
require 'json'

connection = Bunny.new
connection.start

channel = connection.create_channel
loan_reply = channel.queue('loanReplyQueue')

begin
  puts ' [*] Waiting for loan replies'

  loan_reply.subscribe(block: true) do |_delivery_info, _properties, body|
    payload = JSON.parse(body, symbolize_names: true)
    puts " [>] Received #{payload}"
  end
rescue Interrupt => _e
  connection.close
end
