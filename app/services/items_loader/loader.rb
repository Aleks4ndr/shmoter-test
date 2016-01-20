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
            item_id = item.delete :partner_item_id
            item[:created_at] = DateTime.now
            item[:updated_at] = DateTime.now
            @insert_items.push [{:partner_id => @partner.id, :partner_item_id => item_id}, item] 
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
        #conn = ActiveRecord::Base.connection
        #conn.execute('create table items_temp')
        Upsert.batch(Item.connection, Item.table_name) do |upsert|
            @update_items.each { |item| upsert.row(*item) }
        end
    end
    def insert_items
        Upsert.batch(Item.connection, Item.table_name) do |upsert|
            @insert_items.each { |item| upsert.row(*item) }
        end
        #items = []
        #@insert_items.each { |item| items << Item.new(item) }
        #Item.import items
    end
    
    def update_availability
        Item.where(id: @update_availiable).update_all(:availiable_in_store => false)
    end
    
    def existing_items
        @existing_item_ids ||= (@partner.items.pluck :partner_item_id, :id).to_h
    end
end