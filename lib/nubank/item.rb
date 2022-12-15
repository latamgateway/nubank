class Nubank
  class Item < Struct.new(
    :id,
    :value,
    :quantity,
    :description,
    keyword_init: true,
  )
  end
end
