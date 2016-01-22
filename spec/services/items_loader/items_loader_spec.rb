require 'rails_helper'
require 'tempfile'
describe ItemsLoader::ItemsLoader do
    context 'success' do
        
       let(:data) do
           data = Tempfile.new('foo')
           data.write <<-EOF
<items>
	<item available="true" id="123">
		<title>Рубашка</title>
	</item>
	<item available="false" id="1234">
		<title>Джинсы</title>
	</item>
	<item available="true" id="1235">
		<title>Юбка</title>
	</item>
</items>
            EOF

            data.close
            data
       end
       
       let(:partner) { FactoryGirl.create(:partner, xml_url: data.path) }
       
       let (:items) do
            partner.items.create!(availiable_in_store: true, partner_item_id: 1234, title: 'Не Джинсы')
            partner.items.create!(availiable_in_store: false, partner_item_id: 1235, title: 'Не Юбка')
            partner_items_loader = ItemsLoader::ItemsLoader.new partner
            partner_items_loader.run
            partner.items
        end

       it 'insert only necessary data' do
           expect(items.size).to eq(3)
       end

       it 'correctly insert new item' do
            item = partner.items.build(availiable_in_store: true, partner_item_id: 123, title: 'Рубашка')
            expect(items.find_by(partner_item_id: item.partner_item_id)).to have_same_attributes_as(item)
       end
       
       it 'correctly update new item' do
            item = partner.items.build(availiable_in_store: true, partner_item_id: 1235, title: 'Юбка')
            expect(items.find_by(partner_item_id: item.partner_item_id)).to have_same_attributes_as(item)
       end
       it 'update only availiable_in_store attribute if item is not availiable now' do
            item = partner.items.build(availiable_in_store: false, partner_item_id: 1234, title: 'Не Джинсы')
            expect(items.find_by(partner_item_id: item.partner_item_id)).to have_same_attributes_as(item)
       end
    end
end
