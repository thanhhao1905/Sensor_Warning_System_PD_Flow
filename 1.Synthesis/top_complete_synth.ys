# 1. Read Liberty file (Sử dụng thư viện sky130 tiêu chuẩn)
read_liberty -lib /openlane/pdks/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# 2. Read all RTL files (Đọc toàn bộ các file thành phần có trong thư mục project)
read_verilog -sv clk_divider.v
read_verilog -sv dht11.v
read_verilog -sv digit_driver.v
read_verilog -sv digit_scan.v
read_verilog -sv digit_selector.v
read_verilog -sv fire_alarm_system.v
read_verilog -sv gen_string.v
read_verilog -sv hex7seg.v
read_verilog -sv i2c_writeframe.v
read_verilog -sv latch_data.v
read_verilog -sv lcd_display.v
read_verilog -sv lcd_write_cmd_data.v
read_verilog -sv refresh_lcd.v
read_verilog -sv shift_74hc595.v
read_verilog -sv start_dht.v
read_verilog -sv temp_to_uart_string.v
read_verilog -sv top_dht11_lcd.v
read_verilog -sv uart_mq2_receiver.v
read_verilog -sv uart_tx.v
read_verilog -sv uart_tx_feeder.v

# Đọc các file wrapper/top tầng trung gian
read_verilog -sv top.v
#read_verilog -sv top_uart_display.v

# Đọc file top level chính
read_verilog -sv top_complete.v

# 3. Set top module
# Thiết lập module 'top_complete' làm gốc của cây phân cấp thiết kế 
hierarchy -check -top top_complete

# 4. High-level synthesis
synth -top top_complete

# 5. Map flip-flops to Sky130 library
dfflibmap -liberty /openlane/pdks/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# 6. Optimize and map logic to standard cells
abc -liberty /openlane/pdks/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# 7. Clean up
opt_clean -purge
opt

# 8. Write output netlist
# Xuất file netlist sau tổng hợp để sử dụng cho bước Place & Route
write_verilog -noattr -noexpr top_complete_synth.v

# 9. Generate reports
stat
