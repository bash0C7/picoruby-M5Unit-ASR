# picoruby-unitasr

A pure Ruby implementation of [M5Unit-ASR](https://docs.m5stack.com/ja/unit/Unit%20ASR) driver for PicoRuby.

## Installation

Add this line to your PicoRuby build configuration (`picoruby/build_config/xtensa-esp.rb`):

```ruby
conf.gem github: 'bash0C7/picoruby-m5unit-asr', branch: 'main'
```

## Dependencies

- `picoruby-uart`: (included in PicoRuby)

## Quick Start

```ruby
require 'unitasr'
require 'uart'

asr = UnitASR.new(UART.new(unit: :ESP32_UART1, baudrate: 115200, txd_pin: 26, rxd_pin: 32))

# Register command handlers
asr.on(0x17) { puts "pause detected" }
asr.on(0x30) { puts "ok detected" }
asr.on_unknown { |cmd| puts "unknown command: #{cmd}" }

loop do
  asr.update
  sleep_ms 50
end
```

## API Reference

### Initialization

```ruby
asr = UnitASR.new(uart_instance)
```

### Methods

- `on(cmd_num, &block)` - Register a handler for a specific command number
- `on_unknown(&block)` - Register a handler for unknown commands
- `update` - Check for incoming commands and execute handlers

For a complete list of preset voice recognition commands and their corresponding command numbers, refer to the [UNIT-ASR Command Reference](https://m5stack-doc.oss-cn-shenzhen.aliyuncs.com/635/UNIT-ASR-Command_EN.pdf).

## Complete Example

This example demonstrates voice command recognition using the M5Unit-ASR:

```ruby
require 'unitasr'
require 'uart'

UART_TX = 26
UART_RX = 32

asr = UnitASR.new(UART.new(unit: :ESP32_UART1, baudrate: 115200, txd_pin: UART_TX, rxd_pin: UART_RX))

asr.on(0x17) do
  puts "Command: pause"
end

asr.on(0x30) do
  puts "Command: ok"
end

asr.on(0x10) do
  puts "Command: open"
end

asr.on_unknown do |cmd|
  puts "Unknown command: 0x#{cmd.to_s(16)}"
end

loop do
  asr.update
  sleep_ms 50
end
```


## License

MIT