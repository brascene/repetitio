//
//  XOView.swift
//  YRepeat
//
//  Created for XO (Tic Tac Toe) game
//

import SwiftUI
import Combine

enum XOPlayer: String {
    case x = "X"
    case o = "O"

    var symbol: String {
        self.rawValue
    }

    var color: Color {
        switch self {
        case .x: return .blue
        case .o: return .red
        }
    }
}

enum GameState: Equatable {
    case playing
    case won(XOPlayer)
    case draw
}

struct XOView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isMenuShowing: Bool
    @StateObject private var game = XOGame()
    @State private var showConfetti = false
    @State private var showWinAlert = false

    var body: some View {
        ZStack {
            // Liquid background
            LiquidBackgroundView()
                .environmentObject(themeManager)

            VStack(spacing: 0) {
                // Header
                headerView

                Spacer()

                // Game Board
                gameBoard

                Spacer()

                // New Game Button
                newGameButton
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)

            // Confetti overlay
            if showConfetti {
                ConfettiView(isShowing: $showConfetti)
                    .allowsHitTesting(false)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .alert(winMessage, isPresented: $showWinAlert) {
            Button("New Game") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    game.resetGame()
                    showConfetti = false
                }
            }
        } message: {
            Text(winMessageDetail)
        }
        .onChange(of: game.gameState) { oldState, newState in
            switch newState {
            case .won(_), .draw:
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showWinAlert = true
                }
            case .playing:
                break
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                MenuButton(isMenuShowing: $isMenuShowing)

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: themeManager.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .shadow(color: themeManager.backgroundColors.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)

                        Image(systemName: "xmark.square")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("XO")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // Current player indicator
            if case .playing = game.gameState {
                HStack(spacing: 8) {
                    Text("Current Player:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    Text(game.currentPlayer.symbol)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(game.currentPlayer == .x ? .blue : .red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Game Board

    private var gameBoard: some View {
        GlassmorphicCard {
            VStack(spacing: 0) {
                ForEach(0..<3) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<3) { col in
                            cellView(row: row, col: col)

                            if col < 2 {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 2)
                            }
                        }
                    }

                    if row < 2 {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(20)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal, 20)
    }

    private func cellView(row: Int, col: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                game.makeMove(row: row, col: col)
            }

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }) {
            ZStack {
                // Tappable background
                Rectangle()
                    .fill(Color.white.opacity(0.001))

                if let player = game.board[row][col] {
                    Text(player.symbol)
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(player == .x ? .blue : .red)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - New Game Button

    private var newGameButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                game.resetGame()
                showConfetti = false
            }

            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 20))
                Text("New Game")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    LinearGradient(
                        colors: themeManager.backgroundColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )

                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(16)
            .shadow(color: themeManager.backgroundColors.first?.opacity(0.5) ?? .clear, radius: 15, x: 0, y: 8)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 20)
    }

    // MARK: - Win Messages

    private var winMessage: String {
        switch game.gameState {
        case .won(let player):
            return "\(player.symbol) Wins! 🎉"
        case .draw:
            return "It's a Draw! 🤝"
        case .playing:
            return ""
        }
    }

    private var winMessageDetail: String {
        switch game.gameState {
        case .won(let player):
            return "Congratulations! Player \(player.symbol) won the game!"
        case .draw:
            return "Good game! Nobody won this time."
        case .playing:
            return ""
        }
    }
}

// MARK: - Game Logic

class XOGame: ObservableObject {
    @Published var board: [[XOPlayer?]] = Array(repeating: Array(repeating: nil, count: 3), count: 3)
    @Published var currentPlayer: XOPlayer = .x
    @Published var gameState: GameState = .playing

    func makeMove(row: Int, col: Int) {
        // Only allow moves if game is still playing and cell is empty
        guard case .playing = gameState, board[row][col] == nil else { return }

        // Make the move
        board[row][col] = currentPlayer

        // Check for win or draw
        if checkWin(player: currentPlayer) {
            gameState = .won(currentPlayer)
        } else if checkDraw() {
            gameState = .draw
        } else {
            // Switch player
            currentPlayer = currentPlayer == .x ? .o : .x
        }
    }

    func resetGame() {
        board = Array(repeating: Array(repeating: nil, count: 3), count: 3)
        currentPlayer = .x
        gameState = .playing
    }

    private func checkWin(player: XOPlayer) -> Bool {
        // Check rows
        for row in 0..<3 {
            if board[row][0] == player && board[row][1] == player && board[row][2] == player {
                return true
            }
        }

        // Check columns
        for col in 0..<3 {
            if board[0][col] == player && board[1][col] == player && board[2][col] == player {
                return true
            }
        }

        // Check diagonals
        if board[0][0] == player && board[1][1] == player && board[2][2] == player {
            return true
        }
        if board[0][2] == player && board[1][1] == player && board[2][0] == player {
            return true
        }

        return false
    }

    private func checkDraw() -> Bool {
        for row in 0..<3 {
            for col in 0..<3 {
                if board[row][col] == nil {
                    return false
                }
            }
        }
        return true
    }
}


#Preview {
    XOView(isMenuShowing: .constant(false))
        .environmentObject(ThemeManager())
}
