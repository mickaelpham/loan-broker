# frozen_string_literal: true

# https://github.com/ddollar/foreman/wiki/Missing-Output
$stdout.sync = true

require 'bunny'
require 'json'

# Ingress/Egress queues for loan broker
LOAN_REQUEST = 'loanRequestQueue'
LOAN_REPLY = 'loanReplyQueue'

# Ingress/Egress queues for credit bureau subsystem
CREDIT_REQUEST = 'creditRequestQueue'
CREDIT_REPLY = 'creditReplyQueue'

# Ingress queue shared for all bank replies
BANK_REPLY = 'bankReplyQueue'

# Connect to RabbitMQ (every process will use the same connection
# but spawn a different channel)
$connection = Bunny.new
$connection.start

require_relative 'content_enricher'
require_relative 'recipient_list'

begin
  loop { sleep 5 }
rescue Interrupt => _e
  puts ' [X] Terminating all threads for loan-broker application'
  $connection.close
end
