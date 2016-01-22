require 'rails_helper'
require 'stringio'
require 'tempfile'
describe ItemsLoader::Parsers::PartnerParser do
    context 'success' do
       let(:loader) { double(:loader) }
       
       it 'parse data from a file and pass it to loader' do
           data = Tempfile.new('foo')
           data.write(<<EOF
<items>
	<item available="true" id="123">
		<title>Рубашка</title>
	</item>
</items>
EOF
)
            data.rewind
            parser = ItemsLoader::Parsers::PartnerParser.new loader
            #expect(loader).to receive(:enqueue).with({:availiable_in_store=>"true", :partner_item_id=>"123", :title=>"Рубашка"})
            expect(loader).to receive(:call).with({:availiable_in_store=>"true", :partner_item_id=>"123", :title=>"Рубашка"})
            Nokogiri::XML::SAX::Parser.new(parser).parse(data)
        end
    end
end