require "cpf_cnpj"

class Nubank
  class Shopper < Struct.new(
    :first_name,
    :last_name,
    :document,
    :email,
    :phone,
    keyword_init: true,
  )
    def document
      case
      when CPF.valid?(super)
        CPF.new(super).stripped
      when CNPJ.valid?(super)
        CNPJ.new(super).stripped
      else
        raise "Invalid document (document: #{super.inspect})!"
      end
    end

    def document_type
      case
      when CPF.valid?(document)
        "CPF"
      when CNPJ.valid?(document)
        "CNPJ"
      else
        raise "Unknown document type (document: #{document.inspect})!"
      end
    end
  end
end
