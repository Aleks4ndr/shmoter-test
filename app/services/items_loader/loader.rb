class ItemsLoader::Loader
    MAX_QUEUE_LENGTH = 100_000
    def initialize partner
        @partner = partner
        @insert_items = []
        @update_items = []
        @update_availiable = []
        @items = []
        
        
    end
    
    
    ##
    #  enqueue item in load queue 
    #  items is hash with keys:
    #    :availiable_in_store
    #    :partner_item_id
    #    :title
    def enqueue item
        if id = existing_items[item[:partner_item_id]]
            if item[:availiable_in_store] == 'true'
                @update_items.push [{:id => id}, item]
            else
                @update_availiable.push id
            end
        else
            item[:partner_id] = @partner.id
            @insert_items.push item
        end
    end
    
    def prepare_to_update item
        if item[:availiable_in_store]
            item
        else
            item[:id]
        end
    end
    
    def load
        update_items
        update_availability
        insert_items
    end
    
    def update_items
        Upsert.batch(Item.connection, Item.table_name) do |upsert|
            @update_items.each { |item| upsert.row(*item) }
        end
    end
    def insert_items
        items = []
        @insert_items.each { |item| items << Item.new(item) }
        Item.import items
    end
    
    def update_availability
        Item.where(id: @update_availiable).update_all(:availiable_in_store => false)
    end
    
    def existing_items
        @existing_item_ids ||= (@partner.items.pluck :partner_item_id, :id).to_h
    end
end