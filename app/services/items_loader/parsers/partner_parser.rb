class ItemsLoader::Parsers::PartnerParser < Nokogiri::XML::SAX::Document
    def initialize loader
        @loader = loader
    end
        
    def	start_element(name,	attrs = [])
        case name
            when 'item'
                @entry = attrs.map { |k,v| [k.to_sym, v] }.to_h
                @entry[:availiable_in_store] = @entry.delete :available
                @entry[:partner_item_id] = @entry.delete :id
            when 'title'
                @in_title = true
        end
    end
    def	characters(string)
        if @in_title
            @entry[:title] = string 
            @in_title = false
        end
    end
    def	end_element(name)
        @loader.call @entry if name == 'item'
    end
end
