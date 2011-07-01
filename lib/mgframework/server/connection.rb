require 'mgframework/server/packet'

module MGF
  class Connection
    class ProtocolException < Exception; end
    class ProtoStopper < Exception; end
    
    @@connections_counter = 0
    
    public
    
    attr_reader :connection_id
    
    def initialize socket
      @socket = socket
      Server.log.debug "New connection created"
      @connection_id = (@@connections_counter+=1)
    end
    
    def parse_packet data
      begin
        packet = JSON.parse data
      rescue
        close_with_error "Wrong packet format"
        return
      end
      
      if !packet['type'] || !packet['type'] =~ /\A[a-z_]+\z/
        close_with_error "Unallowed packet type"
        return
      end
      
      methname = "handle_#{packet['type']}"
      unless respond_to? methname
        Server.log.error "Undefined packet type: #{methname}"
        close
        return
      end
      #packet = Packet.new packet['type'], packet
      begin		
        __send__(methname, packet)
      rescue ProtocolException => e
        close_with_error e.to_s
      rescue ProtoStopper => e
        # nothing
      end
    end
    
    def simple_send packet
      packet = [packet.to_s]
      send packet
    end
    
    def send *packet      
      packet = packet[0] if packet.size == 1
      
      if packet.kind_of? Packet
        packet = packet.pack
      else		
        if packet.kind_of? Array
          if packet.size == 2
            packet = { :type => packet[0], :info => packet[1] }
          elsif packet.size == 1
            packet = { :type => packet[0] }
          else
            raise 'Packet generation error: Array can contain only 1 or 2 elements'
          end
        end
        
        packet = packet.to_json if packet.kind_of? Hash
      end
      
      @socket.send packet
    end
    
    def event_connected
      on_connected if respond_to? :on_connected
    end
    
    def event_disconnected
      on_disconnected if respond_to? :on_disconnected
    end
    
    def close_with_error text
      send Hash[ :type => 'error', :details => text ]
      close true
    end
    
    def close after_writing = false
      @socket.close_connection after_writing
    end
    
    # Ommits remaining actions in protocol handler
    def stop # must be called only from packet handlers
      raise ProtoStopper
    end
    
    # Closes the connction with error message
    def stop_with_error text # must be called only from packet handlers
      raise ProtocolException, text
    end
    
    def terminate text="Unstable activity"
      stop_with_error text
    end	
    
    def get_ip
      Socket.unpack_sockaddr_in(@socket.get_peername)[1]
    end
  end
end