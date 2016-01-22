require 'open-uri'

module ItemsLoader
    
    class ItemsLoader
        def initialize partner
            @partner = partner
        end
        
        def run
            open(@partner.xml_url) do |stream|
                parse(stream)
            end
        end
        
        private
        
        def parser loader
            ::ItemsLoader::Parsers.const_get("#{@partner.xml_type}Parser").new  loader
        end

        def parse xml_stream
            conn = ActiveRecord::Base.connection
            raw = conn.raw_connection
            raw.exec 'CREATE TEMP TABLE source(LIKE items INCLUDING ALL) ON COMMIT DROP;'
            raw.copy_data "COPY source (partner_id, title, partner_item_id, availiable_in_store, created_at, updated_at) FROM STDIN CSV" do
                template = "#{@partner.id},%{title},%{partner_item_id},%{availiable_in_store},now(),now()\n"
                ::Nokogiri::XML::SAX::Parser.new(parser lambda { |item| raw.put_copy_data (template % item)}).parse(xml_stream) 
            end
            raw.exec <<-SQL
            UPDATE items t
               SET availiable_in_store = s.availiable_in_store, title = s.title, updated_at = now()
              FROM source s 
             WHERE t.partner_id = s.partner_id and t.partner_item_id = s.partner_item_id and s.availiable_in_store = true;
            SQL
            
            raw.exec <<-SQL
            UPDATE items t
               SET availiable_in_store = s.availiable_in_store, updated_at = now()
              FROM source s 
             WHERE t.partner_id = s.partner_id and t.partner_item_id = s.partner_item_id and s.availiable_in_store = false;
            SQL
            
            raw.exec <<-SQL
            INSERT INTO items(partner_id, partner_item_id, title, availiable_in_store, created_at, updated_at)
             SELECT s.partner_id, s.partner_item_id, s.title, s.availiable_in_store, s.created_at, s.updated_at
               FROM source s LEFT JOIN items t USING(partner_id, partner_item_id)
              WHERE t.partner_item_id IS NULL;
            SQL
            
            raw.exec 'COMMIT;'
        end
    end
end