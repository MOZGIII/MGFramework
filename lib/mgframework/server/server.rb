# Global requirements
require 'em-websocket'
require 'logger'
require 'json'
require 'singleton'

# Local requirements
require 'mgframework/server/client'

module MGF
  class Server
    include Singleton
    
    class Clients < Hash    
      def add client
        self[client.connection_id] = client
      end
      
      def remove client
        if client.kind_of? Integer
          self.delete client
        else        
          self.delete client.connection_id
        end
      end
      
      def send_all packet
        
      end
    end
    
    def self.log
      instance.log # use singleton here
    end
    
    def log
      @log ||= Logger.new(STDERR).tap { |l| l.level = Logger::WARN }
    end
    
    def initialize
      @options = {
        host: '0.0.0.0',
        port: 26708
      }
    end
    
    def configure options
      @options.merge! options
    end
    
    def clients
      @clients ||= Clients.new
    end
    
    def run client_class = Client
      raise "Your controller must be derived from MGF::Client!" unless client_class == Client || derived_from_class?(client_class, Client)
      
      EM.run do
        
        EM::WebSocket.start(:host => @options[:host], :port => @options[:port], :debug => false) do |ws|
          connection = client_class.new ws
          
          ws.onopen do
            log.info "WebSocket opened"
            connection.event_connected if connection
            clients.add connection
          end
          
          ws.onmessage do |msg|
            log.debug "Incoming: #{msg}"
            connection.parse_packet msg
            #ws.send "Pong: #{msg}"
          end
          
          ws.onclose do
            log.info "WebSocket closed"
            connection.event_disconnected if connection
            clients.remove connection
            connection = nil
          end
        end
        
      end    
    end
    
    private
    
    def derived_from_class? klass, superklass
      k = klass
      while k = k.superclass
        return true if superklass == k
      end
      false
    end
  end
end