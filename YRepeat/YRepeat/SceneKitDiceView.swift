//
//  SceneKitDiceView.swift
//  YRepeat
//
//  3D Realistic Dice with Physics
//

import SwiftUI
import SceneKit

struct SceneKitDiceView: UIViewRepresentable {
    @Binding var isRolling: Bool
    @Binding var numberOfDice: Int
    let onRollComplete: ([Int]) -> Void

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = context.coordinator.scene
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = .clear
        sceneView.antialiasingMode = .multisampling4X

        // Enable shadows
        sceneView.scene?.rootNode.light?.castsShadow = true

        return sceneView
    }

    func updateUIView(_ sceneView: SCNView, context: Context) {
        // Only initiate throw once per roll
        if isRolling && !context.coordinator.isCurrentlyThrowing {
            context.coordinator.isCurrentlyThrowing = true

            // Immediately reset isRolling to prevent re-triggering
            DispatchQueue.main.async {
                self.isRolling = false
            }

            context.coordinator.throwDice(numberOfDice: numberOfDice) { results in
                DispatchQueue.main.async {
                    context.coordinator.isCurrentlyThrowing = false
                    self.onRollComplete(results)
                }
            }
        } else if !isRolling {
            // Reset the throwing flag when user is ready for next roll
            context.coordinator.isCurrentlyThrowing = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: SceneKitDiceView
        let scene = SCNScene()
        var diceNodes: [SCNNode] = []
        var isCurrentlyThrowing = false

        init(_ parent: SceneKitDiceView) {
            self.parent = parent
            super.init()
            setupScene()
        }

        func setupScene() {
            // Set transparent background
            scene.background.contents = UIColor.clear

            // Camera - positioned at 45-degree angle for better viewing
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.camera?.fieldOfView = 45
            cameraNode.position = SCNVector3(0, 12, 12)
            cameraNode.eulerAngles = SCNVector3(-45 * Float.pi / 180, 0, 0)
            scene.rootNode.addChildNode(cameraNode)

            // Ambient Light - softer for better depth
            let ambientLight = SCNNode()
            ambientLight.light = SCNLight()
            ambientLight.light?.type = .ambient
            ambientLight.light?.color = UIColor(white: 0.5, alpha: 1.0)
            scene.rootNode.addChildNode(ambientLight)

            // Directional Light (for shadows) - properly configured
            let directionalLight = SCNNode()
            directionalLight.light = SCNLight()
            directionalLight.light?.type = .directional
            directionalLight.light?.color = UIColor.white
            directionalLight.light?.intensity = 1000
            directionalLight.light?.castsShadow = true
            directionalLight.light?.shadowMode = .deferred
            directionalLight.light?.shadowRadius = 4
            directionalLight.light?.shadowColor = UIColor(white: 0, alpha: 0.5)
            directionalLight.light?.orthographicScale = 10
            directionalLight.light?.zNear = 1
            directionalLight.light?.zFar = 100
            directionalLight.position = SCNVector3(10, 20, 10)
            directionalLight.eulerAngles = SCNVector3(-45 * Float.pi / 180, 30 * Float.pi / 180, 0)
            scene.rootNode.addChildNode(directionalLight)

            // Floor (table surface) - neutral gray/brown
            let floor = SCNFloor()
            floor.reflectivity = 0.05
            let floorMaterial = SCNMaterial()
            floorMaterial.diffuse.contents = UIColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 1.0)
            floorMaterial.lightingModel = .physicallyBased
            floor.materials = [floorMaterial]

            let floorNode = SCNNode(geometry: floor)
            floorNode.position = SCNVector3(0, 0, 0)
            floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            floorNode.physicsBody?.restitution = 0.3
            floorNode.physicsBody?.friction = 0.6
            scene.rootNode.addChildNode(floorNode)
        }

        func createDice(at position: SCNVector3) -> SCNNode {
            // Dice geometry with rounded edges
            let diceGeometry = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0.2)

            // Create dice face textures with dots
            let materials = (1...6).map { number -> SCNMaterial in
                let material = SCNMaterial()
                material.diffuse.contents = createDiceFaceImage(number: number)
                material.lightingModel = .physicallyBased
                material.roughness.contents = 0.3
                material.metalness.contents = 0.0
                return material
            }

            // Assign materials to faces
            // Order: right, left, top, bottom, front, back
            diceGeometry.materials = [
                materials[5], // right (6)
                materials[0], // left (1)
                materials[1], // top (2)
                materials[4], // bottom (5)
                materials[2], // front (3)
                materials[3]  // back (4)
            ]

            let diceNode = SCNNode(geometry: diceGeometry)
            diceNode.position = position

            // Add physics
            let physicsShape = SCNPhysicsShape(geometry: diceGeometry, options: [.collisionMargin: 0.01])
            diceNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
            diceNode.physicsBody?.mass = 1.0
            diceNode.physicsBody?.restitution = 0.4 // Bounciness
            diceNode.physicsBody?.friction = 0.5
            diceNode.physicsBody?.damping = 0.3
            diceNode.physicsBody?.angularDamping = 0.5

            return diceNode
        }

        func createDiceFaceImage(number: Int) -> UIImage {
            let size = CGSize(width: 200, height: 200)
            let renderer = UIGraphicsImageRenderer(size: size)

            return renderer.image { context in
                // Background (white)
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))

                // Dots (black)
                UIColor.black.setFill()
                let dotRadius: CGFloat = 18
                let margin: CGFloat = 40
                let center = size.width / 2

                let positions: [[CGPoint]] = [
                    // 1
                    [CGPoint(x: center, y: center)],
                    // 2
                    [CGPoint(x: margin, y: margin), CGPoint(x: size.width - margin, y: size.height - margin)],
                    // 3
                    [CGPoint(x: margin, y: margin), CGPoint(x: center, y: center), CGPoint(x: size.width - margin, y: size.height - margin)],
                    // 4
                    [CGPoint(x: margin, y: margin), CGPoint(x: size.width - margin, y: margin),
                     CGPoint(x: margin, y: size.height - margin), CGPoint(x: size.width - margin, y: size.height - margin)],
                    // 5
                    [CGPoint(x: margin, y: margin), CGPoint(x: size.width - margin, y: margin),
                     CGPoint(x: center, y: center),
                     CGPoint(x: margin, y: size.height - margin), CGPoint(x: size.width - margin, y: size.height - margin)],
                    // 6
                    [CGPoint(x: margin, y: margin), CGPoint(x: size.width - margin, y: margin),
                     CGPoint(x: margin, y: center), CGPoint(x: size.width - margin, y: center),
                     CGPoint(x: margin, y: size.height - margin), CGPoint(x: size.width - margin, y: size.height - margin)]
                ]

                for position in positions[number - 1] {
                    let dotRect = CGRect(x: position.x - dotRadius, y: position.y - dotRadius,
                                       width: dotRadius * 2, height: dotRadius * 2)
                    context.cgContext.fillEllipse(in: dotRect)
                }
            }
        }

        func throwDice(numberOfDice: Int, completion: @escaping ([Int]) -> Void) {
            // Remove old dice
            diceNodes.forEach { $0.removeFromParentNode() }
            diceNodes.removeAll()

            // Create new dice
            let spacing: Float = 3.5
            let startX = -Float(numberOfDice - 1) * spacing / 2

            for i in 0..<numberOfDice {
                let x = startX + Float(i) * spacing
                let position = SCNVector3(x, 10, 0) // Start high above table
                let dice = createDice(at: position)
                scene.rootNode.addChildNode(dice)
                diceNodes.append(dice)

                // Add random initial rotation
                dice.eulerAngles = SCNVector3(
                    Float.random(in: 0...(Float.pi * 2)),
                    Float.random(in: 0...(Float.pi * 2)),
                    Float.random(in: 0...(Float.pi * 2))
                )

                // Apply random impulse for realistic throw
                let impulse = SCNVector3(
                    Float.random(in: -4...4),
                    Float.random(in: -3...(-1)),
                    Float.random(in: -4...4)
                )
                dice.physicsBody?.applyForce(impulse, asImpulse: true)

                // Random spin with more variation
                let torque = SCNVector4(
                    Float.random(in: -1...1),
                    Float.random(in: -1...1),
                    Float.random(in: -1...1),
                    Float.random(in: 8...20)
                )
                dice.physicsBody?.applyTorque(torque, asImpulse: true)
            }

            // Wait for dice to settle and read results
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                let results = self.diceNodes.map { self.readDiceValue($0) }
                completion(results)
            }
        }

        func readDiceValue(_ diceNode: SCNNode) -> Int {
            // Get the world transform matrix
            let transform = diceNode.presentation.worldTransform

            // World up vector
            let worldUp = SCNVector3(0, 1, 0)

            // Define face normals in local space and their corresponding values
            // SCNBox faces: Front(-Z), Right(+X), Back(+Z), Left(-X), Top(+Y), Bottom(-Y)
            let faceNormals: [(normal: SCNVector3, value: Int)] = [
                (SCNVector3(1, 0, 0), 1),   // +X Right
                (SCNVector3(-1, 0, 0), 5),  // -X Left
                (SCNVector3(0, 1, 0), 3),   // +Y Top
                (SCNVector3(0, -1, 0), 4),  // -Y Bottom
                (SCNVector3(0, 0, 1), 2),   // +Z Back
                (SCNVector3(0, 0, -1), 6)   // -Z Front
            ]

            var maxDot: Float = -1
            var result = 1

            // Transform each local face normal to world space and check alignment with up
            for (localNormal, value) in faceNormals {
                // Transform normal to world space
                let worldNormal = SCNVector3(
                    transform.m11 * localNormal.x + transform.m12 * localNormal.y + transform.m13 * localNormal.z,
                    transform.m21 * localNormal.x + transform.m22 * localNormal.y + transform.m23 * localNormal.z,
                    transform.m31 * localNormal.x + transform.m32 * localNormal.y + transform.m33 * localNormal.z
                )

                // Calculate dot product with world up
                let dot = worldNormal.x * worldUp.x + worldNormal.y * worldUp.y + worldNormal.z * worldUp.z

                if dot > maxDot {
                    maxDot = dot
                    result = value
                }
            }

            return result
        }
    }
}

// MARK: - Enhanced Dice View with 3D

struct Enhanced3DDiceView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var numberOfDice = 1
    @State private var isRolling = false
    @State private var diceResults: [Int] = [1]
    @State private var rollHistory: [RollResult] = []
    @State private var showHistory = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: themeManager.backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            diceCountSelector

                            // 3D Dice Scene
                            GlassmorphicCard {
                                VStack(spacing: 0) {
                                    SceneKitDiceView(
                                        isRolling: $isRolling,
                                        numberOfDice: $numberOfDice,
                                        onRollComplete: { results in
                                            handleRollComplete(results)
                                        }
                                    )
                                    .frame(height: 350)
                                    .cornerRadius(16)
                                }
                                .padding(16)
                            }

                            if !rollHistory.isEmpty && showHistory {
                                historySection
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                    }

                    // Fixed button at bottom
                    rollButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    // Same header, selector, and history as before...
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)

                        Image(systemName: "cube.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("3D Dice")
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

                if !rollHistory.isEmpty {
                    Button(action: {
                        withAnimation { showHistory.toggle() }
                    }) {
                        Image(systemName: showHistory ? "clock.fill" : "clock")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
        }
    }

    private var diceCountSelector: some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Number of Dice")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    ForEach(1...3, id: \.self) { count in
                        Button(action: {
                            guard !isRolling else { return }
                            withAnimation {
                                numberOfDice = count
                                diceResults = Array(repeating: 1, count: count)
                            }
                        }) {
                            Text("\(count)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(numberOfDice == count ? .white : .white.opacity(0.4))
                                .frame(maxWidth: .infinity, minHeight: 70)
                                .background(
                                    numberOfDice == count
                                        ? LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .cornerRadius(16)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private var rollButton: some View {
        Button(action: {
            guard !isRolling else { return }
            rollDice()
        }) {
            HStack(spacing: 12) {
                Image(systemName: isRolling ? "arrow.triangle.2.circlepath" : "cube")
                Text(isRolling ? "Rolling..." : "THROW DICE!")
                    .font(.system(size: 22, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(
                LinearGradient(
                    colors: isRolling ? [.gray] : [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: isRolling ? .clear : .orange.opacity(0.5), radius: 20, y: 10)
        }
        .disabled(isRolling)
    }

    private var historySection: some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Rolls")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Clear") {
                        withAnimation { rollHistory.removeAll() }
                    }
                    .foregroundColor(.red)
                }

                ForEach(rollHistory.reversed()) { result in
                    HStack {
                        Text(result.values.map { String($0) }.joined(separator: " + "))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("\(result.total)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(20)
        }
    }

    private func rollDice() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        isRolling = true
    }

    private func handleRollComplete(_ results: [Int]) {
        withAnimation {
            diceResults = results
        }

        let result = RollResult(
            values: results,
            total: results.reduce(0, +),
            timestamp: Date()
        )
        rollHistory.append(result)
        if rollHistory.count > 20 {
            rollHistory.removeFirst()
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
