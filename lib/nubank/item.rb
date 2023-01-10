class Nubank
  class Item < Struct.new(
    :id,
    :value,
    :quantity,
    :description,
    keyword_init: true,
  )
    def value
      Float(super)
    end
  end
end
