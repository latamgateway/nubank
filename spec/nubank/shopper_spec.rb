require_relative "../../lib/nubank/shopper"
require_relative "../../lib/nubank/phone"

RSpec.describe Nubank::Shopper do
  let(:shopper) do
    Nubank::Shopper.new(
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      document: document,
      email: Faker::Internet.email,
      phone: Nubank::Phone.new(country: "55", number: "21987654321"),
    )
  end

  describe :document do
    context "with formatting" do
      context "CPF" do
        let(:document) do
          Faker::IDNumber.brazilian_citizen_number(formatted: true)
        end

        it "removes formatting" do
          expect(shopper.document).to eq(CPF.new(document).stripped)
        end
      end

      context "CNPJ" do
        let(:document) do
          Faker::Company.brazilian_company_number(formatted: true)
        end

        it "removes formatting" do
          expect(shopper.document).to eq(CNPJ.new(document).stripped)
        end
      end
    end
  end

  describe :document_type do
    context "CPF" do
      let(:document) do
        Faker::IDNumber.brazilian_citizen_number(
          formatted: Faker::Boolean.boolean,
        )
      end

      it { expect(shopper.document_type).to eq("CPF") }
    end

    context "CNPJ" do
      let(:document) do
        Faker::Company.brazilian_company_number(
          formatted: Faker::Boolean.boolean,
        )
      end

      it { expect(shopper.document_type).to eq("CNPJ") }
    end
  end

  context "with invalid document" do
    let(:document) { "123" }
    let(:error) { "Invalid document (document: #{document.inspect})!" }

    describe :document do
      it "raises an error" do
        expect { shopper.document }.to raise_error(error)
      end
    end

    describe :document_type do
      it "raises an error" do
        expect { shopper.document_type }.to raise_error(error)
      end
    end
  end
end
