require 'open-uri'

module ItemsLoader
    
    class ItemsLoader
        def initialize partner
            @partner = partner
            @loader = Loader.new partner
        end
        
        def run
           
            parse_file
            load_items

        end
        
        private
        
        def parse_file
            stream = open(@partner.xml_url)
            
            @items = parse(stream)
        end
        
        def load_items
        end
        
        def parser
            ::ItemsLoader::Parsers.const_get("#{@partner.xml_type}Parser").new  @loader
        end
        
        def parse xml_stream
            Nokogiri::XML::SAX::Parser.new(parser).parse(xml_stream)
        end
  
  
    end
end