module piece_identifier(
    input wire clk,                         // System clock
    input wire rst,                         // Reset signal
    input wire white_turn,                  // 1 for white's turn, 0 for black's turn
    input wire [63:0] sensor_state,         // Current sensor readings (1 = piece, 0 = no piece, flattened)
    input wire [63:0] prev_sensor_state,    // Previous sensor readings (flattened)
    input wire [255:0] board,               // Current board state (flattened, 64 x 4-bit segments)
    output reg [255:0] new_board,           // Updated board after a valid move (flattened, 64 x 4-bit segments)
    output reg move_executed,               // Pulses high when a valid move is executed
    output reg invalid_move,                // High when an invalid move is detected until corrected
    output reg [2:0] start_row, start_col,  // Starting position of the move
    output reg [2:0] end_row, end_col,      // Ending position of the move
    output reg [3:0] lifted_piece           // Piece being moved
);

    // Parameters for piece representation
    localparam EMPTY = 4'h0;
    localparam W_PAWN = 4'h1;
    localparam W_KING = 4'h2;
    localparam W_QUEEN = 4'h3;
    localparam W_ROOK = 4'h4;
    localparam W_KNIGHT = 4'h5;
    localparam W_BISHOP = 4'h6;
    localparam B_PAWN = 4'hF;   // -1 in 4-bit 2's complement
    localparam B_KING = 4'hE;   // -2 in 4-bit 2's complement
    localparam B_QUEEN = 4'hD;  // -3 in 4-bit 2's complement
    localparam B_ROOK = 4'hC;   // -4 in 4-bit 2's complement
    localparam B_KNIGHT = 4'hB; // -5 in 4-bit 2's complement
    localparam B_BISHOP = 4'hA; // -6 in 4-bit 2's complement

    // State machine states
    localparam IDLE = 3'b000;
    localparam DETECT_LIFT = 3'b001;
    localparam DETECT_LIFT_SCAN = 3'b010;
    localparam WAIT_PLACEMENT = 3'b011;
    localparam WAIT_PLACEMENT_SCAN = 3'b100;
    localparam VALIDATE_MOVE = 3'b101;
    localparam INVALID_WAIT = 3'b110;

    // Internal registers
    reg [2:0] state;                    // Current state
    reg [2:0] orig_row, orig_col;       // Original position of lifted piece
    reg move_in_progress;               // Tracks if a valid move is being processed
    reg valid_move;                     // For VALIDATE_MOVE state
    reg [5:0] scan_idx;                 // Index for scanning in DETECT_LIFT, WAIT_PLACEMENT
    reg [5:0] i;                        // Index for board position (fixes "i is not declared" error)

    // Initialize
    initial begin
        state = IDLE;
        move_executed = 0;
        invalid_move = 0;
        move_in_progress = 0;
        lifted_piece = EMPTY;
        start_row = 0;
        start_col = 0;
        end_row = 0;
        end_col = 0;
        orig_row = 0;
        orig_col = 0;
        new_board = 256'h0; // Initialize all 256 bits to 0 (EMPTY)
        i = 0;
        scan_idx = 0;
    end

    // Main state machine
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            move_executed <= 0;
            invalid_move <= 0;
            move_in_progress <= 0;
            lifted_piece <= EMPTY;
            start_row <= 0;
            start_col <= 0;
            end_row <= 0;
            end_col <= 0;
            orig_row <= 0;
            orig_col <= 0;
            new_board <= board; // Copy initial board state
            scan_idx <= 0;
            i <= 0;
        end else begin
            // Default outputs
            move_executed <= 0;
            invalid_move <= invalid_move; // Maintain unless changed

            case (state)
                IDLE: begin
                    if (!move_in_progress) begin
                        state <= DETECT_LIFT;
                        scan_idx <= 0;
                    end
                end

                DETECT_LIFT: begin
                    state <= DETECT_LIFT_SCAN;
                    scan_idx <= 0;
                end

                DETECT_LIFT_SCAN: begin
                    if (scan_idx < 64) begin
                        if (prev_sensor_state[scan_idx] && !sensor_state[scan_idx]) begin
                            // Check if there's a piece
                            if (board[scan_idx*4 +: 4] != EMPTY) begin
                                // Check if piece matches the turn
                                if ((white_turn && board[scan_idx*4 + 3] == 0) ||
                                    (!white_turn && board[scan_idx*4 + 3] == 1)) begin
                                    // Valid piece: proceed to placement
                                    lifted_piece <= board[scan_idx*4 +: 4];
                                    start_row <= scan_idx[5:3];
                                    start_col <= scan_idx[2:0];
                                    orig_row <= scan_idx[5:3];
                                    orig_col <= scan_idx[2:0];
                                    move_in_progress <= 1;
                                    invalid_move <= 0;
                                    state <= WAIT_PLACEMENT;
                                end else begin
                                    // Opponent's piece: signal invalid move
                                    lifted_piece <= board[scan_idx*4 +: 4];
                                    orig_row <= scan_idx[5:3];
                                    orig_col <= scan_idx[2:0];
                                    invalid_move <= 1;
                                    move_in_progress <= 0;
                                    state <= INVALID_WAIT;
                                end
                            end
                        end
                        scan_idx <= scan_idx + 1;
                    end else begin
                        state <= DETECT_LIFT;
                    end
                end

                WAIT_PLACEMENT: begin
                    state <= WAIT_PLACEMENT_SCAN;
                    scan_idx <= 0;
                end

                WAIT_PLACEMENT_SCAN: begin
                    if (scan_idx == orig_row * 8 + orig_col && sensor_state[scan_idx] == 1) begin
                        // Piece returned to original position, restart scan
                        state <= WAIT_PLACEMENT;
                    end else if (scan_idx < 64) begin
                        if ((scan_idx[5:3] != start_row || scan_idx[2:0] != start_col) &&
                            ((!prev_sensor_state[scan_idx] && sensor_state[scan_idx]) || // Non-capture
                             (prev_sensor_state[scan_idx] && sensor_state[scan_idx]))) begin // Capture
                            end_row <= scan_idx[5:3];
                            end_col <= scan_idx[2:0];
                            state <= VALIDATE_MOVE;
                        end
                        scan_idx <= scan_idx + 1;
                    end else begin
                        state <= WAIT_PLACEMENT;
                    end
                end

                VALIDATE_MOVE: begin
                    valid_move = 0;
                    i = end_row * 8 + end_col; // Fixed by declaring 'i' as reg

                    // Basic checks: different position, destination empty or opponent
                    if (start_row != end_row || start_col != end_col) begin
                        if ((white_turn && (board[i*4 +: 4] == EMPTY || (board[i*4 + 3] == 1 && board[i*4 +: 4] != EMPTY))) ||
                            (!white_turn && (board[i*4 +: 4] == EMPTY || (board[i*4 + 3] == 0 && board[i*4 +: 4] != EMPTY)))) begin
                            // Piece-specific move validation
                            case (lifted_piece)
                                W_PAWN, B_PAWN: valid_move = validate_pawn_move(1'b0);
                                W_ROOK, B_ROOK: valid_move = validate_rook_move(1'b0);
                                W_KNIGHT, B_KNIGHT: valid_move = validate_knight_move(1'b0);
                                W_BISHOP, B_BISHOP: valid_move = validate_bishop_move(1'b0);
                                W_QUEEN, B_QUEEN: valid_move = validate_queen_move(1'b0);
                                W_KING, B_KING: valid_move = validate_king_move(1'b0);
                                default: valid_move = 0;
                            endcase
                        end
                    end

                    if (valid_move) begin
                        // Create updated board with the executed move
                        new_board = board;
                        new_board[end_row * 8 * 4 + end_col * 4 +: 4] = lifted_piece;
                        new_board[start_row * 8 * 4 + start_col * 4 +: 4] = EMPTY;
                        
                        // Register successful move
                        move_executed <= 1;
                        move_in_progress <= 0;
                        invalid_move <= 0;
                        state <= IDLE;
                    end else begin
                        // Invalid move - wait for piece to return
                        invalid_move <= 1;
                        state <= INVALID_WAIT;
                    end
                end

                INVALID_WAIT: begin
                    i = orig_row * 8 + orig_col;
                    if (sensor_state[i]) begin
                        invalid_move <= 0;
                        move_in_progress <= 0;
                        lifted_piece <= EMPTY;
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

function validate_pawn_move(input reg dummy);
    reg [3:0] delta_row;
    reg [3:0] delta_col;
    reg valid;
    reg [5:0] end_idx, mid_idx;
    begin
        end_idx = end_row * 8 + end_col;
        valid = 0;
        
        // Direction dependent on color
        if (white_turn) begin
            // White pawn moves
            if (lifted_piece == W_PAWN) begin
                // Calculate delta - how far the pawn is moving
                delta_row = end_row - start_row; // White pawns move up (increasing row)
                delta_col = (end_col > start_col) ? (end_col - start_col) : (start_col - end_col);
                
                // Forward one square (must be to empty square)
                if (delta_row == 1 && delta_col == 0 && board[end_idx*4 +: 4] == EMPTY) begin
                    valid = 1;
                end
                // Forward two squares from initial rank (must be to empty square with clear path)
                else if (start_row == 1 && delta_row == 2 && delta_col == 0 && 
                         board[end_idx*4 +: 4] == EMPTY) begin
                    mid_idx = (start_row + 1) * 8 + start_col;
                    if (board[mid_idx*4 +: 4] == EMPTY) begin
                        valid = 1;
                    end
                end
                // Diagonal capture - must capture opponent's piece
                else if (delta_row == 1 && delta_col == 1) begin
                    // Check for black pieces to capture (MSB will be 1 for black)
                    if (board[end_idx*4 +: 4] != EMPTY && board[end_idx*4 + 3] == 1) begin
                        valid = 1;
                    end
                    // Note: En passant capture would be added here if implemented
                end
            end
        end else begin
            // Black pawn moves
            if (lifted_piece == B_PAWN) begin
                // Calculate delta - how far the pawn is moving
                delta_row = start_row - end_row; // Black pawns move down (decreasing row)
                delta_col = (end_col > start_col) ? (end_col - start_col) : (start_col - end_col);
                
                // Forward one square (must be to empty square)
                if (delta_row == 1 && delta_col == 0 && board[end_idx*4 +: 4] == EMPTY) begin
                    valid = 1;
                end
                // Forward two squares from initial rank (must be to empty square with clear path)
                else if (start_row == 6 && delta_row == 2 && delta_col == 0 && 
                         board[end_idx*4 +: 4] == EMPTY) begin
                    mid_idx = (start_row - 1) * 8 + start_col;
                    if (board[mid_idx*4 +: 4] == EMPTY) begin
                        valid = 1;
                    end
                end
                // Diagonal capture - must capture opponent's piece
                else if (delta_row == 1 && delta_col == 1) begin
                    // Check for white pieces to capture (MSB will be 0 for white)
                    if (board[end_idx*4 +: 4] != EMPTY && board[end_idx*4 + 3] == 0) begin
                        valid = 1;
                    end
                    // Note: En passant capture would be added here if implemented
                end
            end
        end
        
        validate_pawn_move = valid;
    end
endfunction

    // Rook move validation (Loop-free version)
    function validate_rook_move(input reg dummy);
        reg valid;
        reg [5:0] path_idx;
        reg path_clear;
        reg [2:0] delta_row, delta_col;
        begin
            path_clear = 1;
            valid = 0;

            // Must move along rank or file
            delta_row = (start_row > end_row) ? (start_row - end_row) : (end_row - start_row);
            delta_col = (start_col > end_col) ? (start_col - end_col) : (end_col - start_col);
            
            if (delta_row == 0 || delta_col == 0) begin // Moving along row or column
                if (delta_row == 0) begin // Horizontal move
                    if (start_col < end_col) begin
                        // Moving right
                        if (start_col + 1 < end_col) begin path_idx = start_row * 8 + (start_col + 1); if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (start_col + 2 < end_col) begin path_idx = start_row * 8 + (start_col + 2); if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (start_col + 3 < end_col) begin path_idx = start_row * 8 + (start_col + 3); if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (start_col + 4 < end_col) begin path_idx = start_row * 8 + (start_col + 4); if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (start_col + 5 < end_col) begin path_idx = start_row * 8 + (start_col + 5); if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (start_col + 6 < end_col) begin path_idx = start_row * 8 + (start_col + 6); if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                    end else begin
                        // Moving left
                        if (end_col + 1 < start_col) begin path_idx = start_row * 8 + (end_col + 1); if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (end_col + 2 < start_col) begin path_idx = start_row * 8 + (end_col + 2); if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (end_col + 3 < start_col) begin path_idx = start_row * 8 + (end_col + 3); if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (end_col + 4 < start_col) begin path_idx = start_row * 8 + (end_col + 4); if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (end_col + 5 < start_col) begin path_idx = start_row * 8 + (end_col + 5); if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (end_col + 6 < start_col) begin path_idx = start_row * 8 + (end_col + 6); if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                    end
                end else begin // Vertical move
                    if (start_row < end_row) begin
                        // Moving down
                        if (start_row + 1 < end_row) begin path_idx = (start_row + 1) * 8 + start_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (start_row + 2 < end_row) begin path_idx = (start_row + 2) * 8 + start_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (start_row + 3 < end_row) begin path_idx = (start_row + 3) * 8 + start_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (start_row + 4 < end_row) begin path_idx = (start_row + 4) * 8 + start_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (start_row + 5 < end_row) begin path_idx = (start_row + 5) * 8 + start_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (start_row + 6 < end_row) begin path_idx = (start_row + 6) * 8 + start_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                    end else begin
                        // Moving up
                        if (end_row + 1 < start_row) begin path_idx = (end_row + 1) * 8 + start_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (end_row + 2 < start_row) begin path_idx = (end_row + 2) * 8 + start_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (end_row + 3 < start_row) begin path_idx = (end_row + 3) * 8 + start_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (end_row + 4 < start_row) begin path_idx = (end_row + 4) * 8 + start_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (end_row + 5 < start_row) begin path_idx = (end_row + 5) * 8 + start_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                        if (end_row + 6 < start_row) begin path_idx = (end_row + 6) * 8 + start_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0; end
                    end
                end

                if (path_clear) begin
                    valid = 1;
                    // Target square: must be empty or opponent's piece
                    path_idx = end_row * 8 + end_col;
                    if (board[path_idx*4 +: 4] != EMPTY) begin
                        // If target has a piece, it must be opponent's
                        if ((white_turn && board[path_idx*4 + 3] == 0) || 
                            (!white_turn && board[path_idx*4 + 3] == 1)) begin
                            valid = 0; // Can't capture own piece
                        end
                    end
                end
            end
            
            validate_rook_move = valid;
        end
    endfunction

    // Knight move validation
    function validate_knight_move(input reg dummy);
        reg [3:0] delta_row, delta_col;
        reg [5:0] end_idx;
        begin
            end_idx = end_row * 8 + end_col;
            delta_row = (end_row > start_row) ? (end_row - start_row) : (start_row - end_row);
            delta_col = (end_col > start_col) ? (end_col - start_col) : (start_col - end_col);
            
            // Knight moves in L-shape: 2+1 pattern
            validate_knight_move = ((delta_row == 2 && delta_col == 1) || (delta_row == 1 && delta_col == 2));
            
            // Target square: must be empty or opponent's piece
            if (validate_knight_move && board[end_idx*4 +: 4] != EMPTY) begin
                // If target has a piece, it must be opponent's
                if ((white_turn && board[end_idx*4 + 3] == 0) || 
                    (!white_turn && board[end_idx*4 + 3] == 1)) begin
                    validate_knight_move = 0; // Can't capture own piece
                end
            end
        end
    endfunction

    // Bishop move validation (Loop-free version)
    function validate_bishop_move(input reg dummy);
        reg valid;
        reg [5:0] path_idx;
        reg path_clear;
        reg [2:0] delta_row, delta_col;
        reg [2:0] row_step, col_step;
        reg [2:0] check_row, check_col;
        begin
            valid = 0;
            path_clear = 1;
            delta_row = (end_row > start_row) ? (end_row - start_row) : (start_row - end_row);
            delta_col = (end_col > start_col) ? (end_col - start_col) : (start_col - end_col);
            
            // Bishop moves diagonally (equal steps in row and column)
            if (delta_row == delta_col) begin
                row_step = (end_row > start_row) ? 1 : -1;
                col_step = (end_col > start_col) ? 1 : -1;

                // Check path is clear (unrolled for max 7 steps)
                check_row = start_row + row_step;
                check_col = start_col + col_step;
                if (delta_row > 1) begin
                    path_idx = check_row * 8 + check_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0;
                    check_row = check_row + row_step; check_col = check_col + col_step;
                end
                if (delta_row > 2) begin
                    path_idx = check_row * 8 + check_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0;
                    check_row = check_row + row_step; check_col = check_col + col_step;
                end
                if (delta_row > 3) begin
                    path_idx = check_row * 8 + check_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0;
                    check_row = check_row + row_step; check_col = check_col + col_step;
                end
                if (delta_row > 4) begin
                    path_idx = check_row * 8 + check_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0;
                    check_row = check_row + row_step; check_col = check_col + col_step;
                end
                if (delta_row > 5) begin
                    path_idx = check_row * 8 + check_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0;
                    check_row = check_row + row_step; check_col = check_col + col_step;
                end
                if (delta_row > 6) begin
                    path_idx = check_row * 8 + check_col; if (board[path_idx*4 +: 4] != EMPTY) path_clear = 0;
                end

                if (path_clear) begin
                    valid = 1;
                    // Target square: must be empty or opponent's piece
                    path_idx = end_row * 8 + end_col;
                    if (board[path_idx*4 +: 4] != EMPTY) begin
                        // If target has a piece, it must be opponent's
                        if ((white_turn && board[path_idx*4 + 3] == 0) || 
                            (!white_turn && board[path_idx*4 + 3] == 1)) begin
                            valid = 0; // Can't capture own piece
                        end
                    end
                end
            end
            
            validate_bishop_move = valid;
        end
    endfunction

    // Queen move validation (combines rook and bishop movement)
    function validate_queen_move(input reg dummy);
        begin
            validate_queen_move = (validate_rook_move(dummy) || validate_bishop_move(dummy));
        end
    endfunction

    // King move validation
    function validate_king_move(input reg dummy);
        reg [3:0] delta_row, delta_col;
        reg [5:0] end_idx;
        begin
            end_idx = end_row * 8 + end_col;
            delta_row = (end_row > start_row) ? (end_row - start_row) : (start_row - end_row);
            delta_col = (end_col > start_col) ? (end_col - start_col) : (start_col - end_col);
            
            // King moves one square in any direction
            validate_king_move = (delta_row <= 1 && delta_col <= 1 && (delta_row != 0 || delta_col != 0));
            
            // Target square: must be empty or opponent's piece
            if (validate_king_move && board[end_idx*4 +: 4] != EMPTY) begin
                // If target has a piece, it must be opponent's
                if ((white_turn && board[end_idx*4 + 3] == 0) || 
                    (!white_turn && board[end_idx*4 + 3] == 1)) begin
                    validate_king_move = 0; // Can't capture own piece
                end
            end
        end
    endfunction

endmodule
