module top_module_initial (
    input wire clk,              // System clock (e.g., 100 MHz)
    input wire rst,              // Active-high reset
    
    // Physical I/O pins for matrix interface
    input wire [7:0] col_in,     // Column inputs from sensors (active-low)
    output wire [2:0] row_addr,  // 3-bit row address for external decoder
    output wire row_addr_en,     // Row address enable signal (active-low)
    
    // Outputs for future modules
    output wire [255:0] piece_values, // Encoded chess piece values (4-bit signed per square)
    output wire [63:0] sensor_state   // Current sensor state (1 bit per square)
);
    // Internal wires
    wire [2:0] internal_row_sel;
    wire internal_row_en;
    wire [63:0] internal_sensor_state;
    
    // Register row control signals for better timing
    // and to ensure they're stable for the external decoder
    reg [2:0] row_addr_reg;
    reg row_addr_en_reg;
    
    // Registered sensor state
    reg [63:0] sensor_state_reg;
    
    // Connect registered outputs to module outputs
    assign row_addr = row_addr_reg;
    assign row_addr_en = row_addr_en_reg;
    assign sensor_state = sensor_state_reg;
    
    // Instantiate matrix_scanner
    matrix_scanner scanner (
        .clk(clk),
        .rst(rst),
        .col_in(col_in),
        .row_sel(internal_row_sel),
        .row_en(internal_row_en),
        .sensor_state(internal_sensor_state)
    );
    
    // Register outputs for external decoder and future modules
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            row_addr_reg <= 3'b000;
            row_addr_en_reg <= 1'b1;  // Inactive state (assuming active-low)
            sensor_state_reg <= 64'b0;
        end else begin
            row_addr_reg <= internal_row_sel;
            row_addr_en_reg <= internal_row_en;  // Pass through row enable signal
            sensor_state_reg <= internal_sensor_state;
        end
    end
    
    // Instantiate piece_value_converter
    piece_value_converter converter (
        .clk(clk),
        .rst(rst),
        .sensor_state(internal_sensor_state),
        .piece_values(piece_values)
    );
    
endmodule
