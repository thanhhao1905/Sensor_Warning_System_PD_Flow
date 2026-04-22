
# Physical Design of Sensor_Warning_System (RTL-to-GDS Flow)

After completing the functional verification of the Sensor_Warning_System through simulation, the next step is to take the design through the synthesis and physical layout generation flow – a critical stage to prepare for actual IC fabrication. This flow includes several main stages: logic synthesis, placement and routing, GDS file generation, and layout verification.

<img width="810" height="191" alt="image" src="https://github.com/user-attachments/assets/078a7c97-965b-4f2a-a906-d841de3e07b5" />

## 1. Logic Synthesis with Yosys

The goal of this step is to convert the Register-Transfer Level (RTL) Verilog code into a gate-level netlist based on a specific standard cell library.

- **Tool:** Yosys
- **Standard Cell Library:** sky130_fd_sc_hd (Sky130 standard, tt_025C_1v80 operating corner)
- **Procedure:** Yosys reads all source Verilog files of the Sensor_Warning_System, including:
    - Clock management modules: `clk_divider.v`
    - Sensor communication modules: `dht11.v`, `start_dht.v`, `uart_mq2_receiver.v`
    - Display modules: `lcd_display.v`, `lcd_write_cmd_data.v`, `i2c_writeframe.v`, `refresh_lcd.v`, `gen_string.v`
    - 7-segment control modules: `shift_74hc595.v`, `digit_driver.v`, `digit_scan.v`, `digit_selector.v`, `hex7seg.v`, `latch_data.v`
    - UART communication modules: `uart_tx.v`, `uart_tx_feeder.v`, `temp_to_uart_string.v`
    - Top modules: `top.v`, `top_complete.v` (main top module), `fire_alarm_system.v`

- **Process:** Yosys then performs logic optimization and maps the behavioral descriptions in the RTL code to basic logic gates available in the Sky130 cell library (e.g., AND, OR, XOR, DFF).
- **Output:** A netlist file `top_complete_synth.v` (Verilog format) containing detailed instances and connections, with `top_complete` as the root of the design hierarchy. This is a crucial input for subsequent physical processing steps.

## 2. Placement and Routing with OpenROAD

With the netlist ready, the next step is to determine the physical location of each cell on the chip surface and create the metal connections between them.

- **Tool:** OpenROAD
- **Procedure:** Executed via the script `top_complete.tcl`:
    - **Input Processing:** Receives the netlist `top_complete_synth.v` from Yosys, timing constraints file (`.sdc`), and the Sky130 technology library.
    - **Floorplanning:** Defines chip dimensions, I/O pin locations, and allocates areas for main functional blocks like the DHT11 controller (`dht11`, `start_dht`), UART receiver for MQ-2 (`uart_mq2_receiver`), I2C interface for LCD (`i2c_writeframe`), and SPI interface for the 74HC595 shift register (`shift_74hc595`).
    - **Placement:** Arranges logic cells into predefined rows and columns, optimizing for area and performance.


    - **Clock Tree Synthesis (CTS):** With support from the `constraints.sdc` file, OpenROAD builds a clock distribution tree, ensuring the clock signal reaches all flip-flops with minimal skew and meeting timing requirements. This is particularly important for timing-critical components like the 1-wire handshake of the DHT11 (`dht11.v`), UART protocol (`uart_tx.v`, `uart_mq2_receiver.v`), and I2C protocol (`i2c_writeframe.v`).
    - **Routing:** Creates metal connection paths between cells according to the netlist.

<img width="1853" height="895" alt="image" src="https://github.com/user-attachments/assets/4b5f157c-ebfd-49c4-8797-b0de24002205" />

- **Output:** A DEF (Design Exchange Format) file containing geometric information about cell positions and routing paths across different metal layers.

<img width="1853" height="898" alt="image" src="https://github.com/user-attachments/assets/f82c6aa0-25a6-485c-9c33-54aedaf51586" />

## 3. Complete Layout Generation and GDS Export with Magic

To prepare for manufacturing, the design needs to be converted from a positional description (DEF) to a detailed geometric representation of actual material layers.

- **Tool:** Magic VLSI Layout Tool
- **Procedure:**
    - **Import DEF File:** Using Tcl commands in Magic, the DEF file from OpenROAD is read along with the corresponding Sky130 technology library.
    - **Layout Inspection and Editing (if needed):** Magic allows viewing and manual editing of the layout to ensure no geometric violations exist, especially for sensitive signal lines from the DHT11 (`dht11.v`), the UART interface to the ESP32 (`uart_tx.v`), and the I2C/SPI lines controlling the displays.
    - **Export GDS File:** Use the command `gds write top_complete.gds` to generate a GDSII file – the industry-standard format containing all physical parameters (diffusion layers, polysilicon, metal layers) required by the fabrication foundry.

<img width="1854" height="897" alt="image" src="https://github.com/user-attachments/assets/cceb9215-1a4a-4037-b1e4-a5d51a8221ca" />

## 4. Layout Verification and Visualization with KLayout

Before proceeding to "Tape-out" – sending the design for manufacturing – a final verification is needed to ensure no design rule violations exist.

- **Tool:** KLayout
- **Role:**
    - **Detailed Layout Viewing:** KLayout provides color-coded layer visibility, allowing zooming, panning, and precise measurements on the layout.
    - **Visual Inspection:** Engineers can easily identify potential issues such as layer overlaps, insufficient spacing between traces, or connectivity problems. This is especially important for a complex system with multiple different communication protocols (UART, I2C, SPI, 1-wire) like the Sensor_Warning_System.

- **Final Result:** A complete, verified layout of the Sensor_Warning_System (`top_complete` module), ready for the Tape-out stage – the final step before mass production.

<img width="1851" height="898" alt="image" src="https://github.com/user-attachments/assets/174d9734-c363-436a-b6a3-b120ddeb88f2" /> <img width="1853" height="899" alt="image" src="https://github.com/user-attachments/assets/62c2f633-34c1-4c5b-b909-ed00ab11eea2" />

## 5. 3D Layout Analysis and Verification with GDS3D

After successfully exporting the GDS file `top_complete.gds` from Magic, the next step is to perform visual inspection and three-dimensional structural analysis of the entire design. Instead of using KLayout, I choose the **GDS3D** tool – a dedicated 3D IC layout viewer and analyzer that allows for deeper evaluation of geometry and interactions between physical layers.

- **Tool:** GDS3D
- **Purpose:**
    - **Visualizing Multi-Layer Structures:** GDS3D clearly shows the overlaps between layers such as diffusion, polysilicon, metal layers (M1, M2, M3…), and vias. This is especially important for detecting errors like shorts between layers or missing connections.
    - **Height and Spacing Analysis:** In 3D mode, users can rotate, tilt, and zoom into any area to check wiring density, ensuring no vertical spacing violations or excessive parasitic capacitance effects.
    - **Detecting Hidden Design Errors:** Errors such as antenna effect on long metal lines or floating structures become easier to recognize in 3D space.

- **Procedure with GDS3D:**

    1.**Navigate to the GDS3D tool directory:**
        ```bash
        cd GDS3D
  
    2.**Run the GDS3D startup command with the Sky130 technology file and the output GDS file:**
       ```bash
        linux/GDS3D -p techfiles/skywater130.txt -i gds/top_complete_final.gds

## Conclusion

This RTL-to-GDS flow not only closes the IC design lifecycle from concept to physical product but also provides valuable practical experience for any IC design engineer wanting to deeply understand the synthesis and physical layout process. The Sensor_Warning_System, with its flexible features including precise clock management for the DHT11 (`clk_divider.v`, `dht11.v`, `start_dht.v`), UART communication with ESP32 (`uart_tx.v`, `uart_tx_feeder.v`, `temp_to_uart_string.v`, `uart_mq2_receiver.v`), I2C control for the LCD (`i2c_writeframe.v`, `lcd_display.v`, `lcd_write_cmd_data.v`, `refresh_lcd.v`, `gen_string.v`), and SPI for the 7-segment display (`shift_74hc595.v`, `digit_driver.v`, `digit_scan.v`, `digit_selector.v`, `hex7seg.v`, `latch_data.v`), allows this system to adapt to various applications – from smart environmental monitoring and early fire warning to cloud computing integration – and can be easily integrated into complex SoC designs.
```# Sensor_Warning_System_PD_Flow
