require 'open-uri'

module ItemsLoader
    
    class ItemsLoader
        def initialize partner
            @partner = partner
            @loader = Loader.new partner
        end
        
        def run
           
            parse_file
            #load_items

        end
        
        private
        
        def parse_file
            stream = open(@partner.xml_url)
            
            parse(stream)
        end
        
        def load_items
        conn = ActiveRecord::Base.connection
        raw = conn.raw_connection
        raw.exec 'BEGIN;'
        raw.exec 'CREATE TEMP TABLE source(LIKE items INCLUDING ALL) ON COMMIT DROP;'
        raw.copy_data "COPY source (partner_id, title, partner_item_id, availiable_in_store, created_at, updated_at) FROM STDIN CSV" do
            
            raw.put_copy_data "1,Apple,123,t,now(),now()\n"
        end
        raw.exec 'COMMIT;'
=begin        
data = {
    category: 'test',
    person_id: 1
}

template = "UPDATE `table` SET person_id = %{person_id}, category = '%{category}' WHERE category = '%{category}--%{person_id}';"

template % data
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
        end
        
        def parser loader
            ::ItemsLoader::Parsers.const_get("#{@partner.xml_type}Parser").new  loader
        end

        def parse xml_stream
            conn = ActiveRecord::Base.connection
            raw = conn.raw_connection
            #raw.exec 'BEGIN;' "1,Apple,123,t,now(),now()\n"
            raw.exec 'CREATE TEMP TABLE source(LIKE items INCLUDING ALL) ON COMMIT DROP;'
            raw.copy_data "COPY source (partner_id, title, partner_item_id, availiable_in_store, created_at, updated_at) FROM STDIN CSV" do
                template = "#{@partner.id},%{title},%{partner_item_id},%{availiable_in_store},now(),now()\n"
                #raw.put_copy_data "1,Apple,123,t,now(),now()\n"
                ::Nokogiri::XML::SAX::Parser.new(parser lambda { |item| raw.put_copy_data (template % item)}).parse(xml_stream) 
            end
            
            raw.exec <<-SQL
            UPDATE items t
               SET availiable_in_store = s.availiable_in_store, title = s.title
              FROM source s 
             WHERE t.partner_id = s.partner_id and t.partner_item_id = s.partner_item_id;
            SQL
            
            raw.exec <<-SQL
            INSERT INTO items(partner_id, partner_item_id, title, availiable_in_store, created_at, updated_at)
             SELECT s.partner_id, s.partner_item_id, s.title, s.availiable_in_store, s.created_at, s.updated_at
               FROM source s LEFT JOIN items t USING(partner_id, partner_item_id)
              WHERE t.partner_item_id IS NULL;
            SQL
            
            raw.exec 'COMMIT;'
            #Nokogiri::XML::SAX::Parser.new(parser).parse(xml_stream)
        end
  
  
    end
end