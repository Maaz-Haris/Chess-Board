`timescale 1ns / 1ps

module pixel_clk_gen(
    input clk,                  // pixel clock
    input video_on,             // video on signal
    input [9:0] x, y,           // current pixel coordinates
    input [3:0] sec_1s_a, sec_10s_a, min_1s_a, min_10s_a, // Timer A
    input [3:0] sec_1s_b, sec_10s_b, min_1s_b, min_10s_b, // Timer B
    input timer_select,         // 0 = Timer A active, 1 = Timer B active
    output [11:0] time_rgb
);

    reg [3:0] red = 0, green = 0, blue = 0;

    // Chess board piece positions
    reg signed [3:0] chess_values [7:0][7:0];

    // Initialize chess_values array
    initial begin
        // Rank 8
        chess_values[0][0] = -4; // Black Rook
        chess_values[0][1] = -5; // Black Knight
        chess_values[0][2] = -6; // Black Bishop
        chess_values[0][3] = -3; // Black Queen
        chess_values[0][4] = -2; // Black King
        chess_values[0][5] = -6; // Black Bishop
        chess_values[0][6] = -5; // Black Knight
        chess_values[0][7] = -4; // Black Rook
        // Rank 7
        chess_values[1][0] = -1; // Black Pawn
        chess_values[1][1] = -1;
        chess_values[1][2] = -1;
        chess_values[1][3] = -1;
        chess_values[1][4] = -1;
        chess_values[1][5] = -1;
        chess_values[1][6] = -1;
        chess_values[1][7] = -1;
        // Rank 6
        chess_values[2][0] = 0;  // Empty
        chess_values[2][1] = 0;
        chess_values[2][2] = 0;
        chess_values[2][3] = 0;
        chess_values[2][4] = 0;
        chess_values[2][5] = 0;
        chess_values[2][6] = 0;
        chess_values[2][7] = 0;
        // Rank 5
        chess_values[3][0] = 0;
        chess_values[3][1] = 0;
        chess_values[3][2] = 0;
        chess_values[3][3] = 0;
        chess_values[3][4] = 0;
        chess_values[3][5] = 0;
        chess_values[3][6] = 0;
        chess_values[3][7] = 0;
        // Rank 4
        chess_values[4][0] = 0;
        chess_values[4][1] = 0;
        chess_values[4][2] = 0;
        chess_values[4][3] = 0;
        chess_values[4][4] = 0;
        chess_values[4][5] = 0;
        chess_values[4][6] = 0;
        chess_values[4][7] = 0;
        // Rank 3
        chess_values[5][0] = 0;
        chess_values[5][1] = 0;
        chess_values[5][2] = 0;
        chess_values[5][3] = 0;
        chess_values[5][4] = 0;
        chess_values[5][5] = 0;
        chess_values[5][6] = 0;
        chess_values[5][7] = 0;
        // Rank 2
        chess_values[6][0] = 1;  // White Pawn
        chess_values[6][1] = 1;
        chess_values[6][2] = 1;
        chess_values[6][3] = 1;
        chess_values[6][4] = 1;
        chess_values[6][5] = 1;
        chess_values[6][6] = 1;
        chess_values[6][7] = 1;
        // Rank 1
        chess_values[7][0] = 4;  // White Rook
        chess_values[7][1] = 5;  // White Knight
        chess_values[7][2] = 6;  // White Bishop
        chess_values[7][3] = 3;  // White Queen
        chess_values[7][4] = 2;  // White King
        chess_values[7][5] = 6;  // White Bishop
        chess_values[7][6] = 5;  // White Knight
        chess_values[7][7] = 4;  // White Rook
    end

    // *** PLAYER 1 Label (Top, 160x32 pixels) ***
    localparam P1_X_L = 0;
    localparam P1_X_R = 127;
    localparam P1_Y_T = 0;
    localparam P1_Y_B = 31;

    // *** Timer A Section (Below PLAYER 1, 160x64 pixels) ***
    localparam A_M10_X_L = 0;
    localparam A_M10_X_R = 31;
    localparam A_M10_Y_T = 50;
    localparam A_M10_Y_B = 113;

    localparam A_M1_X_L = 32;
    localparam A_M1_X_R = 63;
    localparam A_M1_Y_T = 50;
    localparam A_M1_Y_B = 113;

    localparam A_C_X_L = 64;
    localparam A_C_X_R = 95;
    localparam A_C_Y_T = 50;
    localparam A_C_Y_B = 113;

    localparam A_S10_X_L = 96;
    localparam A_S10_X_R = 127;
    localparam A_S10_Y_T = 50;
    localparam A_S10_Y_B = 113;

    localparam A_S1_X_L = 128;
    localparam A_S1_X_R = 159;
    localparam A_S1_Y_T = 50;
    localparam A_S1_Y_B = 113;

    // *** PLAYER 2 Label (Above Timer B, 160x32 pixels) ***
    localparam P2_X_L = 0;
    localparam P2_X_R = 127;
    localparam P2_Y_T = 136;
    localparam P2_Y_B = 167;

    // *** Timer B Section (Below PLAYER 2, 160x64 pixels) ***
    localparam B_M10_X_L = 0;
    localparam B_M10_X_R = 31;
    localparam B_M10_Y_T = 200;
    localparam B_M10_Y_B = 263;

    localparam B_M1_X_L = 32;
    localparam B_M1_X_R = 63;
    localparam B_M1_Y_T = 200;
    localparam B_M1_Y_B = 263;

    localparam B_C_X_L = 64;
    localparam B_C_X_R = 95;
    localparam B_C_Y_T = 200;
    localparam B_C_Y_B = 263;

    localparam B_S10_X_L = 96;
    localparam B_S10_X_R = 127;
    localparam B_S10_Y_T = 200;
    localparam B_S10_Y_B = 263;

    localparam B_S1_X_L = 128;
    localparam B_S1_X_R = 159;
    localparam B_S1_Y_T = 200;
    localparam B_S1_Y_B = 263;

    // *** Chess Board Parameters (Rightmost, 480x480) ***
    parameter BOARD_SIZE = 480;
    parameter GRID_SIZE = 8;
    parameter SQUARE_SIZE = BOARD_SIZE / GRID_SIZE;
    localparam CHESS_X_L = 160;
    localparam CHESS_X_R = 639;
    localparam CHESS_Y_T = 0;
    localparam CHESS_Y_B = 479;

    // Region detection signals
    wire P1_on, P2_on;
    wire A_M10_on, A_M1_on, A_C_on, A_S10_on, A_S1_on;
    wire B_M10_on, B_M1_on, B_C_on, B_S10_on, B_S1_on;
    wire chess_on;

    assign P1_on = (P1_X_L <= x) && (x <= P1_X_R) && (P1_Y_T <= y) && (y <= P1_Y_B);
    assign P2_on = (P2_X_L <= x) && (x <= P2_X_R) && (P2_Y_T <= y) && (y <= P2_Y_B);

    assign A_M10_on = (A_M10_X_L <= x) && (x <= A_M10_X_R) && (A_M10_Y_T <= y) && (y <= A_M10_Y_B);
    assign A_M1_on  = (A_M1_X_L  <= x) && (x <= A_M1_X_R) && (A_M1_Y_T  <= y) && (y <= A_M1_Y_B);
    assign A_C_on   = (A_C_X_L   <= x) && (x <= A_C_X_R) && (A_C_Y_T   <= y) && (y <= A_C_Y_B);
    assign A_S10_on = (A_S10_X_L <= x) && (x <= A_S10_X_R) && (A_S10_Y_T <= y) && (y <= A_S10_Y_B);
    assign A_S1_on  = (A_S1_X_L  <= x) && (x <= A_S1_X_R) && (A_S1_Y_T  <= y) && (y <= A_S1_Y_B);

    assign B_M10_on = (B_M10_X_L <= x) && (x <= B_M10_X_R) && (B_M10_Y_T <= y) && (y <= B_M10_Y_B);
    assign B_M1_on  = (B_M1_X_L  <= x) && (x <= B_M1_X_R) && (B_M1_Y_T  <= y) && (y <= B_M1_Y_B);
    assign B_C_on   = (B_C_X_L   <= x) && (x <= B_C_X_R) && (B_C_Y_T   <= y) && (y <= B_C_Y_B);
    assign B_S10_on = (B_S10_X_L <= x) && (x <= B_S10_X_R) && (B_S10_Y_T <= y) && (y <= B_S10_Y_B);
    assign B_S1_on  = (B_S1_X_L  <= x) && (x <= B_S1_X_R) && (B_S1_Y_T  <= y) && (y <= B_S1_Y_B);

    assign chess_on = (CHESS_X_L <= x) && (x <= CHESS_X_R) && (CHESS_Y_T <= y) && (y <= CHESS_Y_B);

    // ASCII ROM Interface (for PLAYER 1 and PLAYER 2 labels)
    wire [10:0] ascii_rom_addr;
    reg [6:0] ascii_char_addr;
    reg [3:0] ascii_row_addr;
    reg [2:0] ascii_bit_addr;
    wire [7:0] ascii_word;
    wire ascii_bit;

    assign ascii_rom_addr = {ascii_char_addr, ascii_row_addr};
    assign ascii_bit = ascii_word[7 - ascii_bit_addr];

    // Digit ROM Interface (for Timers)
    wire [10:0] digit_rom_addr;
    reg [6:0] digit_char_addr;
    reg [3:0] digit_row_addr;
    reg [2:0] digit_bit_addr;
    wire [7:0] digit_word;
    wire digit_bit;

    assign digit_rom_addr = {digit_char_addr, digit_row_addr};
    assign digit_bit = digit_word[7 - digit_bit_addr];

    // Chess Pieces ROM Interface
    wire [10:0] piece_rom_addr;
    reg [6:0] piece_char_addr;
    reg [3:0] piece_row_addr;
    wire [7:0] piece_word;
    wire piece_bit;

    assign piece_rom_addr = {piece_char_addr, piece_row_addr};
    // Fix bit selection: Map x_in_square (14 to 45) to bit index (0 to 7)
    wire [5:0] x_in_square_for_bit = (x - CHESS_X_L) % SQUARE_SIZE;
    wire [2:0] bit_index = (x_in_square_for_bit >= 14 && x_in_square_for_bit < 46) ? ((x_in_square_for_bit - 14) >> 2) : 0;
    assign piece_bit = piece_word[7 - bit_index];

    // Instantiate ROMs
    ascii_rom adr(.clk(clk), .addr(ascii_rom_addr), .data(ascii_word));
    clock_digit_rom cdr(.clk(clk), .addr(digit_rom_addr), .data(digit_word));
    chess_pieces_rom cpr(.clk(clk), .addr(piece_rom_addr), .data(piece_word));

    // Chess rendering variables
    reg [2:0] row;              // Board row (0 to 7)
    reg [2:0] col;              // Board column (0 to 7)
    reg signed [3:0] piece_val; // Piece value from chess_values
    reg [5:0] x_in_square;      // X position within square (0 to 59)
    reg [5:0] y_in_square;      // Y position within square (0 to 59)

    // RGB pixel generation
    always @* begin
        // Default background: black
        red   = 4'h0;
        green = 4'h0;
        blue  = 4'h0;

        if (video_on) begin
            // *** Chess Board rendering ***
            if (chess_on) begin
                // Calculate board indices
                row = (y - CHESS_Y_T) / SQUARE_SIZE; // 0 to 7
                col = (x - CHESS_X_L) / SQUARE_SIZE; // 0 to 7
                piece_val = chess_values[row][col];

                // Chess square background
                if (((x - CHESS_X_L) / SQUARE_SIZE % 2) ^ ((y - CHESS_Y_T) / SQUARE_SIZE % 2)) begin
                    red   = 4'hA; green = 4'hF; blue  = 4'hA; // Light green
                end else begin
                    red   = 4'h0; green = 4'h8; blue  = 4'h0; // Dark green
                end

                // Chess piece rendering
                if (piece_val != 0) begin
                    // Calculate pixel position within the square
                    x_in_square = (x - CHESS_X_L) % SQUARE_SIZE; // 0 to 59
                    y_in_square = (y - CHESS_Y_T) % SQUARE_SIZE; // 0 to 59

                    // Center the 32x64 piece (4x scaling of 8x16) in 60x60 square
                    if (x_in_square >= 14 && x_in_square < 46 && y_in_square >= 2 && y_in_square < 66) begin
                        // Map chess_values to ROM base address
                        case (piece_val)
                            -1, 1:  piece_char_addr = 7'h50; // Pawn
                            -2, 2:  piece_char_addr = 7'h55; // King
                            -3, 3:  piece_char_addr = 7'h54; // Queen
                            -4, 4:  piece_char_addr = 7'h53; // Rook
                            -5, 5:  piece_char_addr = 7'h52; // Knight
                            -6, 6:  piece_char_addr = 7'h51; // Bishop
                            default: piece_char_addr = 7'h50; // Default to pawn
                        endcase

                        piece_row_addr = (y_in_square - 2) >> 2; // Divide by 4 for 4x scaling
                        if (piece_bit) begin
                            if (piece_val > 0) begin
                                red = 4'hF; green = 4'hF; blue = 4'hF; // White piece
                            end else begin
                                red = 4'h0; green = 4'h0; blue = 4'h0; // Black piece
                            end
                        end
                    end
                end
            end

            // *** PLAYER 1 Label ("PLAYER 1") ***
            if (P1_on) begin
                case ((x - P1_X_L) / 16) // 8 chars, 16 pixels each (2x scaling)
                    0: ascii_char_addr = 7'h50; // P
                    1: ascii_char_addr = 7'h4C; // L
                    2: ascii_char_addr = 7'h41; // A
                    3: ascii_char_addr = 7'h59; // Y
                    4: ascii_char_addr = 7'h45; // E
                    5: ascii_char_addr = 7'h52; // R
                    6: ascii_char_addr = 7'h20; // Space
                    7: ascii_char_addr = 7'h31; // 1
                    default: ascii_char_addr = 7'h20; // Space
                endcase
                ascii_row_addr = (y - P1_Y_T) >> 1; // 32 pixels tall, 2x scaling
                ascii_bit_addr = (x - P1_X_L) >> 1;
                if (ascii_bit) begin
                    red = 4'hF; green = 4'hF; blue = 4'hF; // White text
                end
            end

            // *** Timer A rendering ***
            if (A_M10_on) begin
                digit_char_addr = {3'b011, min_10s_a};
                digit_row_addr  = (y - A_M10_Y_T) >> 2; // 64 pixels tall, 4x scaling
                digit_bit_addr  = x >> 2;
                if (digit_bit) begin
                    if (!timer_select) begin // Timer A active
                        red = 4'hF; green = 4'hF; blue = 4'h0; // Bright yellow
                    end else begin // Timer A paused
                        red = 4'hA; green = 4'hA; blue = 4'h0; // Dim yellow
                    end
                end
            end else if (A_M1_on) begin
                digit_char_addr = {3'b011, min_1s_a};
                digit_row_addr  = (y - A_M1_Y_T) >> 2;
                digit_bit_addr  = x >> 2;
                if (digit_bit) begin
                    if (!timer_select) begin // Timer A active
                        red = 4'hF; green = 4'hF; blue = 4'h0; // Bright yellow
                    end else begin // Timer A paused
                        red = 4'hA; green = 4'hA; blue = 4'h0; // Dim yellow
                    end
                end
            end else if (A_C_on) begin
                digit_char_addr = 7'h3a; // Colon
                digit_row_addr  = (y - A_C_Y_T) >> 2;
                digit_bit_addr  = x >> 2;
                if (digit_bit) begin
                    if (!timer_select) begin // Timer A active
                        red = 4'hF; green = 4'hF; blue = 4'h0; // Bright yellow
                    end else begin // Timer A paused
                        red = 4'hA; green = 4'hA; blue = 4'h0; // Dim yellow
                    end
                end
            end else if (A_S10_on) begin
                digit_char_addr = {3'b011, sec_10s_a};
                digit_row_addr  = (y - A_S10_Y_T) >> 2;
                digit_bit_addr  = x >> 2;
                if (digit_bit) begin
                    if (!timer_select) begin // Timer A active
                        red = 4'hF; green = 4'hF; blue = 4'h0; // Bright yellow
                    end else begin // Timer A paused
                        red = 4'hA; green = 4'hA; blue = 4'h0; // Dim yellow
                    end
                end
            end else if (A_S1_on) begin
                digit_char_addr = {3'b011, sec_1s_a};
                digit_row_addr  = (y - A_S1_Y_T) >> 2;
                digit_bit_addr  = x >> 2;
                if (digit_bit) begin
                    if (!timer_select) begin // Timer A active
                        red = 4'hF; green = 4'hF; blue = 4'h0; // Bright yellow
                    end else begin // Timer A paused
                        red = 4'hA; green = 4'hA; blue = 4'h0; // Dim yellow
                    end
                end
            end

            // *** PLAYER 2 Label ("PLAYER 2") ***
            if (P2_on) begin
                case ((x - P2_X_L) / 16) // 8 chars, 16 pixels each
                    0: ascii_char_addr = 7'h50; // P
                    1: ascii_char_addr = 7'h4C; // L
                    2: ascii_char_addr = 7'h41; // A
                    3: ascii_char_addr = 7'h59; // Y
                    4: ascii_char_addr = 7'h45; // E
                    5: ascii_char_addr = 7'h52; // R
                    6: ascii_char_addr = 7'h20; // Space
                    7: ascii_char_addr = 7'h32; // 2
                    default: ascii_char_addr = 7'h20; // Space
                endcase
                ascii_row_addr = (y - P2_Y_T) >> 1;
                ascii_bit_addr = (x - P2_X_L) >> 1;
                if (ascii_bit) begin
                    red = 4'hF; green = 4'hF; blue = 4'hF; // White text
                end
            end

            // *** Timer B rendering ***
            if (B_M10_on) begin
                digit_char_addr = {3'b011, min_10s_b};
                digit_row_addr  = (y - B_M10_Y_T) >> 2;
                digit_bit_addr  = x >> 2;
                if (digit_bit) begin
                    if (timer_select) begin // Timer B active
                        red = 4'hF; green = 4'hF; blue = 4'h0; // Bright yellow
                    end else begin // Timer B paused
                        red = 4'hA; green = 4'hA; blue = 4'h0; // Dim yellow
                    end
                end
            end else if (B_M1_on) begin
                digit_char_addr = {3'b011, min_1s_b};
                digit_row_addr  = (y - B_M1_Y_T) >> 2;
                digit_bit_addr  = x >> 2;
                if (digit_bit) begin
                    if (timer_select) begin // Timer B active
                        red = 4'hF; green = 4'hF; blue = 4'h0; // Bright yellow
                    end else begin // Timer B paused
                        red = 4'hA; green = 4'hA; blue = 4'h0; // Dim yellow
                    end
                end
            end else if (B_C_on) begin
                digit_char_addr = 7'h3a; // Colon
                digit_row_addr  = (y - B_C_Y_T) >> 2;
                digit_bit_addr  = x >> 2;
                if (digit_bit) begin
                    if (timer_select) begin // Timer B active
                        red = 4'hF; green = 4'hF; blue = 4'h0; // Bright yellow
                    end else begin // Timer B paused
                        red = 4'hA; green = 4'hA; blue = 4'h0; // Dim yellow
                    end
                end
            end else if (B_S10_on) begin
                digit_char_addr = {3'b011, sec_10s_b};
                digit_row_addr  = (y - B_S10_Y_T) >> 2;
                digit_bit_addr  = x >> 2;
                if (digit_bit) begin
                    if (timer_select) begin // Timer B active
                        red = 4'hF; green = 4'hF; blue = 4'h0; // Bright yellow
                    end else begin // Timer B paused
                        red = 4'hA; green = 4'hA; blue = 4'h0; // Dim yellow
                    end
                end
            end else if (B_S1_on) begin
                digit_char_addr = {3'b011, sec_1s_b};
                digit_row_addr  = (y - B_S1_Y_T) >> 2;
                digit_bit_addr  = x >> 2;
                if (digit_bit) begin
                    if (timer_select) begin // Timer B active
                        red = 4'hF; green = 4'hF; blue = 4'h0; // Bright yellow
                    end else begin // Timer B paused
                        red = 4'hA; green = 4'hA; blue = 4'h0; // Dim yellow
                    end
                end
            end
        end else begin
            red = 4'h0; green = 4'h0; blue = 4'h0; // Blank (black)
        end
    end

    assign time_rgb = {red, green, blue};

endmodule
