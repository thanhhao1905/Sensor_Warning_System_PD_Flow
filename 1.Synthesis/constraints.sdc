# ==============================================
# Timing Constraints for top_complete Module
# ==============================================

# -------------------- Clock Definition --------------------
# Main clock: 40MHz (period = 25ns for 40MHz, but your example uses 10ns for 100MHz)
# Adjust based on actual clock frequency
create_clock -name clk -period 25.0 [get_ports clk]
set_clock_uncertainty -setup 0.2 [get_clocks clk]
set_clock_uncertainty -hold 0.05 [get_clocks clk]

# -------------------- Reset Signal --------------------
# Asynchronous reset with recovery/removal timing
set_input_delay -clock clk -max 2.0 [get_ports rst_n]
set_input_delay -clock clk -min 0.5 [get_ports rst_n]
set_false_path -from [get_ports rst_n] -setup
set_false_path -from [get_ports rst_n] -hold

# -------------------- DHT11 Bidirectional Pin --------------------
# Input timing for dht_pin when reading
set_input_delay -clock clk -max 3.0 [get_ports dht_pin]
set_input_delay -clock clk -min 1.0 [get_ports dht_pin]

# Output timing for dht_pin when writing
set_output_delay -clock clk -max 3.0 [get_ports dht_pin]
set_output_delay -clock clk -min 1.0 [get_ports dht_pin]

# -------------------- LCD I2C Pins --------------------
# SCL - clock output
set_output_delay -clock clk -max 2.5 [get_ports scl]
set_output_delay -clock clk -min 0.8 [get_ports scl]

# SDA - bidirectional
set_input_delay -clock clk -max 2.5 [get_ports sda]
set_input_delay -clock clk -min 0.8 [get_ports sda]
set_output_delay -clock clk -max 2.5 [get_ports sda]
set_output_delay -clock clk -min 0.8 [get_ports sda]

# -------------------- UART Pins --------------------
# UART TX - output to ESP32 (baud rate 9600 -> ~104us period, relaxed timing)
set_output_delay -clock clk -max 5.0 [get_ports uart_tx]
set_output_delay -clock clk -min 1.0 [get_ports uart_tx]

# UART RX - input from ESP32
set_input_delay -clock clk -max 5.0 [get_ports rx]
set_input_delay -clock clk -min 1.0 [get_ports rx]

# -------------------- HC595 LED 7-Segment Pins --------------------
# SPI-like interface to shift register
set_output_delay -clock clk -max 2.0 [get_ports SCLK]
set_output_delay -clock clk -min 0.5 [get_ports SCLK]

set_output_delay -clock clk -max 2.0 [get_ports RCLK]
set_output_delay -clock clk -min 0.5 [get_ports RCLK]

set_output_delay -clock clk -max 2.0 [get_ports DIO]
set_output_delay -clock clk -min 0.5 [get_ports DIO]

# -------------------- Fire Alarm System Inputs --------------------
# Warning button (asynchronous, debounced in hardware)
set_input_delay -clock clk -max 3.0 [get_ports warning_btn]
set_input_delay -clock clk -min 1.0 [get_ports warning_btn]

# -------------------- Fire Alarm System Outputs --------------------
# LED outputs (8-bit)
set_output_delay -clock clk -max 2.0 [get_ports {led[*]}]
set_output_delay -clock clk -min 0.5 [get_ports {led[*]}]

# Buzzer output
set_output_delay -clock clk -max 2.0 [get_ports buzzer]
set_output_delay -clock clk -min 0.5 [get_ports buzzer]

# Warning status outputs
set_output_delay -clock clk -max 2.0 [get_ports warning_enabled]
set_output_delay -clock clk -min 0.5 [get_ports warning_enabled]

set_output_delay -clock clk -max 2.0 [get_ports warning_led]
set_output_delay -clock clk -min 0.5 [get_ports warning_led]

set_output_delay -clock clk -max 2.0 [get_ports sim]
set_output_delay -clock clk -min 0.5 [get_ports sim]

# -------------------- Load Capacitance --------------------
# Set load capacitance for output pins (typical 5-15pF for FPGA pins)
set_load 0.010 [all_outputs]

# -------------------- Transition Time Constraints --------------------
# Maximum transition time for all signals
set_max_transition 1.0 [current_design]
set_max_fanout 20 [current_design]

# -------------------- False Paths (optional) --------------------
# If warning_btn is asynchronous and debounced in hardware
set_false_path -from [get_ports warning_btn]

# If any outputs don't need strict timing (e.g., LEDs, buzzer)
# set_false_path -to [get_ports {led[*] buzzer warning_led}]

# -------------------- Clock Grouping --------------------
# Since there's only one clock domain, no need for clock groups
# But if you have multiple clocks in the future:
# set_clock_groups -asynchronous -group [get_clocks clk]

# -------------------- Output Delay External (for UART) --------------------
# UART timing is very relaxed, create multicycle paths if needed
# set_multicycle_path -setup 100 -from [get_clocks clk] -to [get_ports uart_tx]
# set_multicycle_path -hold 0 -from [get_clocks clk] -to [get_ports uart_tx]
