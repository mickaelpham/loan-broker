# frozen_string_literal: true

BANKS_DB = %w[
  bank1
  bank2
  bank3
  bank4
  bank5
].freeze

BANK_RECIPIENT_LIST_BASED_ON_MAX_CREDIT_SCORE = {
  650 => BANKS_DB[0..2],
  750 => BANKS_DB[1..3],
  850 => BANKS_DB[2..4]
}.freeze

def bank_recipients(credit_score)
  BANK_RECIPIENT_LIST_BASED_ON_MAX_CREDIT_SCORE.each do |upto_score, banks|
    return banks if credit_score <= upto_score
  end

  raise "No Banks Found for credit score: #{credit_score}"
end
