module matrix_scanner (
    input wire clk,              // System clock (e.g., 100 MHz)
    input wire rst,              // Active-high reset
    input wire [7:0] col_in,     // 8-bit column sensor inputs (active-low)
    output reg [2:0] row_sel,    // 3-bit row select for row activation
    output reg row_en,           // Demux enable (always 0 to keep rows active)
    output reg [63:0] sensor_state // Flattened 1D array for 8x8 sensor state
);

    // Clock divider for slower scanning (1250 µs per row, 10 ms per full scan)
    reg [16:0] clk_div;          // Clock divider counter (17 bits for 124,999)
    reg scan_en;                 // Enable signal for row scanning
    integer i;                   // Loop variable for reset

    // Clock divider logic (1250 µs per row, 10 ms per full 8-row scan)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div <= 0;
            scan_en <= 0;
        end else begin
            clk_div <= clk_div + 1;
            if (clk_div == 17'd124999) begin // 125,000 cycles = 1250 µs at 100 MHz
                clk_div <= 0;
                scan_en <= 1; // Pulse scan_en every 1250 µs
            end else begin
                scan_en <= 0;
            end
        end
    end

    // Row scanning and sensor reading logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            row_sel <= 0;          // Reset row select
            row_en <= 0;           // Ensure row_en is 0 during reset
            // Explicitly clear sensor_state
            sensor_state <= 64'b0;
        end else begin
            row_en <= 0;           // Always keep row enabled (active-low)
            if (scan_en) begin
                // Store column inputs for the current row (active-low, so invert)
                sensor_state[row_sel * 8 +: 8] <= ~col_in; // Assign 8-bit row value
                // Move to the next row
                row_sel <= row_sel + 1;
                if (row_sel == 3'd7) begin
                    row_sel <= 0; // Reset to 0 after row 7
                end
            end
        end
    end

endmodule
