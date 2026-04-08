import SwiftUI
import AppKit

struct IconView: View {
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(hex: "0A84FF"),
                    Color(hex: "5AC8FA")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 内发光效果
            RadialGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            
            // 时钟外圈
            Circle()
                .stroke(Color.white.opacity(0.9), lineWidth: 12)
                .frame(width: 700, height: 700)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            
            // 时钟刻度
            ForEach(0..<12) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: i % 3 == 0 ? 16 : 8, height: i % 3 == 0 ? 40 : 24)
                    .offset(y: -280)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            
            // 时针
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 20, height: 180)
                .offset(y: -60)
                .rotationEffect(.degrees(-60))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // 分针
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: 14, height: 260)
                .offset(y: -80)
                .rotationEffect(.degrees(30))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // 中心点
            Circle()
                .fill(Color.white)
                .frame(width: 40, height: 40)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // 中心点小细节
            Circle()
                .fill(Color(hex: "0A84FF"))
                .frame(width: 20, height: 20)
        }
        .frame(width: 1024, height: 1024)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// 生成图标
@MainActor
func generateIcon(size: CGFloat, outputPath: String) {
    let view = IconView()
        .frame(width: size, height: size)
    
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1.0
    
    if let nsImage = renderer.nsImage {
        if let tiffData = nsImage.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try? pngData.write(to: URL(fileURLWithPath: outputPath))
            print("Generated: \(outputPath)")
        }
    }
}

// 主函数
@MainActor
func main() {
    let iconSetPath = "/Users/lian/Xcode/foo/foo/Assets.xcassets/AppIcon.appiconset"
    
    // 生成所有尺寸的图标
    let sizes: [(String, CGFloat)] = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024)
    ]
    
    for (filename, size) in sizes {
        let path = "\(iconSetPath)/\(filename)"
        generateIcon(size: size, outputPath: path)
    }
    
    print("All icons generated successfully!")
}

await main()
