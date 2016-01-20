
require 'rails_helper'

describe ItemsLoader::Loader do
    #@partner = double(:partner)
    let(:partner) { FactoryGirl.create(:partner)}
    let(:loader)  { ItemsLoader::Loader.new(partner) }
    let(:item)    { { :availiable_in_store=>"true", :partner_item_id=>"123", :title=>"Рубашка" } }
   
    it 'inserts item' do
        loader.enqueue item
        loader.load
        item = partner.items.build(item)
        expect(partner.items).to include(item)
    end
    
    it 'updates items' do
        existing_item = partner.items.create!( :availiable_in_store=>"true", :partner_item_id=>"123", :title=>"Джинсы" )
        loader.enqueue item
        loader.load
        expect(existing_item.reload.title).to eq(item[:title])
    end
    
    it 'not update title if item does not availiable any more' do
        existing_item = partner.items.create!( :availiable_in_store=>"true", :partner_item_id=>"123", :title=>"Джинсы" )
        item[:availiable_in_store] = false
        loader.enqueue item
        loader.load
        expect(existing_item.reload.title).not_to eq(item[:title])
    end
    
     it 'update availiability if item does not availiable any more' do
        existing_item = partner.items.create!( :availiable_in_store=>"true", :partner_item_id=>"123", :title=>"Джинсы" )
        item[:availiable_in_store] = false
        loader.enqueue item
        loader.load
        expect(existing_item.reload.availiable_in_store).to be false
    end
end
