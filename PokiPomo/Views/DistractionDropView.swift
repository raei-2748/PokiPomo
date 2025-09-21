import SwiftUI

struct DistractionDropView: View {
    var onContinue: () -> Void

    @StateObject private var motionManager = MotionManager()
    @State private var tiles: [FallingTile] = []
    @State private var lastUpdate: Date?
    @State private var spawnTimer: TimeInterval = 0
    @State private var nextSpawnInterval: TimeInterval = .random(in: 0.35...0.85)
    @State private var continueEnabled = false
    @State private var restAccumulation: TimeInterval = 0
    @State private var elapsed: TimeInterval = 0
    @State private var hasUnlockedContinue = false

    private let floorInset: CGFloat = 170
    private let sideInset: CGFloat = 28
    private let maxTiles = 16
    private let gravity: CGFloat = 900
    private let horizontalDrag: CGFloat = 0.985
    private let bounceDamping: CGFloat = 0.58

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack(alignment: .bottom) {
                background
                    .ignoresSafeArea()

                TimelineView(.animation) { timeline in
                    ZStack {
                        ForEach(tiles) { tile in
                            SocialTileView(tile: tile)
                                .frame(width: tile.size.width, height: tile.size.height)
                                .scaleEffect(x: 1 + tile.squash, y: 1 - tile.squash, anchor: .bottom)
                                .rotationEffect(tile.rotation)
                                .position(
                                    x: tile.position.x + tile.microOffset.x,
                                    y: tile.position.y + tile.microOffset.y
                                )
                                .shadow(color: tile.style.shadow.opacity(0.32), radius: 14, x: 0, y: 18)
                                .opacity(tile.opacity)
                                .zIndex(tile.zIndex)
                                .animation(.easeOut(duration: 0.45), value: tile.squash)
                        }
                    }
                    .frame(width: size.width, height: size.height)
                    .onChange(of: timeline.date) { date in
                        stepSimulation(to: date, container: size)
                    }
                }
                .ignoresSafeArea()

                copyBlock
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 64)
                    .padding(.horizontal, 32)

                continueButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 44)
            }
            .onAppear {
                if size.width > 0, size.height > 0 {
                    resetSimulation(for: size)
                }
                motionManager.start()
            }
            .onDisappear {
                motionManager.stop()
            }
            .onChange(of: size) { newSize in
                guard newSize.width > 0, newSize.height > 0 else { return }
                resetSimulation(for: newSize)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 32/255, green: 34/255, blue: 49/255),
                Color(red: 18/255, green: 19/255, blue: 31/255)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var copyBlock: some View {
        VStack(spacing: 12) {
            Text("The Distraction Loop")
                .font(.title2.bold())
                .foregroundStyle(.white.opacity(0.94))

            Text("Notice how the icons keep pulling you back. Tilt to feel the tug, then continue when you’re ready to focus.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var continueButton: some View {
        Button {
            guard continueEnabled else { return }
            withAnimation(.easeInOut) {
                onContinue()
            }
        } label: {
            Text("Continue")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 10)
                )
        }
        .disabled(!continueEnabled)
        .opacity(continueEnabled ? 1 : 0.4)
        .animation(.easeOut(duration: 0.4), value: continueEnabled)
        .overlay(alignment: .top, content: {
            Rectangle()
                .fill(.clear)
                .frame(height: 1)
        })
    }

    private func stepSimulation(to now: Date, container size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        let dt: TimeInterval
        if let lastUpdate {
            dt = min(max(now.timeIntervalSince(lastUpdate), 1.0 / 240.0), 1.0 / 24.0)
        } else {
            lastUpdate = now
            return
        }

        lastUpdate = now
        spawnTimer += dt
        elapsed += dt

        if !hasUnlockedContinue, tiles.count < maxTiles, spawnTimer >= nextSpawnInterval {
            spawnTimer = 0
            nextSpawnInterval = .random(in: 0.45...0.9)
            spawnTile(in: size)
        }

        let floorY = size.height - floorInset
        let tilt = motionManager.horizontalTilt

        var restingTiles = 0

        for index in tiles.indices {
            tiles[index].age += dt
            tiles[index].velocity.dy += gravity * CGFloat(dt)
            tiles[index].velocity.dx += CGFloat(tilt) * 820 * CGFloat(dt)
            tiles[index].velocity.dx *= horizontalDrag

            tiles[index].position.x += tiles[index].velocity.dx * CGFloat(dt)
            tiles[index].position.y += tiles[index].velocity.dy * CGFloat(dt)

            let minX = sideInset + tiles[index].size.width / 2
            let maxX = size.width - sideInset - tiles[index].size.width / 2

            if tiles[index].position.x < minX {
                tiles[index].position.x = minX
                tiles[index].velocity.dx *= -0.4
            } else if tiles[index].position.x > maxX {
                tiles[index].position.x = maxX
                tiles[index].velocity.dx *= -0.4
            }

            let restingY = floorY - tiles[index].size.height / 2
            if tiles[index].position.y >= restingY {
                tiles[index].position.y = restingY

                if tiles[index].velocity.dy > 0 {
                    let impactVelocity = tiles[index].velocity.dy
                    let bounceVelocity = -impactVelocity * bounceDamping
                    tiles[index].velocity.dy = abs(bounceVelocity) < 35 ? 0 : bounceVelocity
                    tiles[index].squash = min(0.45, (abs(impactVelocity) / 1400).clamped(to: 0...0.45))

                    if tiles[index].velocity.dy == 0 {
                        tiles[index].velocity.dx *= 0.82
                    }
                }
            } else {
                tiles[index].squash *= 0.88
            }

            if tiles[index].velocity.dy == 0 {
                restingTiles += 1
                let ambientAmplitude: CGFloat = continueEnabled ? 0.6 : 2
                tiles[index].microOffset = tiles[index].microOffset.blendedToward(
                    CGPoint(
                        x: sin(CGFloat(tiles[index].age) * 1.6 + tiles[index].wobblePhase) * ambientAmplitude,
                        y: sin(CGFloat(tiles[index].age) * 1.05 + tiles[index].wobblePhase + .pi/3) * (ambientAmplitude * 0.75)
                    ),
                    amount: 0.12
                )
            } else {
                tiles[index].microOffset = tiles[index].microOffset.blendedToward(.zero, amount: 0.2)
            }

            tiles[index].rotation = tiles[index].rotation.blended(
                towards: Angle(degrees: Double(tiles[index].velocity.dx / 12)),
                amount: 0.12
            )

            tiles[index].opacity = min(1, tiles[index].opacity + CGFloat(dt) * 2.4)
            tiles[index].zIndex = Double(tiles[index].position.y / size.height)
        }

        resolveCollisions(in: size, floorY: floorY)

        for index in tiles.indices where tiles[index].velocity.dy == 0 {
            tiles[index].velocity.dx *= 0.97
        }

        if restingTiles == tiles.count && !tiles.isEmpty {
            restAccumulation += dt
        } else {
            restAccumulation = 0
        }

        let isRestedLongEnough = restAccumulation >= 0.8
        let hasRunLongEnough = elapsed >= 5.0
        let shouldEnable = isRestedLongEnough || hasRunLongEnough

        if shouldEnable {
            hasUnlockedContinue = true
        }

        if continueEnabled != shouldEnable {
            continueEnabled = shouldEnable
        }
    }

    private func spawnTile(in size: CGSize) {
        let style = SocialTileStyle.random()
        let dimension = CGFloat.random(in: 68...108)
        let position = CGPoint(
            x: .random(in: (sideInset + dimension/2)...(size.width - sideInset - dimension/2)),
            y: -dimension - .random(in: 20...120)
        )
        let velocity = CGVector(dx: .random(in: -40...40), dy: .random(in: -30...0))
        let wobblePhase = CGFloat.random(in: 0...(2 * .pi))

        let tile = FallingTile(
            style: style,
            size: CGSize(width: dimension, height: dimension),
            position: position,
            velocity: velocity,
            rotation: .degrees(.random(in: -5...5)),
            wobblePhase: wobblePhase
        )

        tiles.append(tile)
    }

    private func resolveCollisions(in size: CGSize, floorY: CGFloat) {
        guard tiles.count > 1 else { return }

        for i in 0..<tiles.count {
            for j in (i + 1)..<tiles.count {
                let delta = CGVector(
                    dx: tiles[j].position.x - tiles[i].position.x,
                    dy: tiles[j].position.y - tiles[i].position.y
                )
                let distance = max(0.001, sqrt(delta.dx * delta.dx + delta.dy * delta.dy))
                let minDistance = (tiles[i].size.width + tiles[j].size.width) * 0.45

                guard distance < minDistance else { continue }

                var normal = CGVector(dx: delta.dx / distance, dy: delta.dy / distance)
                if !normal.dx.isFinite || !normal.dy.isFinite {
                    normal = CGVector(dx: 0, dy: -1)
                }

                let overlap = minDistance - distance
                let correction = CGVector(dx: normal.dx * overlap / 2, dy: normal.dy * overlap / 2)

                tiles[i].position.x -= correction.dx
                tiles[i].position.y -= correction.dy
                tiles[j].position.x += correction.dx
                tiles[j].position.y += correction.dy

                let relativeVelocity = CGVector(
                    dx: tiles[j].velocity.dx - tiles[i].velocity.dx,
                    dy: tiles[j].velocity.dy - tiles[i].velocity.dy
                )
                let separatingSpeed = relativeVelocity.dx * normal.dx + relativeVelocity.dy * normal.dy
                let impulse = separatingSpeed * 0.35

                tiles[i].velocity.dx += impulse * normal.dx
                tiles[i].velocity.dy += impulse * normal.dy
                tiles[j].velocity.dx -= impulse * normal.dx
                tiles[j].velocity.dy -= impulse * normal.dy

                tiles[i].position.y = min(tiles[i].position.y, floorY)
                tiles[j].position.y = min(tiles[j].position.y, floorY)
            }
        }

        for index in tiles.indices {
            let minX = sideInset + tiles[index].size.width / 2
            let maxX = size.width - sideInset - tiles[index].size.width / 2
            tiles[index].position.x = tiles[index].position.x.clamped(to: minX...maxX)
            tiles[index].position.y = min(tiles[index].position.y, floorY)
        }
    }
}

extension DistractionDropView {
    private func resetSimulation(for size: CGSize) {
        tiles.removeAll()
        spawnTimer = 0
        nextSpawnInterval = .random(in: 0.45...0.9)
        continueEnabled = false
        restAccumulation = 0
        elapsed = 0
        hasUnlockedContinue = false
        lastUpdate = nil

        for _ in 0..<4 {
            spawnTile(in: size)
        }
    }
}

private struct FallingTile: Identifiable {
    let id = UUID()
    let style: SocialTileStyle
    var size: CGSize
    var position: CGPoint
    var velocity: CGVector
    var rotation: Angle
    var squash: CGFloat = 0
    var wobblePhase: CGFloat
    var age: TimeInterval = 0
    var microOffset: CGPoint = .zero
    var opacity: CGFloat = 0
    var zIndex: Double = 0
}

private struct SocialTileStyle {
    let name: String
    let background: AnyShapeStyle
    let glyph: String?
    let symbol: String?
    let glyphColor: Color
    let accent: Color
    let shadow: Color

    static func random() -> SocialTileStyle {
        styles.randomElement() ?? styles[0]
    }

    static let styles: [SocialTileStyle] = [
        SocialTileStyle(
            name: "Instagram",
            background: AnyShapeStyle(
                AngularGradient(
                    colors: [
                        Color(red: 241/255, green: 90/255, blue: 36/255),
                        Color(red: 240/255, green: 49/255, blue: 118/255),
                        Color(red: 196/255, green: 58/255, blue: 255/255),
                        Color(red: 241/255, green: 90/255, blue: 36/255)
                    ],
                    center: .center
                )
            ),
            glyph: nil,
            symbol: "camera.fill",
            glyphColor: .white,
            accent: Color.white.opacity(0.6),
            shadow: Color(red: 241/255, green: 49/255, blue: 118/255)
        ),
        SocialTileStyle(
            name: "TikTok",
            background: AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 18/255, green: 19/255, blue: 25/255),
                        Color(red: 35/255, green: 37/255, blue: 47/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            glyph: nil,
            symbol: "music.note",
            glyphColor: .white,
            accent: Color(red: 67/255, green: 235/255, blue: 203/255),
            shadow: Color.black.opacity(0.85)
        ),
        SocialTileStyle(
            name: "YouTube",
            background: AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 248/255, green: 47/255, blue: 54/255),
                        Color(red: 196/255, green: 13/255, blue: 25/255)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            ),
            glyph: nil,
            symbol: "play.fill",
            glyphColor: .white,
            accent: Color.white.opacity(0.75),
            shadow: Color(red: 156/255, green: 0, blue: 14/255)
        ),
        SocialTileStyle(
            name: "Snapchat",
            background: AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 246/255, blue: 103/255),
                        Color(red: 1.0, green: 226/255, blue: 58/255)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            ),
            glyph: nil,
            symbol: "ghost.fill",
            glyphColor: .black,
            accent: Color.black.opacity(0.25),
            shadow: Color(red: 240/255, green: 205/255, blue: 0)
        ),
        SocialTileStyle(
            name: "X",
            background: AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 36/255, green: 37/255, blue: 44/255),
                        Color(red: 10/255, green: 10/255, blue: 12/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            glyph: "X",
            symbol: nil,
            glyphColor: .white,
            accent: Color.white.opacity(0.45),
            shadow: Color.black.opacity(0.92)
        )
    ]
}

private struct SocialTileView: View {
    let tile: FallingTile

    var body: some View {
        let radius = tile.size.width * 0.26

        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(tile.style.background)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(tile.style.accent.opacity(0.35), lineWidth: 1.2)
                    .blendMode(.overlay)
            )
            .overlay(contentOverlay(radius: radius))
    }

    @ViewBuilder
    private func contentOverlay(radius: CGFloat) -> some View {
        ZStack {
            if let symbol = tile.style.symbol {
                Image(systemName: symbol)
                    .font(.system(size: tile.size.width * 0.38, weight: .bold))
                    .foregroundStyle(tile.style.glyphColor)
            } else if let glyph = tile.style.glyph {
                Text(glyph)
                    .font(.system(size: tile.size.width * 0.42, weight: .heavy, design: .rounded))
                    .foregroundStyle(tile.style.glyphColor)
            }
        }
    }
}

private extension CGFloat {
    func clamped(to limits: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, limits.lowerBound), limits.upperBound)
    }
}

private extension CGPoint {
    func blendedToward(_ target: CGPoint, amount: CGFloat) -> CGPoint {
        CGPoint(
            x: x + (target.x - x) * amount,
            y: y + (target.y - y) * amount
        )
    }
}

private extension Angle {
    func blended(towards target: Angle, amount: Double) -> Angle {
        Angle(degrees: degrees + (target.degrees - degrees) * amount)
    }
}

struct DistractionDropView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DistractionDropView(onContinue: {})
        }
    }
}
