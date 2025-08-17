import SwiftUI

/// An animated background view with subtle floating elements and gradients
public struct AnimatedBackgroundView: View {
    @State private var animationOffset1: CGFloat = 0
    @State private var animationOffset2: CGFloat = 0
    @State private var animationOffset3: CGFloat = 0
    @State private var rotationAngle: Double = 0
    
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color
    
    public init(
        primaryColor: Color = .blue,
        secondaryColor: Color = .purple,
        accentColor: Color = .cyan
    ) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.accentColor = accentColor
    }
    
    public var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    primaryColor.opacity(0.1),
                    secondaryColor.opacity(0.05),
                    accentColor.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating orbs
            Circle()
                .fill(primaryColor.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .offset(x: animationOffset1, y: -100)
                .animation(
                    Animation.easeInOut(duration: 8)
                        .repeatForever(autoreverses: true),
                    value: animationOffset1
                )
            
            Circle()
                .fill(secondaryColor.opacity(0.08))
                .frame(width: 150, height: 150)
                .blur(radius: 30)
                .offset(x: animationOffset2, y: 200)
                .animation(
                    Animation.easeInOut(duration: 10)
                        .repeatForever(autoreverses: true),
                    value: animationOffset2
                )
            
            Circle()
                .fill(accentColor.opacity(0.06))
                .frame(width: 100, height: 100)
                .blur(radius: 25)
                .offset(x: animationOffset3, y: -50)
                .animation(
                    Animation.easeInOut(duration: 12)
                        .repeatForever(autoreverses: true),
                    value: animationOffset3
                )
            
            // Subtle grid pattern
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let gridSize: CGFloat = 60
                    
                    // Vertical lines
                    for x in stride(from: 0, through: width, by: gridSize) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    
                    // Horizontal lines
                    for y in stride(from: 0, through: height, by: gridSize) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(primaryColor.opacity(0.03), lineWidth: 0.5)
            }
            
            // Rotating accent elements
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 4, height: 40)
                    .rotationEffect(.degrees(rotationAngle + Double(index * 120)))
                    .offset(x: CGFloat(index * 100 - 100), y: 0)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            animationOffset1 = 100
        }
        
        withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
            animationOffset2 = -80
        }
        
        withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
            animationOffset3 = 60
        }
        
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

#Preview {
    AnimatedBackgroundView()
        .ignoresSafeArea()
}
