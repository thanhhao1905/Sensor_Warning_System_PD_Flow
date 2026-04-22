
# Physical Design of Sensor_Warning_System (RTL-to-GDS Flow)

After completing the functional verification of the Sensor_Warning_System through simulation, the next step is to take the design through the synthesis and physical layout generation flow – a critical stage to prepare for actual IC fabrication. This flow includes several main stages: logic synthesis, placement and routing, GDS file generation, and layout verification.

<img width="605" height="427" alt="image" src="https://github.com/user-attachments/assets/0dc260de-89a8-4c00-93d0-a563a4783517" />


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

------

## 2. Placement and Routing with OpenROAD

With the netlist ready, the next step is to determine the physical location of each cell on the chip surface and create the metal connections between them.

- **Tool:** OpenROAD
- **Procedure:** Executed via the script `top_complete.tcl`:
    - **Input Processing:** Receives the netlist `top_complete_synth.v` from Yosys, timing constraints file (`.sdc`), and the Sky130 technology library.
    - **Floorplanning:** Defines chip dimensions, I/O pin locations, and allocates areas for main functional blocks like the DHT11 controller (`dht11`, `start_dht`), UART receiver for MQ-2 (`uart_mq2_receiver`), I2C interface for LCD (`i2c_writeframe`), and SPI interface for the 74HC595 shift register (`shift_74hc595`).
    - **Placement:** Arranges logic cells into predefined rows and columns, optimizing for area and performance.

<img width="1296" height="640" alt="image" src="https://github.com/user-attachments/assets/80be38ac-31ff-4dd7-a36e-677afe438988" />

------

**Clock Tree Synthesis (CTS):** With support from the `constraints.sdc` file, OpenROAD builds a clock distribution tree, ensuring the clock signal reaches all flip-flops with minimal skew and meeting timing requirements. This is particularly important for timing-critical components like the 1-wire handshake of the DHT11 (`dht11.v`), UART protocol (`uart_tx.v`, `uart_mq2_receiver.v`), and I2C protocol (`i2c_writeframe.v`).


<img width="1309" height="577" alt="image" src="https://github.com/user-attachments/assets/a99b0ba0-d662-43df-a209-b53a1c3baab7" />

------

**Routing:** Creates metal connection paths between cells according to the netlist.

<img width="605" height="293" alt="image" src="https://github.com/user-attachments/assets/0a81c509-7d56-4d10-945e-ce0e8ee9362f" />

<img width="1287" height="618" alt="image" src="https://github.com/user-attachments/assets/984ec854-c607-48da-80fb-f26c81d2c595" />



- **Output:** A DEF (Design Exchange Format) file containing geometric information about cell positions and routing paths across different metal layers.


## 3. Complete Layout Generation and GDS Export with Magic

To prepare for manufacturing, the design needs to be converted from a positional description (DEF) to a detailed geometric representation of actual material layers.

- **Tool:** Magic VLSI Layout Tool
- **Procedure:**
    - **Import DEF File:** Using Tcl commands in Magic, the DEF file from OpenROAD is read along with the corresponding Sky130 technology library.
    - **Layout Inspection and Editing (if needed):** Magic allows viewing and manual editing of the layout to ensure no geometric violations exist, especially for sensitive signal lines from the DHT11 (`dht11.v`), the UART interface to the ESP32 (`uart_tx.v`), and the I2C/SPI lines controlling the displays.
    - **Export GDS File:** Use the command `gds write top_complete.gds` to generate a GDSII file – the industry-standard format containing all physical parameters (diffusion layers, polysilicon, metal layers) required by the fabrication foundry.

<img width="686" height="530" alt="image" src="https://github.com/user-attachments/assets/fec5ffe9-c3a5-465c-8e79-7251c8eeca78" />

## 4. Layout Verification and Visualization with KLayout

Before proceeding to "Tape-out" – sending the design for manufacturing – a final verification is needed to ensure no design rule violations exist.

- **Tool:** KLayout
- **Role:**
    - **Detailed Layout Viewing:** KLayout provides color-coded layer visibility, allowing zooming, panning, and precise measurements on the layout.
    - **Visual Inspection:** Engineers can easily identify potential issues such as layer overlaps, insufficient spacing between traces, or connectivity problems. This is especially important for a complex system with multiple different communication protocols (UART, I2C, SPI, 1-wire) like the Sensor_Warning_System.

- **Final Result:** A complete, verified layout of the Sensor_Warning_System (`top_complete` module), ready for the Tape-out stage – the final step before mass production.

<img width="1208" height="619" alt="image" src="https://github.com/user-attachments/assets/0f116f2e-1ea8-41d9-9ffc-1cd4e2dacfef" />

<img width="744" height="360" alt="image" src="https://github.com/user-attachments/assets/b667cf66-ce73-4d38-a15e-64b7916e9d7c" />

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

  <img width="1867" height="897" alt="image" src="https://github.com/user-attachments/assets/476e4446-c5f5-420a-ad00-5c1c3ad26f6d" />

  <img width="1867" height="894" alt="image" src="https://github.com/user-attachments/assets/8fbbb7e3-c4c2-4d57-af14-3efa77ecec8a" />

  <img width="1867" height="913" alt="image" src="https://github.com/user-attachments/assets/8f184919-870e-4105-88fd-1b15de4af878" />

  <img width="1857" height="892" alt="image" src="https://github.com/user-attachments/assets/db450bc8-e846-4a98-972b-6845ebadab22" />

  <img width="1857" height="890" alt="image" src="https://github.com/user-attachments/assets/9b90b138-a16e-40cc-8c59-566e9b2303af" />

  <img width="1857" height="914" alt="image" src="https://github.com/user-attachments/assets/990fd87f-2702-413b-b60f-70e882a22ed0" />

  <img width="1866" height="928" alt="image" src="https://github.com/user-attachments/assets/731d3fc7-af55-49f1-90e9-dd69dadf4973" />

  <img width="1866" height="903" alt="image" src="https://github.com/user-attachments/assets/80c0601c-bebb-4d37-8cba-0e1153a4606a" />


## Conclusion

The RTL-to-GDS flow for the Sensor_Warning_System has been successfully completed. Key achievements include a synthesized gate-level netlist, a fully routed physical layout, a verified GDSII file ready for fabrication, and 3D layout verification using GDS3D. The design is now ready for tape-out. This project demonstrates a complete, repeatable physical design flow using open-source tools and the Sky130 process, providing valuable practical experience for future IC design projects.
