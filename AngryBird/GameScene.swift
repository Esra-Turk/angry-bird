//
//  GameScene.swift
//  AngryBird
//
//  Created by Esra Türk on 22.11.2024.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    private var bird = SKSpriteNode()
    private var rocks = [SKSpriteNode]()
    private var isGameStart = false
    private var originalPosition: CGPoint?
    private var score = 0
    private let scoreLabel = SKLabelNode()
    private let gameOverLabel = SKLabelNode()
    private let timerLabel = SKLabelNode()
    private var remainingTime = 20
    private var lastUpdateTime: TimeInterval = 0

    enum ColliderType: UInt32 {
        case bird = 1
        case rock = 2
    }

    override func didMove(to view: SKView) {
        setupPhysicsBody()
        setupBird()
        setupRocks()
        setupScoreLabel()
        setupTimerLabel()
        setupGameOverLabel()
    }

    private func setupPhysicsBody() {
        physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        scene?.scaleMode = .aspectFit
        physicsWorld.contactDelegate = self
    }

    private func setupBird() {
        guard let birdNode = childNode(withName: "bird") as? SKSpriteNode else { return }
        bird = birdNode
        let birdTexture = SKTexture(imageNamed: "bird")
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: birdTexture.size().height / 13)
        bird.physicsBody?.affectedByGravity = false
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.mass = 0.15
        bird.physicsBody?.contactTestBitMask = ColliderType.bird.rawValue
        bird.physicsBody?.categoryBitMask = ColliderType.bird.rawValue
        bird.physicsBody?.collisionBitMask = ColliderType.rock.rawValue
        
        originalPosition = bird.position
    }

    private func setupRocks() {
        let rockNames = ["rock1", "rock2", "rock3", "rock4", "rock5"]
        let rockTexture = SKTexture(imageNamed: "rock")
        let rockSize = CGSize(width: rockTexture.size().width / 5, height: rockTexture.size().height / 5)

        for rockName in rockNames {
            if let rockNode = childNode(withName: rockName) as? SKSpriteNode {
                rockNode.physicsBody = createRockPhysicsBody(size: rockSize)
                rocks.append(rockNode)
            }
        }
    }

    private func createRockPhysicsBody(size: CGSize) -> SKPhysicsBody {
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = true
        body.affectedByGravity = true
        body.allowsRotation = true
        body.mass = 0.2
        body.collisionBitMask = ColliderType.bird.rawValue
        
        return body
    }

    private func setupScoreLabel() {
        scoreLabel.fontName = "Helvetica-Heavy"
        scoreLabel.fontSize = 100
        scoreLabel.fontColor = .black
        scoreLabel.text = "0"
        scoreLabel.position = CGPoint(x: 0, y: self.frame.height / 4)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
    }

    private func setupTimerLabel() {
        timerLabel.fontName = "Helvetica-Heavy"
        timerLabel.fontSize = 50
        timerLabel.fontColor = .black
        timerLabel.text = "Time: \(remainingTime)"
        timerLabel.position = CGPoint(x: self.frame.width / 2 - 100, y: self.frame.height / 2 - 100)
        timerLabel.horizontalAlignmentMode = .right
        timerLabel.zPosition = 3
        addChild(timerLabel)
    }
    
    private func setupGameOverLabel() {
        gameOverLabel.fontName = "Helvetica-Heavy"
        gameOverLabel.fontSize = 80
        gameOverLabel.fontColor = .darkGray
        gameOverLabel.text = ""
        gameOverLabel.position = CGPoint(x: self.frame.width / 2 - 450, y: self.frame.height / 4 - 200)
        gameOverLabel.horizontalAlignmentMode = .right
        gameOverLabel.zPosition = 4
        addChild(gameOverLabel)
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        if currentTime - lastUpdateTime >= 1.0 && isGameStart {
            if remainingTime > 0 {
                remainingTime -= 1
                timerLabel.text = "Time: \(remainingTime)"
            }

            lastUpdateTime = currentTime

            if remainingTime <= 0 {
                resetBird()
                gameOverLabel.text = "Game Over!"
                isGameStart = false
            }
        }

        guard let physicsBody = bird.physicsBody else { return }
        if physicsBody.velocity.isEffectivelyZero && isGameStart {
            resetBird()
            isGameStart = false
        }
    }


    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameStart == false {
            handleTouch(touches, for: .began)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameStart == false {
            handleTouch(touches, for: .moved)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameStart == false {
            handleTouch(touches, for: .ended)
        }
    }

    private func handleTouch(_ touches: Set<UITouch>, for state: TouchState) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)

        for node in nodes {
            if let sprite = node as? SKSpriteNode, sprite == bird {
                switch state {
                case .began, .moved:
                    bird.position = location
                case .ended:
                    let dx = -(location.x - originalPosition!.x)
                    let dy = -(location.y - originalPosition!.y)
                    let impulse = CGVector(dx: dx, dy: dy)
                    bird.physicsBody?.applyImpulse(impulse)
                    bird.physicsBody?.affectedByGravity = true
                    isGameStart = true
                }
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.collisionBitMask == ColliderType.bird.rawValue || contact.bodyB.collisionBitMask == ColliderType.bird.rawValue {
            incrementScore()
        }
    }
    
    private func incrementScore() {
        score += 1
        scoreLabel.text = String(score)
    }

    private func resetBird() {
        bird.physicsBody?.affectedByGravity = false
        bird.physicsBody?.velocity = .zero
        bird.physicsBody?.angularVelocity = 0
        bird.position = originalPosition!
    }

}

private extension CGVector {
    var isEffectivelyZero: Bool {
        return dx.magnitude <= 0.1 && dy.magnitude <= 0.1
    }
}

private enum TouchState {
    case began, moved, ended
}
