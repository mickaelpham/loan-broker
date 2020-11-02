# frozen_string_literal: true

class Translator
  attr_reader :offers, :channel

  def initialize(offers, channel)
    @offers = offers
    @channel = channel
  end

  def call
    puts " [>] Received #{offers.size} offers, applying best offer"
    reply_with(best_offer)
  end

  private

  def best_offer
    offers
      .select { |offer| offer[:approved] }
      .min_by { |offer| offer[:interest_rate] }
  end

  def reply_with(offer)
    puts " [<] Replying with offer #{offer}"
    channel.default_exchange.publish(offer.to_json, routing_key: LOAN_REPLY)
  end
end
