module move_executor (
    input wire clk,
    input wire rst,
    input wire [63:0] sensor_state,
    input wire [255:0] board_flat_in,
    output reg [255:0] board_flat_out,
    output reg move_valid,
    output reg next_turn
);

    // Unpacked arrays for internal use
    reg [3:0] board_in [0:63];
    reg [3:0] board_out [0:63];
    reg [5:0] moves [0:55];

    // Piece parameters
    parameter EMPTY = 4'd0;
    parameter W_PAWN = 4'd1;
    parameter W_KING = 4'd2;
    parameter W_QUEEN = 4'd3;
    parameter W_ROOK = 4'd4;
    parameter W_KNIGHT = 4'd5;
    parameter W_BISHOP = 4'd6;
    parameter B_PAWN = 4'd15;
    parameter B_KING = 4'd14;
    parameter B_QUEEN = 4'd13;
    parameter B_ROOK = 4'd12;
    parameter B_KNIGHT = 4'd11;
    parameter B_BISHOP = 4'd10;

    // FSM states
    localparam IDLE = 2'd0;
    localparam LIFTED = 2'd1;
    localparam PLACED = 2'd2;
    localparam UPDATE = 2'd3;

    // Internal signals
    reg [1:0] state, next_state;
    reg [63:0] prev_sensor_state;
    reg [5:0] input_row, input_col, target_row, target_col;
    reg [3:0] lifted_piece;
    reg is_white_piece;
    reg is_white_turn;
    reg [5:0] move_count;
    reg promotion_detected;
    integer i, d, step;
    
    // Declare loop counter variables at the top level for use in all blocks
    integer r, c;
    
    // Variables used in LIFTED state
    reg [5:0] row, col, new_row, new_col;
    reg [3:0] piece, target_piece;
    reg is_white;

    // Direction arrays
    reg signed [5:0] directions [0:7][0:1];
    reg signed [5:0] knight_moves [0:7][0:1];
    reg signed [5:0] king_moves [0:7][0:1];

    // Helper function to convert 2D coordinates to flattened index
    function [5:0] get_flat_index;
        input [5:0] r;
        input [5:0] c;
        begin
            get_flat_index = (r * 8) + c;
        end
    endfunction

    // Initialize direction arrays
    initial begin
        directions[0][0] = 1;  directions[0][1] = 0;
        directions[1][0] = -1; directions[1][1] = 0;
        directions[2][0] = 0;  directions[2][1] = 1;
        directions[3][0] = 0;  directions[3][1] = -1;
        directions[4][0] = 1;  directions[4][1] = 1;
        directions[5][0] = 1;  directions[5][1] = -1;
        directions[6][0] = -1; directions[6][1] = 1;
        directions[7][0] = -1; directions[7][1] = -1;

        knight_moves[0][0] = 2;  knight_moves[0][1] = 1;
        knight_moves[1][0] = 1;  knight_moves[1][1] = 2;
        knight_moves[2][0] = -1; knight_moves[2][1] = 2;
        knight_moves[3][0] = -2; knight_moves[3][1] = 1;
        knight_moves[4][0] = -2; knight_moves[4][1] = -1;
        knight_moves[5][0] = -1; knight_moves[5][1] = -2;
        knight_moves[6][0] = 1;  knight_moves[6][1] = -2;
        knight_moves[7][0] = 2;  knight_moves[7][1] = -1;

        king_moves[0][0] = 1;  king_moves[0][1] = 0;
        king_moves[1][0] = -1; king_moves[1][1] = 0;
        king_moves[2][0] = 0;  king_moves[2][1] = 1;
        king_moves[3][0] = 0;  king_moves[3][1] = -1;
        king_moves[4][0] = 1;  king_moves[4][1] = 1;
        king_moves[5][0] = 1;  king_moves[5][1] = -1;
        king_moves[6][0] = -1; king_moves[6][1] = 1;
        king_moves[7][0] = -1; king_moves[7][1] = -1;
    end

    // State transition
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // FSM logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                for (r = 0; r < 8; r = r + 1) begin
                    for (c = 0; c < 8; c = c + 1) begin
                        if (prev_sensor_state[get_flat_index(r, c)] == 1 && sensor_state[get_flat_index(r, c)] == 0) begin
                            next_state = LIFTED;
                        end
                    end
                end
            end
            LIFTED: begin
                for (r = 0; r < 8; r = r + 1) begin
                    for (c = 0; c < 8; c = c + 1) begin
                        if (prev_sensor_state[get_flat_index(r, c)] == 0 && sensor_state[get_flat_index(r, c)] == 1 && 
                            !(r == input_row && c == input_col)) begin
                            next_state = PLACED;
                        end
                    end
                end
            end
            PLACED: begin
                next_state = UPDATE;
            end
            UPDATE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Main process
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            board_flat_out <= 0;
            move_valid <= 0;
            next_turn <= 0;
            target_row <= 0;
            target_col <= 0;
            input_row <= 0;
            input_col <= 0;
            lifted_piece <= 0;
            is_white_turn <= 1;
            prev_sensor_state <= 0;
            move_count <= 0;
            promotion_detected <= 0;
            for (i = 0; i < 56; i = i + 1) begin
                moves[i] <= 0;
            end
        end else begin
            // Update previous sensor state
            prev_sensor_state <= sensor_state;

            // Unpack board_flat_in
            for (i = 0; i < 64; i = i + 1) begin
                board_in[i] = board_flat_in[i*4+:4];
            end

            case (state)
                IDLE: begin
                    move_valid <= 0;
                    next_turn <= 0;
                    for (r = 0; r < 8; r = r + 1) begin
                        for (c = 0; c < 8; c = c + 1) begin
                            if (prev_sensor_state[get_flat_index(r, c)] == 1 && sensor_state[get_flat_index(r, c)] == 0) begin
                                input_row <= r;
                                input_col <= c;
                                lifted_piece <= board_in[get_flat_index(r, c)];
                                is_white_piece <= (board_in[get_flat_index(r, c)][3] == 0) && (board_in[get_flat_index(r, c)] != 0);
                            end
                        end
                    end
                end

                LIFTED: begin
                    // Skip if lifted piece is invalid
                    if (lifted_piece == EMPTY) begin
                        next_state = IDLE;
                    end else begin
                        
                        move_count <= 0;
                        promotion_detected <= 0;
                        for (i = 0; i < 56; i = i + 1) begin
                            moves[i] <= 0;
                        end

                        // Copy input position
                        row = input_row;
                        col = input_col;
                        piece = lifted_piece;
                        is_white = is_white_piece;

                        case (piece)
                            W_PAWN: begin
                                if (row < 7 && board_in[get_flat_index(row + 1, col)] == EMPTY) begin
                                    if (move_count < 28) begin
                                        moves[move_count * 2] <= row + 1;
                                        moves[move_count * 2 + 1] <= col;
                                        if (row + 1 == 7) promotion_detected <= 1;
                                        move_count <= move_count + 1;
                                    end
                                    if (row == 1 && board_in[get_flat_index(row + 2, col)] == EMPTY) begin
                                        if (move_count < 28) begin
                                            moves[move_count * 2] <= row + 2;
                                            moves[move_count * 2 + 1] <= col;
                                            move_count <= move_count + 1;
                                        end
                                    end
                                end
                                if (row < 7 && col > 0) begin
                                    target_piece = board_in[get_flat_index(row + 1, col - 1)];
                                    if (target_piece != EMPTY && target_piece[3] == 1) begin
                                        if (move_count < 28) begin
                                            moves[move_count * 2] <= row + 1;
                                            moves[move_count * 2 + 1] <= col - 1;
                                            if (row + 1 == 7) promotion_detected <= 1;
                                            move_count <= move_count + 1;
                                        end
                                    end
                                end
                                if (row < 7 && col < 7) begin
                                    target_piece = board_in[get_flat_index(row + 1, col + 1)];
                                    if (target_piece != EMPTY && target_piece[3] == 1) begin
                                        if (move_count < 28) begin
                                            moves[move_count * 2] <= row + 1;
                                            moves[move_count * 2 + 1] <= col + 1;
                                            if (row + 1 == 7) promotion_detected <= 1;
                                            move_count <= move_count + 1;
                                        end
                                    end
                                end
                            end

                            B_PAWN: begin
                                if (row > 0 && board_in[get_flat_index(row - 1, col)] == EMPTY) begin
                                    if (move_count < 28) begin
                                        moves[move_count * 2] <= row - 1;
                                        moves[move_count * 2 + 1] <= col;
                                        if (row - 1 == 0) promotion_detected <= 1;
                                        move_count <= move_count + 1;
                                    end
                                    if (row == 6 && board_in[get_flat_index(row - 2, col)] == EMPTY) begin
                                        if (move_count < 28) begin
                                            moves[move_count * 2] <= row - 2;
                                            moves[move_count * 2 + 1] <= col;
                                            move_count <= move_count + 1;
                                        end
                                    end
                                end
                                if (row > 0 && col > 0) begin
                                    target_piece = board_in[get_flat_index(row - 1, col - 1)];
                                    if (target_piece != EMPTY && target_piece[3] == 0) begin
                                        if (move_count < 28) begin
                                            moves[move_count * 2] <= row - 1;
                                            moves[move_count * 2 + 1] <= col - 1;
                                            if (row - 1 == 0) promotion_detected <= 1;
                                            move_count <= move_count + 1;
                                        end
                                    end
                                end
                                if (row > 0 && col < 7) begin
                                    target_piece = board_in[get_flat_index(row - 1, col + 1)];
                                    if (target_piece != EMPTY && target_piece[3] == 0) begin
                                        if (move_count < 28) begin
                                            moves[move_count * 2] <= row - 1;
                                            moves[move_count * 2 + 1] <= col + 1;
                                            if (row - 1 == 0) promotion_detected <= 1;
                                            move_count <= move_count + 1;
                                        end
                                    end
                                end
                            end

                            W_ROOK, B_ROOK: begin
                                for (d = 0; d < 4; d = d + 1) begin
                                    for (step = 1; step < 8; step = step + 1) begin
                                        new_row = row + step * directions[d][0];
                                        new_col = col + step * directions[d][1];
                                        if (new_row >= 8 || new_col >= 8 || new_row < 0 || new_col < 0 || move_count >= 28) begin
                                            step = 8;
                                        end else begin
                                            target_piece = board_in[get_flat_index(new_row, new_col)];
                                            if (target_piece == EMPTY) begin
                                                moves[move_count * 2] <= new_row;
                                                moves[move_count * 2 + 1] <= new_col;
                                                move_count <= move_count + 1;
                                            end else begin
                                                if (is_white && target_piece[3] == 1) begin
                                                    moves[move_count * 2] <= new_row;
                                                    moves[move_count * 2 + 1] <= new_col;
                                                    move_count <= move_count + 1;
                                                end else if (!is_white && target_piece[3] == 0 && target_piece != EMPTY) begin
                                                    moves[move_count * 2] <= new_row;
                                                    moves[move_count * 2 + 1] <= new_col;
                                                    move_count <= move_count + 1;
                                                end
                                                step = 8;
                                            end
                                        end
                                    end
                                end
                            end

                            W_BISHOP, B_BISHOP: begin
                                for (d = 4; d < 8; d = d + 1) begin
                                    for (step = 1; step < 8; step = step + 1) begin
                                        new_row = row + step * directions[d][0];
                                        new_col = col + step * directions[d][1];
                                        if (new_row >= 8 || new_col >= 8 || new_row < 0 || new_col < 0 || move_count >= 28) begin
                                            step = 8;
                                        end else begin
                                            target_piece = board_in[get_flat_index(new_row, new_col)];
                                            if (target_piece == EMPTY) begin
                                                moves[move_count * 2] <= new_row;
                                                moves[move_count * 2 + 1] <= new_col;
                                                move_count <= move_count + 1;
                                            end else if ((is_white && target_piece[3] == 1) || (!is_white && target_piece[3] == 0 && target_piece != EMPTY)) begin
                                                moves[move_count * 2] <= new_row;
                                                moves[move_count * 2 + 1] <= new_col;
                                                move_count <= move_count + 1;
                                                step = 8;
                                            end else begin
                                                step = 8;
                                            end
                                        end
                                    end
                                end
                            end

                            W_QUEEN, B_QUEEN: begin
                                for (d = 0; d < 8; d = d + 1) begin
                                    for (step = 1; step < 8; step = step + 1) begin
                                        new_row = row + step * directions[d][0];
                                        new_col = col + step * directions[d][1];
                                        if (new_row >= 8 || new_col >= 8 || new_row < 0 || new_col < 0 || move_count >= 28) begin
                                            step = 8;
                                        end else begin
                                            target_piece = board_in[get_flat_index(new_row, new_col)];
                                            if (target_piece == EMPTY) begin
                                                moves[move_count * 2] <= new_row;
                                                moves[move_count * 2 + 1] <= new_col;
                                                move_count <= move_count + 1;
                                            end else if ((is_white && target_piece[3] == 1) || (!is_white && target_piece[3] == 0 && target_piece != EMPTY)) begin
                                                moves[move_count * 2] <= new_row;
                                                moves[move_count * 2 + 1] <= new_col;
                                                move_count <= move_count + 1;
                                                step = 8;
                                            end else begin
                                                step = 8;
                                            end
                                        end
                                    end
                                end
                            end

                            W_KNIGHT, B_KNIGHT: begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    new_row = row + knight_moves[i][0];
                                    new_col = col + knight_moves[i][1];
                                    if (new_row >= 0 && new_row < 8 && new_col >= 0 && new_col < 8) begin
                                        if (move_count < 28) begin
                                            target_piece = board_in[get_flat_index(new_row, new_col)];
                                            if (target_piece == EMPTY) begin
                                                moves[move_count * 2] <= new_row;
                                                moves[move_count * 2 + 1] <= new_col;
                                                move_count <= move_count + 1;
                                            end else if ((is_white && target_piece[3] == 1) || (!is_white && target_piece[3] == 0 && target_piece != EMPTY)) begin
                                                moves[move_count * 2] <= new_row;
                                                moves[move_count * 2 + 1] <= new_col;
                                                move_count <= move_count + 1;
                                            end
                                        end
                                    end
                                end
                            end

                            W_KING, B_KING: begin
                                for (i = 0; i < 8; i = i + 1) begin
                                    new_row = row + king_moves[i][0];
                                    new_col = col + king_moves[i][1];
                                    if (new_row >= 0 && new_row < 8 && new_col >= 0 && new_col < 8) begin
                                        if (move_count < 28) begin
                                            target_piece = board_in[get_flat_index(new_row, new_col)];
                                            if (target_piece == EMPTY) begin
                                                moves[move_count * 2] <= new_row;
                                                moves[move_count * 2 + 1] <= new_col;
                                                move_count <= move_count + 1;
                                            end else if ((is_white && target_piece[3] == 1) || (!is_white && target_piece[3] == 0 && target_piece != EMPTY)) begin
                                                moves[move_count * 2] <= new_row;
                                                moves[move_count * 2 + 1] <= new_col;
                                                move_count <= move_count + 1;
                                            end
                                        end
                                    end
                                end
                            end

                            default: begin
                                move_count <= 0;
                            end
                        endcase
                    end
                end

                PLACED: begin
                    move_valid <= 0;
                    for (r = 0; r < 8; r = r + 1) begin
                        for (c = 0; c < 8; c = c + 1) begin
                            if (prev_sensor_state[get_flat_index(r, c)] == 0 && sensor_state[get_flat_index(r, c)] == 1 && 
                                !(r == input_row && c == input_col)) begin
                                target_row <= r;
                                target_col <= c;
                            end
                        end
                    end
                    
                    for (i = 0; i < move_count; i = i + 1) begin
                        if (moves[i*2] == target_row && moves[i*2+1] == target_col && is_white_turn == is_white_piece) begin
                            move_valid <= 1;
                            break;
                        end
                    end
                end

                UPDATE: begin
                    if (move_valid) begin
                        // Update board state
                        for (i = 0; i < 64; i = i + 1) begin
                            board_out[i] = board_in[i];
                        end

                        // Handle promotion
                        if (promotion_detected && (lifted_piece == W_PAWN || lifted_piece == B_PAWN)) begin
                            board_out[get_flat_index(target_row, target_col)] = (lifted_piece == W_PAWN) ? W_QUEEN : B_QUEEN;
                        end else begin
                            board_out[get_flat_index(target_row, target_col)] = lifted_piece;
                        end
                        board_out[get_flat_index(input_row, input_col)] = 0;

                        // Pack board_out into board_flat_out
                        for (i = 0; i < 64; i = i + 1) begin
                            board_flat_out[i*4+:4] = board_out[i];
                        end

                        // Switch turn
                        is_white_turn <= ~is_white_turn;
                        next_turn <= 1;
                    end else begin
                        // Revert to previous state on invalid move
                        for (i = 0; i < 64; i = i + 1) begin
                            board_flat_out[i*4+:4] = board_in[i];
                        end
                    end

                    // Reset flags
                    move_count <= 0;
                    promotion_detected <= 0;
                end

                default: begin
                    move_valid <= 0;
                    next_turn <= 0;
                    for (i = 0; i < 64; i = i + 1) begin
                        board_flat_out[i*4+:4] = board_in[i];
                    end
                end
            endcase
        end
    end
endmodule
