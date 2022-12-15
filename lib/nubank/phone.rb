class Nubank
  class Phone < Struct.new(:country, :number, keyword_init: true)
  end
end
