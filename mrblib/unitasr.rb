# M5Unit-ASR voice recognition module driver for PicoRuby
class UnitASR
  # Maximum size of the receive buffer to prevent memory overflow
  BUFFER_MAX_SIZE = 20
  # Startup delay in milliseconds for module initialization
  STARTUP_DELAY_MS = 3000
  # Command number indicating the module has woken up
  WAKEUP_CMD = 0xFF
  
  # Initialize the UnitASR module with a UART interface
  # @param uart [Object] UART communication interface
  def initialize(uart)
    @uart = uart                          # UART communication interface
    @rx_buffer = []                       # Receive buffer for incoming data
    @command_handlers = {}                # Hash mapping command numbers to handler blocks
    @unknown_handler = Proc.new { |cmd_num| }  # Handler for unknown commands
    @current_command_num = nil            # Last recognized command number
    @is_awake = false                     # Module wake state flag
    
    initialize_module
  end
  
  # Register a handler block for a specific voice command number
  # @param cmd_num [Integer] Command number to handle
  # @param block [Proc] Block to execute when command is recognized
  def on(cmd_num, &block)
    @command_handlers[cmd_num] = block
  end
  
  # Register a handler block for unknown/unregistered commands
  # @param block [Proc] Block to execute for unknown commands
  def on_unknown(&block)
    @unknown_handler = block
  end
  
  # Update method to process incoming data and parse commands
  # Should be called regularly in the main loop
  def update
    receive_data
    parse_packets
  end
  
  # Get the most recently recognized command number
  # @return [Integer, nil] Command number or nil if no command recognized
  def current_command_num
    @current_command_num
  end
  
  # Check if the module is awake and ready to receive commands
  # @return [Boolean] True if module is awake, false otherwise
  def awake?
    @is_awake
  end
  
  # Get the current size of the receive buffer
  # @return [Integer] Number of bytes in the buffer
  def buffer_size
    @rx_buffer.length
  end
  
  private
  
  # Initialize the UnitASR module with proper timing and buffer clearing
  # Includes initial delay and startup sequence required by the hardware
  def initialize_module
    sleep_ms(100)
    sleep_ms(STARTUP_DELAY_MS)
    @uart.clear_rx_buffer if @uart.respond_to?(:clear_rx_buffer)
  end
  
  # Read incoming data from UART and store in receive buffer
  # Maintains buffer size limit to prevent memory overflow
  def receive_data
    while @uart.bytes_available > 0
      data = @uart.read(1)
      if data && data.length == 1
        @rx_buffer.push(data[0].ord)
      end
      
      if @rx_buffer.length > BUFFER_MAX_SIZE
        @rx_buffer.shift
      end
    end
  end
  
  # Parse the receive buffer for valid command packets
  # Extracts command numbers and triggers appropriate handlers
  def parse_packets
    cmd = find_and_parse_packet
    
    if cmd
      @current_command_num = cmd
      handle_command(cmd)
    end
  end
  
  # Search for and extract command packets from the receive buffer
  # Packet format: 0xAA 0x55 [CMD] 0x55 0xAA
  # @return [Integer, nil] Command number if valid packet found, nil otherwise
  def find_and_parse_packet
    return nil if @rx_buffer.length < 5
    
    i = 0
    while i <= @rx_buffer.length - 5
      if @rx_buffer[i] == 0xAA && @rx_buffer[i + 1] == 0x55
        if @rx_buffer[i + 3] == 0x55 && @rx_buffer[i + 4] == 0xAA
          cmd = @rx_buffer[i + 2]
          (i + 5).times { @rx_buffer.shift }
          return cmd
        end
      end
      i += 1
    end
    
    if @rx_buffer.length > 10
      5.times { @rx_buffer.shift }
    end
    
    nil
  end
  
  # Process a recognized command by calling appropriate handlers
  # Updates wake state for wakeup commands and executes registered callbacks
  # @param cmd [Integer] Command number to handle
  def handle_command(cmd)
    if cmd == WAKEUP_CMD
      @is_awake = true
    end
    
    if @command_handlers[cmd]
      @command_handlers[cmd].call
    else
      @unknown_handler.call(cmd)
    end
  end
end
