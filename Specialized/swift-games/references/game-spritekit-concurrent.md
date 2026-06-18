# Concurrency-Safe SpriteKit Games

Use this for single-file iOS 26 SwiftUI games with `SpriteView`, `SKScene`,
physics contacts, touch drag, score, game over, and restart.

Rules:

- SpriteKit nodes, scene state, labels, touches, and physics world are UI-owned;
  keep the scene `@MainActor`.
- Do not write `@MainActor final class Scene: SKScene, SKPhysicsContactDelegate`.
  That claims a nonisolated delegate conformance from main-actor code.
- Prefer isolated conformance: `extension Scene: @MainActor
  SKPhysicsContactDelegate { ... }`. Set `physicsWorld.contactDelegate = self`
  from scene lifecycle code.
- Do not make `didBegin(_:)` `nonisolated` and pass `SKPhysicsContact`,
  `SKPhysicsBody`, or `SKNode` into `Task { @MainActor in ... }`; they are not
  Sendable. For forced `nonisolated` callbacks, copy only Sendable value data.
- Queue contact effects in `didBegin(_:)`; remove nodes and mutate game state in
  `update(_:)`, after SpriteKit's physics callback.
- Keep the scene stable in SwiftUI with `@State`; never create it inside `body`.

## Complete Orb Dodge Example

Paste as one file. It uses a main-actor scene plus a main-actor isolated physics
delegate conformance, which avoids the Swift 6 diagnostic.

```swift
import SwiftUI
import SpriteKit
import UIKit

@main
struct OrbDodgeApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
    @State private var scene: OrbDodgeScene = {
        let scene = OrbDodgeScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes])
            .ignoresSafeArea()
    }
}

private enum Body { static let none: UInt32 = 0; static let player: UInt32 = 1 << 0; static let orb: UInt32 = 1 << 1 }

@MainActor
final class OrbDodgeScene: SKScene {
    private let player = SKSpriteNode(color: .systemCyan, size: CGSize(width: 88, height: 26))
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let messageLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var lastUpdate: TimeInterval = 0
    private var spawnClock: TimeInterval = 0
    private var score = 0
    private var gameOver = false
    private var pendingScore = 0
    private var pendingGameOver = false
    private var pendingRemoval: [SKNode] = []

    override func didMove(to view: SKView) {
        view.ignoresSiblingOrder = true
        backgroundColor = SKColor(red: 0.04, green: 0.05, blue: 0.10, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -5.7)
        physicsWorld.contactDelegate = self
        installPlayer()
        installHUD()
        restartRound()
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : min(currentTime - lastUpdate, 1.0 / 30.0)
        lastUpdate = currentTime
        applyPendingContacts()
        guard !gameOver else { return }

        spawnClock += dt
        if spawnClock >= max(0.28, 0.82 - Double(score) * 0.012) {
            spawnClock = 0
            spawnOrb()
        }
        enumerateChildNodes(withName: "orb") { [weak self] node, _ in
            guard let self, node.position.y < -40 else { return }
            self.queueRemoval(node)
            self.pendingScore += 1
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        gameOver ? restartRound() : movePlayer(with: touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameOver { movePlayer(with: touches) }
    }

    private func installPlayer() {
        player.name = "player"
        player.zPosition = 10
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = false
        player.physicsBody?.categoryBitMask = Body.player; player.physicsBody?.contactTestBitMask = Body.orb
        player.physicsBody?.collisionBitMask = Body.none
        if player.parent == nil { addChild(player) }
    }

    private func installHUD() {
        scoreLabel.fontSize = 28; scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left; scoreLabel.zPosition = 20
        messageLabel.fontSize = 28; messageLabel.fontColor = .white
        messageLabel.horizontalAlignmentMode = .center; messageLabel.zPosition = 20
        if scoreLabel.parent == nil { addChild(scoreLabel) }
        if messageLabel.parent == nil { addChild(messageLabel) }
        layoutHUD()
    }

    private func layoutHUD() {
        scoreLabel.position = CGPoint(x: 24, y: max(size.height - 72, 24))
        messageLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private func spawnOrb() {
        let radius = CGFloat.random(in: 14...24)
        let orb = SKShapeNode(circleOfRadius: radius)
        orb.name = "orb"
        orb.fillColor = .systemPink
        orb.strokeColor = SKColor.white.withAlphaComponent(0.35)
        orb.lineWidth = 2
        orb.zPosition = 5
        orb.position = CGPoint(x: CGFloat.random(in: radius...max(radius, size.width - radius)),
                               y: size.height + radius)
        orb.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        orb.physicsBody?.isDynamic = true
        orb.physicsBody?.allowsRotation = true
        orb.physicsBody?.usesPreciseCollisionDetection = true
        orb.physicsBody?.categoryBitMask = Body.orb; orb.physicsBody?.contactTestBitMask = Body.player
        orb.physicsBody?.collisionBitMask = Body.none
        addChild(orb)
    }

    private func movePlayer(with touches: Set<UITouch>) {
        guard let x = touches.first?.location(in: self).x else { return }
        player.position.x = x
        clampPlayer()
    }

    private func clampPlayer() {
        let half = player.size.width / 2
        player.position.y = 96
        player.position.x = min(max(player.position.x, half), max(half, size.width - half))
    }

    private func applyPendingContacts() {
        if pendingScore > 0 {
            score += pendingScore
            pendingScore = 0
            scoreLabel.text = "Score \(score)"
        }
        pendingRemoval.forEach { $0.removeFromParent() }
        pendingRemoval.removeAll()
        if pendingGameOver {
            pendingGameOver = false
            endGame()
        }
    }

    private func endGame() {
        guard !gameOver else { return }
        gameOver = true
        messageLabel.text = "Hit! Tap to Restart"
    }

    private func restartRound() {
        removeChildren(in: children.filter { $0.name == "orb" })
        pendingRemoval.removeAll()
        pendingScore = 0; pendingGameOver = false; score = 0; gameOver = false
        lastUpdate = 0; spawnClock = 0
        player.position = CGPoint(x: size.width / 2, y: 96)
        clampPlayer()
        scoreLabel.text = "Score 0"
        messageLabel.text = ""
    }

    private func queueRemoval(_ node: SKNode?) {
        guard let node, !pendingRemoval.contains(where: { $0 === node }) else { return }
        pendingRemoval.append(node)
    }
}

extension OrbDodgeScene: @MainActor SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        guard !gameOver else { return }
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        guard mask == (Body.player | Body.orb) else { return }
        let orb = contact.bodyA.categoryBitMask == Body.orb ? contact.bodyA.node : contact.bodyB.node
        queueRemoval(orb)
        pendingGameOver = true
    }
}
```
