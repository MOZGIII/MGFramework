module MGF
  class Packet
    attr_reader :type
    
    def initialize type
      @type = type
    end
    
    # Should be redefined in subclasses
    def pack
      { :type => @type }.to_json
    end
    
    def to_s
      pack
    end
  end

  class UniversalPacket < Packet
    attr_reader :data

    def initialize type, data = {}
      super type
      @data = data
      @data['type'] = @type
    end
    
    def [](key)
      @data[key]
    end
    
    def []=(key, val)
      return if key == 'type'
      @data[key] = val
    end
      
    def pack
      @data['type'] = @type
      @data.to_json
    end
  end
end