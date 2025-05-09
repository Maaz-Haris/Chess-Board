`timescale 1ns / 1ps
module piece_value_converter (
    input wire clk,              // System clock (e.g., 100 MHz)
    input wire rst,              // Active-high reset
    input wire [63:0] sensor_state, // Flattened 8x8 sensor state (8'hFF = all pieces present per row)
    output wire [255:0] piece_values // Flattened 1D array of 64 4-bit signed integers
);
    // Internal 2D array, styled like chess_values
    reg signed [3:0] piece_values_internal [0:7][0:7];
    integer row, col; // Loop variables
    
    // Generate block to statically map internal 2D array to flattened output port
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : row_gen
            for (j = 0; j < 8; j = j + 1) begin : col_gen
                assign piece_values[(i * 8 + j) * 4 + 3 : (i * 8 + j) * 4] = piece_values_internal[i][j];
            end
        end
    endgenerate
    
    // Conversion logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize all piece_values_internal to 0 on reset
            for (row = 0; row < 8; row = row + 1) begin
                for (col = 0; col < 8; col = col + 1) begin
                    piece_values_internal[row][col] <= 4'd0;
                end
            end
        end else begin
            // Convert sensor_state to piece_values based on initial position
            for (row = 0; row < 8; row = row + 1) begin
                for (col = 0; col < 8; col = col + 1) begin
                    // Check if this specific position is occupied
                    if (sensor_state[row * 8 + col]) begin
                        // Black pieces (rows 0 and 1)
                        if (row == 0) begin
                            case (col)
                                0, 7: piece_values_internal[row][col] <= -4;    // Rooks (a8, h8)
                                1, 6: piece_values_internal[row][col] <= -5;    // Knights (b8, g8)
                                2, 5: piece_values_internal[row][col] <= -6;    // Bishops (c8, f8)
                                3:    piece_values_internal[row][col] <= -3;    // Queen (d8)
                                4:    piece_values_internal[row][col] <= -2;    // King (e8)
                                default: piece_values_internal[row][col] <= 4'd0;
                            endcase
                        end else if (row == 1) begin
                            piece_values_internal[row][col] <= -1;              // Pawns (a7 to h7)
                        end
                        // White pieces (rows 6 and 7)
                        else if (row == 6) begin
                            piece_values_internal[row][col] <= 1;               // Pawns (a2 to h2)
                        end else if (row == 7) begin
                            case (col)
                                0, 7: piece_values_internal[row][col] <= 4;     // Rooks (a1, h1)
                                1, 6: piece_values_internal[row][col] <= 5;     // Knights (b1, g1)
                                2, 5: piece_values_internal[row][col] <= 6;     // Bishops (c1, f1)
                                3:    piece_values_internal[row][col] <= 3;     // Queen (d1)
                                4:    piece_values_internal[row][col] <= 2;     // King (e1)
                                default: piece_values_internal[row][col] <= 4'd0;
                            endcase
                        end
                    end else begin
                        piece_values_internal[row][col] <= 4'd0;                // Empty square
                    end
                end
            end
        end
    end
endmodule
