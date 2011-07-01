$: << '../../lib/'
require 'mgframework/server'

module Chess

  class GameController
    attr_reader :state, :fiber, :players
    
    def initialize
      new_game
    end
    
    def new_game
      @fiber = Fiber.new do
        @state = :none
        @players = []
        
        # Lobby
        @state = :waiting_for_players
        while @players.size < 2
          @players.each { |player| player.simple_send :lobby_waiting_for_other_players }
          new_palyer = Fiber.yield
          @players.each { |player| player.simple_send :lobby_player_joined }
          @players << new_palyer
          new_palyer.simple_send :greet
        end
        
        # Preloading some info (nicknames etc)
        @state = :loading_prestart_info
        @players.each { |player| player.simple_send :send_prestart_info }
        Fiber.yield until @players.all? { |player| !!player.info }
        
        
        # Place figures and do init and etc kind of stuff
        @state = :loading
        
        
        @state = :playing        
        @players.each { |player| player.simple_send :game_start }
        
        game_ended = false
        until game_ended
          # Here we process player's turn or timeout
          Fiber.yield
          
          # DEBUG!!!
          game_ended = true
        end
        
        
        @players.each { |player| player.simple_send :game_finish }
        @state = :finished
      end
      
      # To make the first step
      @fiber.resume
    end
    
    def player_disconnected player
      @players.delete(player)
      @players.each{ |player| player.close_with_error "Opponent disconnected!" } if @state != :waiting_for_players
      new_game
    end
  end

  class ClientController < MGF::Client
    @@game = GameController.new
    
    def info
      @info ||= nil
    end
    
    def on_connected      
      if @@game.state == :waiting_for_players
        @@game.fiber.resume self
      else
        close_with_error "Already playing!"
      end
    end
    
    def on_disconnected
      @@game.player_disconnected self if @@game.players.member? self
    end
    
    def handle_get_state packet
      send :gamestate, @@game.state
    end
    
    def handle_move packet
      p packet
    end
    
    def handle_prestart_info packet
      terminate unless @@game.state == :loading_prestart_info
      @info ||= {}
      @info.merge! packet
      @@game.fiber.resume
    end
    
    def handle_chat_message packet
      new_packet = MGF::UniversalPacket.new :chat
      new_packet[:msg] = packet['msg']
      new_packet[:player] = self.connection_id
      @@game.players.each do |player|
        player.send new_packet
      end
    end
    
  end

end

MGF::Server.instance.run Chess::ClientController
