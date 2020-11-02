# frozen_string_literal: true

class Translator
  attr_reader :offers

  def initialize(offers)
    @offers = offers
  end

  def call; end
end
