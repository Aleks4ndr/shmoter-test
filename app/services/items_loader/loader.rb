require 'open-uri'

class ItemsLoader::Loader
    MAX_QUEUE_LENGTH = 100_000
    def initialize partner
        @partner = partner
        @insert_items = []
        @update_items = []
        @update_availiable = []
        @items = []
    end
        
=begin
        conn.execute 'select * from source;'
        #@raw.exec 'CREATE TEMP TABLE source(LIKE items INCLUDING ALL) ON COMMIT DROP;'
        #raw.exec 'select * from source;'
        result = raw.exec 'select * from items;'
        result.values
        raw.exec 'ABORT;'
        conn = ActiveRecord::Base.connection
        raw = conn.raw_connection
        raw.exec 'BEGIN;'
        raw.exec 'CREATE TEMP TABLE source(LIKE items INCLUDING ALL) ON COMMIT DROP;'
        raw.copy_data "COPY source (partner_id, title, partner_item_id, availiable_in_store, created_at, updated_at) FROM STDIN CSV" do
            raw.put_copy_data "1,Apple,123,t,now(),now()\n"
        end
        
        #
        #raw.exec 'COMMIT;'
        
        id | partner_id |  title   | partner_item_id | availiable_in_store |         created_at         |         updated_at  
        
=end
    
    
     def load_items
            
        conn = ActiveRecord::Base.connection
        raw = conn.raw_connection
        raw.exec 'BEGIN;'
        raw.exec 'CREATE TEMP TABLE source(LIKE items INCLUDING ALL) ON COMMIT DROP;'
        raw.copy_data "COPY source (partner_id, title, partner_item_id, availiable_in_store, created_at, updated_at) FROM STDIN CSV" do
            
            raw.put_copy_data "1,Apple,123,t,now(),now()\n"
        end
=begin        
        WITH upd AS (
        raw.exec <<SQL
            UPDATE items t
               SET availiable_in_store = s.availiable_in_store, title = s.title
              FROM source s 
             WHERE t.partner_id = s.partner_id and t.partner_item_id = s.partner_item_id;
         RETURNING s.id
        )
        INSERT INTO items(partner_id, partner_item_id, title, availiable_in_store, created_at, updated_at)
             SELECT partner_id, partner_item_id, title, availiable_in_store, created_at, updated_at
               FROM source s LEFT JOIN target t USING(partner_id, partner_item_id)
              WHERE t.id IS NULL
           GROUP BY s.id
          RETURNING t.id
=end        
        raw.exec 'COMMIT;'
    end
        
        def parser
            ::ItemsLoader::Parsers.const_get("#{@partner.xml_type}Parser").new  @loader
        end
        
        def parse
            stream = open(@partner.xml_url)
            
            Nokogiri::XML::SAX::Parser.new(parser).parse(xml_stream)
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