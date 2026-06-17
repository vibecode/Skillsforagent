---
name: swift-games
display_name: SwiftUI Games
description: "Interactive stateful SwiftUI game patterns for iOS 26 single-file apps - use when generating memory-match, tic-tac-toe, reflex, puzzle, or arcade games that need a real @Observable game-state model, timer/game loop, gestures, score, win/lose detection, and restart instead of flat decorative UI."
metadata: {"openclaw": {"emoji": "🎮"}}
---

# SwiftUI Game Patterns

Generated games break when rules are scattered through `@State` in the view.
Use one `@Observable` model for phase, board/entities, score, timer state,
outcome, and restart. Views render state and call intent methods only.

Core rules:

- Outcomes are explicit: `.playing`, `.won`, `.lost`, `.draw`.
- Disable or ignore input after the outcome is final.
- Fixed boards may use `0..<9`; shuffled cards/entities need stable `Identifiable` ids.
- Restart resets transient state: selected card, turn, timer, target, matches, phase.
- Bound random positions and drag coordinates to the visible playfield.

## 1. Board game: model-owned win/draw/score

Use this for tic-tac-toe, connect-style grids, and turn-based puzzles. The view
does not compute winners.

```swift
@Observable
final class TicTacToeGame {
    enum Mark: String, Equatable {
        case x = "xmark", o = "circle"
        var next: Mark { self == .x ? .o : .x }
        var title: String { self == .x ? "X" : "O" }
    }
    enum Outcome: Equatable { case playing, won(Mark), draw }

    var cells: [Mark?] = Array(repeating: nil, count: 9)
    var turn: Mark = .x
    var outcome: Outcome = .playing
    var xScore = 0, oScore = 0, draws = 0
    private let wins = [[0,1,2], [3,4,5], [6,7,8], [0,3,6],
                        [1,4,7], [2,5,8], [0,4,8], [2,4,6]]

    func play(_ index: Int) {
        guard cells.indices.contains(index), cells[index] == nil, outcome == .playing else { return }
        cells[index] = turn
        if wins.contains(where: { $0.allSatisfy { cells[$0] == turn } }) {
            outcome = .won(turn)
            if turn == .x { xScore += 1 } else { oScore += 1 }
        } else if cells.allSatisfy({ $0 != nil }) {
            outcome = .draw
            draws += 1
        } else {
            turn = turn.next
        }
    }

    func restartRound() {
        cells = Array(repeating: nil, count: 9)
        turn = .x
        outcome = .playing
    }

    func resetScore() {
        xScore = 0; oScore = 0; draws = 0
        restartRound()
    }
}
```

Render fixed boards with `LazyVGrid`; each cell button calls `game.play(index)`
and disables when the cell is filled or `outcome != .playing`.

## 2. Timer loop: reflex game with lose/restart

A loop task should only call `tick()`. The model owns score, target movement,
and the lose condition.

```swift
@Observable
final class ReflexGame {
    enum Phase { case ready, playing, lost }
    var phase: Phase = .ready
    var timeRemaining = 10.0
    var score = 0
    var target = CGPoint(x: 160, y: 240)

    func start(in size: CGSize) {
        phase = .playing; timeRemaining = 10; score = 0
        moveTarget(in: size)
    }

    func tick() {
        guard phase == .playing else { return }
        timeRemaining = max(0, timeRemaining - 1.0 / 30.0)
        if timeRemaining == 0 { phase = .lost }
    }

    func hit(in size: CGSize) {
        guard phase == .playing else { return }
        score += 10
        timeRemaining = min(10, timeRemaining + 0.35)
        moveTarget(in: size)
    }

    private func moveTarget(in size: CGSize) {
        let maxX = max(56, size.width - 56), maxY = max(120, size.height - 100)
        target = CGPoint(x: CGFloat.random(in: 56...maxX), y: CGFloat.random(in: 120...maxY))
    }
}

struct ReflexGameView: View {
    @State private var game = ReflexGame()
    @State private var loop: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                Circle().fill(game.phase == .playing ? .pink : .secondary)
                    .frame(width: 68, height: 68).position(game.target)
                    .onTapGesture { game.hit(in: proxy.size) }
                VStack {
                    HStack {
                        Text("Score \(game.score)")
                        Spacer()
                        Text("Time \(Int(game.timeRemaining.rounded(.up)))")
                    }
                    .font(.headline.monospacedDigit()).padding()
                    Spacer()
                    Button(game.phase == .lost ? "Restart" : "Start") { game.start(in: proxy.size) }
                        .buttonStyle(.borderedProminent).padding(.bottom, 28)
                }
            }
        }
        .onAppear { startLoop() }
        .onDisappear { loop?.cancel(); loop = nil }
    }

    private func startLoop() {
        guard loop == nil else { return }
        loop = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 33_000_000)
                game.tick()
            }
        }
    }
}
```

## 3. Drag gesture: bounds and win detection

Gestures should forward coordinates to the model. Clamp inside the playfield and
check collision there.

```swift
@Observable
final class DragPuzzleGame {
    enum Phase { case playing, won }
    var phase: Phase = .playing
    var score = 0
    var player = CGPoint(x: 80, y: 120)
    var goal = CGPoint(x: 260, y: 420)

    func move(to point: CGPoint, in size: CGSize) {
        guard phase == .playing else { return }
        player = CGPoint(x: min(max(28, point.x), max(28, size.width - 28)),
                         y: min(max(28, point.y), max(28, size.height - 28)))
        if distance(player, goal) < 42 { phase = .won; score += 100 }
    }

    func restart(in size: CGSize) {
        phase = .playing
        player = CGPoint(x: 80, y: 120)
        goal = CGPoint(x: max(120, size.width - 80), y: max(180, size.height - 120))
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        let dx = Double(a.x - b.x), dy = Double(a.y - b.y)
        return (dx * dx + dy * dy).squareRoot()
    }
}

struct DragPuzzleView: View {
    @State private var game = DragPuzzleGame()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(.thinMaterial)
                Circle().stroke(.green, lineWidth: 5).frame(width: 84, height: 84).position(game.goal)
                Circle().fill(game.phase == .won ? .green : .blue).frame(width: 56, height: 56).position(game.player)
                VStack {
                    Text(game.phase == .won ? "You win" : "Drag to the goal").font(.headline)
                    Text("Score \(game.score)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                    Spacer()
                    Button("Restart") { game.restart(in: proxy.size) }.buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { game.move(to: $0.location, in: proxy.size) })
            .padding()
        }
    }
}
```

Before finishing: move changes state visibly, final outcomes block input, score
and outcome are model-owned, restart clears stale state, and positions stay on
screen.
