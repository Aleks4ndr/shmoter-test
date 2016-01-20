FactoryGirl.define do
  factory :item do
    association :partner
    title "Banana"
    partner_item_id "MyString"
    availiable_in_store false
  end

end
