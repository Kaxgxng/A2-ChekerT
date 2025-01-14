int rows = 8;
int cols = 8;
int tileSize = 100;
int[][] board = new int[rows][cols]; // 2D array for the game board
PVector selectedPiece = null; // Position of the selected piece
boolean isBlackTurn = true; // Black starts first
boolean capturing = false; // Indicates if there are multiple captures
String saveFileName = "savegame.txt"; // Filename for saving the game
boolean gameOver = false; // Indicates if the game is over
String winner = ""; // Stores the name of the winner

void settings() {
    size(cols * tileSize, (rows * tileSize) + 150); // Increased height for UI
}

void setup() {
    setupBoard(); // Initialize the game board
    textSize(32); // Set text size for UI
    textAlign(CENTER, CENTER);
}

void draw() {
    background(255);
    drawBoard();
    drawPieces();

    if (selectedPiece != null && !gameOver) {
        highlightSelectedPiece();
        drawPathway();
    }

    drawUI();
    if (!capturing) { // Only check game over when not in the middle of capturing
        checkGameOver(); // Check if the game has ended after each turn
    }
}

void setupBoard() {
    // Set the initial positions of pieces on the board
    for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
            if ((row + col) % 2 == 1) { // Playable squares
                if (row < 2) { // Place white pieces in the top 2 rows
                    board[row][col] = 1; // White piece
                } else if (row > 5) { // Place black pieces in the bottom 2 rows
                    board[row][col] = 2; // Black piece
                } else {
                    board[row][col] = 0; // Empty square
                }
            } else {
                board[row][col] = -1; // Non-playable square
            }
        }
    }
}

void drawBoard() {
    for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
            if (board[row][col] == -1) {
                fill(200); // Gray for non-playable squares
            } else if ((row + col) % 2 == 0) {
                fill(255); // White for white squares
            } else {
                fill(100); // Black for black squares
            }
            rect(col * tileSize, row * tileSize, tileSize, tileSize);
        }
    }
}

void drawPieces() {
    for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
            if (board[row][col] == 1 || board[row][col] == 3) { // White pieces and kings
                fill(board[row][col] == 1 ? 255 : color(255, 215, 0)); // White or gold king
                ellipse(col * tileSize + tileSize / 2, row * tileSize + tileSize / 2, tileSize * 0.8, tileSize * 0.8);
                if (board[row][col] == 3) {
                    fill(0);
                    text("K", col * tileSize + tileSize / 2, row * tileSize + tileSize / 2);
                }
            } else if (board[row][col] == 2 || board[row][col] == 4) { // Black pieces and kings
                fill(board[row][col] == 2 ? 0 : color(0, 0, 255)); // Black or blue king
                ellipse(col * tileSize + tileSize / 2, row * tileSize + tileSize / 2, tileSize * 0.8, tileSize * 0.8);
                if (board[row][col] == 4) {
                    fill(255);
                    text("K", col * tileSize + tileSize / 2, row * tileSize + tileSize / 2);
                }
            }
        }
    }
}

void highlightSelectedPiece() {
    stroke(255, 0, 0);
    strokeWeight(4);
    noFill();
    rect(selectedPiece.x * tileSize, selectedPiece.y * tileSize, tileSize, tileSize);
    strokeWeight(1);
}

void drawPathway() {
    int oldCol = int(selectedPiece.x);
    int oldRow = int(selectedPiece.y);
    int piece = board[oldRow][oldCol];

    if (isCaptureMoveAvailable(oldRow, oldCol)) {
        int[][] directions = getCaptureDirections(oldRow, oldCol);
        for (int[] dir : directions) {
            int enemyRow = oldRow + dir[0] / 2;
            int enemyCol = oldCol + dir[1] / 2;
            int landingRow = oldRow + dir[0];
            int landingCol = oldCol + dir[1];

            if (isWithinBounds(landingRow, landingCol) && board[landingRow][landingCol] == 0 &&
                isEnemy(piece, board[enemyRow][enemyCol])) {
                fill(0, 255, 0, 150); // Green for capturing
                rect(landingCol * tileSize, landingRow * tileSize, tileSize, tileSize);
            }
        }
    } else {
        // Highlight possible moves
        int[][] directions = getMoveDirections(oldRow, oldCol);
        for (int[] dir : directions) {
            if (piece == 1 || piece == 2) { // Normal pieces
                int newRow = oldRow + dir[0];
                int newCol = oldCol + dir[1];

                if (isValidMove(oldRow, oldCol, newRow, newCol)) {
                    fill(0, 255, 0, 150); // Green for valid move
                    rect(newCol * tileSize, newRow * tileSize, tileSize, tileSize);
                }
            } else { // Kings can move multiple squares
                for (int distance = 1; distance < rows; distance++) {
                    int newRow = oldRow + dir[0] * distance;
                    int newCol = oldCol + dir[1] * distance;

                    if (!isWithinBounds(newRow, newCol)) break; // Out of bounds

                    if (board[newRow][newCol] == 0) {
                        fill(0, 255, 0, 150); // Green for valid move
                        rect(newCol * tileSize, newRow * tileSize, tileSize, tileSize);
                    } else {
                        if (isEnemy(piece, board[newRow][newCol])) {
                            // Check for capture move
                            int landingRow = newRow + dir[0];
                            int landingCol = newCol + dir[1];

                            if (isWithinBounds(landingRow, landingCol) && board[landingRow][landingCol] == 0) {
                                fill(0, 255, 0, 150); // Highlight the landing square for capture
                                rect(landingCol * tileSize, landingRow * tileSize, tileSize, tileSize);
                            }
                        }
                        break; // Stop if another piece is blocking
                    }
                }
            }
        }
    }
}

void mousePressed() {
    if (gameOver) return; // Skip if the game is over
    if (mouseY > rows * tileSize) return; // Ignore clicks below the board
    int col = mouseX / tileSize;
    int row = mouseY / tileSize;

    if (!isWithinBounds(row, col)) return; // Ensure within bounds

    int piece = board[row][col];

    // Clicked on a piece
    if (selectedPiece == null && (piece != 0 && piece != -1)) {
        // Allow only current player's pieces to be selected
        if ((isBlackTurn && (piece == 2 || piece == 4)) ||
            (!isBlackTurn && (piece == 1 || piece == 3))) {

            // Prioritize capture moves if available
            if (anyCaptureAvailable(piece)) {
                if (isCaptureMoveAvailable(row, col)) {
                    selectedPiece = new PVector(col, row); // Select the capturing piece
                }
            } else {
                selectedPiece = new PVector(col, row); // Select any piece
            }
        }
    } else if (selectedPiece != null) {
        int oldCol = int(selectedPiece.x);
        int oldRow = int(selectedPiece.y);

        // Attempt to move or capture
        if (isValidMove(oldRow, oldCol, row, col) || isCaptureMove(oldRow, oldCol, row, col)) {
            movePiece(oldRow, oldCol, row, col); // Move the piece
            if (!capturing) {
                selectedPiece = null; // Clear selection if not in multiple capture
            }
        } else {
            println("Invalid move from (" + oldRow + ", " + oldCol + ") to (" + row + ", " + col + ")");
        }
    }
}


void mouseClicked() {
    // Save, Load, or Reset game state based on button clicks
    if (mouseY > height - 100 && mouseY < height - 50) {
        if (mouseX > 10 && mouseX < 110) {
            saveGame(); // Save the game
        } else if (mouseX > 120 && mouseX < 220) {
            loadGame(); // Load the game
        } else if (mouseX > 230 && mouseX < 330) {
            resetGame(); // Reset the game
        }
    }
}

void movePiece(int oldRow, int oldCol, int newRow, int newCol) {
    // Check if it's a capture move
    if (isCaptureMove(oldRow, oldCol, newRow, newCol)) {
        int capturedRow = (oldRow + newRow) / 2;
        int capturedCol = (oldCol + newCol) / 2;

        if (isValidKingCapture(oldRow, oldCol, newRow, newCol)) {
            // Remove enemy piece after long distance King capture
            removeCapturedPiece(oldRow, oldCol, newRow, newCol);
        } else {
            // Regular capture for normal pieces
            if (isEnemy(board[oldRow][oldCol], board[capturedRow][capturedCol])) {
                board[capturedRow][capturedCol] = 0; // Remove captured piece
                println("Captured piece at (" + capturedRow + ", " + capturedCol + ")");
            }
        }

        // Move the piece after capture
        board[newRow][newCol] = board[oldRow][oldCol];
        board[oldRow][oldCol] = 0;

        // Check for King promotion
        promoteToKing(newRow, newCol);

        // Check if multiple captures are possible
        if (isCaptureMoveAvailable(newRow, newCol)) {
            selectedPiece = new PVector(newCol, newRow); // Keep King for multiple capture
            capturing = true;
        } else {
            capturing = false;
            endTurn(); // No more captures, switch turn
        }
    } 
    // Normal move
    else {
        board[newRow][newCol] = board[oldRow][oldCol];
        board[oldRow][oldCol] = 0;
        promoteToKing(newRow, newCol);
        endTurn(); // Switch turn after normal move
    }
}

void endTurn() {
    // Switch player turn
    isBlackTurn = !isBlackTurn;
}

void promoteToKing(int row, int col) {
    if (board[row][col] == 1 && row == rows - 1) { // White piece reaches the bottom row
        board[row][col] = 3; // Promote to White king
        println("White piece promoted to king at (" + row + ", " + col + ")");
    } else if (board[row][col] == 2 && row == 0) { // Black piece reaches the top row
        board[row][col] = 4; // Promote to Black king
        println("Black piece promoted to king at (" + row + ", " + col + ")");
    } else {
        println("No promotion at (" + row + ", " + col + ")");
    }
}

boolean isValidMove(int oldRow, int oldCol, int newRow, int newCol) {
    if (!isWithinBounds(newRow, newCol)) return false; // Check bounds
    if (board[newRow][newCol] != 0) return false; // Target square must be empty

    int piece = board[oldRow][oldCol];

    // Check if any capture is available for the current player
    if (anyCaptureAvailable(piece)) {
        return false; // Prevent movement if a capture is available
    }

    // Regular pieces move only 1 square diagonally forward
    if (piece == 1 || piece == 2) { 
        int direction = (piece == 1) ? 1 : -1; // White moves down, Black moves up
        if (newRow == oldRow + direction && abs(newCol - oldCol) == 1) {
            return true; // Valid regular move
        }
    } else if (piece == 3 || piece == 4) { // Kings can move multiple squares diagonally
        if (abs(newRow - oldRow) == abs(newCol - oldCol)) {
            if (isPathClear(oldRow, oldCol, newRow, newCol)) {
                return true; // Valid king move
            }
        }
    }
    return false; // Invalid move
}


boolean isValidKingCapture(int oldRow, int oldCol, int newRow, int newCol) {
    int rowStep = (newRow - oldRow) > 0 ? 1 : -1;
    int colStep = (newCol - oldCol) > 0 ? 1 : -1;
    
    int row = oldRow + rowStep;
    int col = oldCol + colStep;
    boolean foundEnemy = false; // Track if King encountered an enemy piece
    
    while (row != newRow && col != newCol) {
        if (board[row][col] != 0) {
            if (isEnemy(board[oldRow][oldCol], board[row][col])) {
                if (foundEnemy) return false; // More than one enemy, invalid
                foundEnemy = true; // Found exactly one enemy to capture
            } else {
                return false; // A friendly piece is blocking the path
            }
        }
        row += rowStep;
        col += colStep;
    }

    return foundEnemy; // Return true if exactly one enemy was found and captured
}

boolean isCaptureMove(int oldRow, int oldCol, int newRow, int newCol) {
    int piece = board[oldRow][oldCol];

    // Regular piece capture (must move diagonally two squares)
    if (piece == 1 || piece == 2) {
        if (abs(oldRow - newRow) == 2 && abs(oldCol - newCol) == 2) {
            int capturedRow = (oldRow + newRow) / 2;
            int capturedCol = (oldCol + newCol) / 2;
            if (isEnemy(piece, board[capturedRow][capturedCol])) {
                // Ensure that the piece moves forward only
                if ((piece == 1 && newRow > oldRow) || (piece == 2 && newRow < oldRow)) {
                    return true; // Valid capture move for normal piece
                }
            }
        }
    } 
    // King capture
    else if (piece == 3 || piece == 4) {
        return isValidKingCapture(oldRow, oldCol, newRow, newCol); // Call the King capture function
    }

    return false; // Not a valid capture move
}

boolean isPathClear(int oldRow, int oldCol, int newRow, int newCol) {
    int rowStep = (newRow - oldRow) > 0 ? 1 : -1;
    int colStep = (newCol - oldCol) > 0 ? 1 : -1;

    int row = oldRow + rowStep;
    int col = oldCol + colStep;

    while (row != newRow && col != newCol) {
        if (board[row][col] != 0) return false; // If there's a piece blocking the path, return false
        row += rowStep;
        col += colStep;
    }
    return true; // Path is clear
}

boolean isCaptureMoveAvailable(int row, int col) {
    int piece = board[row][col];
    int[][] directions = getCaptureDirections(row, col); // Directions for capturing

    for (int[] dir : directions) {
        int enemyRow = row + dir[0] / 2; // Position of the enemy piece to capture
        int enemyCol = col + dir[1] / 2;
        int landingRow = row + dir[0]; // Landing position after capture
        int landingCol = col + dir[1];

        // Check if the landing position is within bounds, empty, and the enemy piece exists
        if (isWithinBounds(landingRow, landingCol) && board[landingRow][landingCol] == 0 &&
            isEnemy(piece, board[enemyRow][enemyCol])) {

            // Check the direction of capture for normal pieces
            if ((piece == 1 && landingRow > row) || (piece == 2 && landingRow < row) || piece >= 3) {
                return true; // Valid capture direction
            }
        }
    }
    return false; // No valid capture moves
}

void removeCapturedPiece(int oldRow, int oldCol, int newRow, int newCol) {
    int rowStep = (newRow - oldRow) > 0 ? 1 : -1;
    int colStep = (newCol - oldCol) > 0 ? 1 : -1;

    int row = oldRow + rowStep;
    int col = oldCol + colStep;

    while (row != newRow && col != newCol) {
        if (isEnemy(board[oldRow][oldCol], board[row][col])) {
            board[row][col] = 0; // Remove captured piece
            println("Captured piece at (" + row + ", " + col + ")");
            return;
        }
        row += rowStep;
        col += colStep;
    }
}

int[][] getCaptureDirections(int row, int col) {
    // Directions for capturing (diagonal two squares)
    return new int[][] {
        {2, 2}, {2, -2}, {-2, 2}, {-2, -2} // Down-right, down-left, up-right, up-left
    };
}

int[][] getMoveDirections(int row, int col) {
    // Return possible move directions for the piece
    return new int[][]{
        {1, 1}, {1, -1}, {-1, 1}, {-1, -1} // Down-right, down-left, up-right, up-left
    };
}

boolean isEnemy(int piece, int target) {
    return (piece == 1 || piece == 3) && (target == 2 || target == 4) || 
           (piece == 2 || piece == 4) && (target == 1 || target == 3);
}

boolean isWithinBounds(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < cols;
}

void checkGameOver() {
    boolean whiteRemaining = false;
    boolean blackRemaining = false;

    for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
            if (board[row][col] == 1 || board[row][col] == 3) {
                whiteRemaining = true; // White pieces exist
            }
            if (board[row][col] == 2 || board[row][col] == 4) {
                blackRemaining = true; // Black pieces exist
            }
        }
    }

    if (!whiteRemaining) {
        gameOver = true;
        winner = "Black wins!";
    } else if (!blackRemaining) {
        gameOver = true;
        winner = "White wins!";
    }
}

void drawUI() {
    fill(0);
    text("Turn: " + (isBlackTurn ? "Black" : "White"), width / 1.5, height - 75);
    if (gameOver) {
        textSize(48);
        text(winner, width / 2, height / 2);
    }
    // Add buttons for Save, Load, and Reset
    fill(200);
    rect(10, height - 100, 100, 50);
    fill(0);
    text("Save", 10 + 50, height - 75);
    
    fill(200);
    rect(120, height - 100, 100, 50);
    fill(0);
    text("Load", 120 + 50, height - 75);
    
    fill(200);
    rect(230, height - 100, 100, 50);
    fill(0);
    text("Reset", 230 + 50, height - 75);
}

void saveGame() {
    PrintWriter output = createWriter(saveFileName);
    // Save the game state including the board, whose turn it is, and if a capture is ongoing
    for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
            output.print(board[row][col] + " "); // Save each board position
        }
        output.println(); // Newline after each row
    }
    // Save additional game state info
    output.println(isBlackTurn);
    output.println(capturing);
    output.println(gameOver);
    output.println(winner);
    output.flush(); // Ensure the data is written to the file
    output.close();
    println("Game saved successfully.");
}

void loadGame() {
    String[] lines = loadStrings(saveFileName);
    if (lines == null || lines.length == 0) {
        println("No saved game found.");
        return;
    }

    // Load board state from the file
    for (int row = 0; row < rows; row++) {
        String[] tokens = split(trim(lines[row]), " ");
        for (int col = 0; col < cols; col++) {
            board[row][col] = int(tokens[col]);
        }
    }

    // Load other game states
    isBlackTurn = Boolean.parseBoolean(lines[rows].trim());
    capturing = Boolean.parseBoolean(lines[rows + 1].trim());
    gameOver = Boolean.parseBoolean(lines[rows + 2].trim());
    winner = lines[rows + 3].trim();
    
    println("Game loaded successfully.");
}

void resetGame() {
    setupBoard(); // Reset the board
    isBlackTurn = true; // Reset turn to black
    gameOver = false; // Reset game over status
    winner = ""; // Clear winner
    println("Game reset.");
}

boolean anyCaptureAvailable(int playerPiece) {
    for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
            if ((playerPiece == 1 || playerPiece == 3) && (board[row][col] == 1 || board[row][col] == 3)) {
                if (isCaptureMoveAvailable(row, col)) return true;
            } else if ((playerPiece == 2 || playerPiece == 4) && (board[row][col] == 2 || board[row][col] == 4)) {
                if (isCaptureMoveAvailable(row, col)) return true;
            }
        }
    }
    return false;
}
