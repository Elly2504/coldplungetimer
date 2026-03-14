#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let center = Double(size) / 2.0

guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
      let ctx = CGContext(
          data: nil,
          width: size,
          height: size,
          bitsPerComponent: 8,
          bytesPerRow: size * 4,
          space: colorSpace,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ) else {
    fatalError("Failed to create CGContext")
}

// Background: #0A1628
ctx.setFillColor(red: 10/255, green: 22/255, blue: 40/255, alpha: 1.0)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Subtle radial gradient behind snowflake for depth
let gradientColors = [
    CGColor(red: 20/255, green: 40/255, blue: 70/255, alpha: 1.0),
    CGColor(red: 10/255, green: 22/255, blue: 40/255, alpha: 1.0)
] as CFArray
if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0, 1]) {
    ctx.drawRadialGradient(
        gradient,
        startCenter: CGPoint(x: center, y: center),
        startRadius: 0,
        endCenter: CGPoint(x: center, y: center),
        endRadius: Double(size) * 0.45,
        options: .drawsAfterEndLocation
    )
}

// Snowflake drawing helper
func drawArm(ctx: CGContext, cx: Double, cy: Double, angle: Double, length: Double, lineWidth: Double) {
    let endX = cx + cos(angle) * length
    let endY = cy + sin(angle) * length

    // Main arm
    ctx.move(to: CGPoint(x: cx, y: cy))
    ctx.addLine(to: CGPoint(x: endX, y: endY))

    // Branch 1 (at 60% of arm length)
    let branchLen = length * 0.35
    let b1x = cx + cos(angle) * (length * 0.6)
    let b1y = cy + sin(angle) * (length * 0.6)
    let branchAngle1 = angle + .pi / 4
    let branchAngle2 = angle - .pi / 4
    ctx.move(to: CGPoint(x: b1x, y: b1y))
    ctx.addLine(to: CGPoint(x: b1x + cos(branchAngle1) * branchLen, y: b1y + sin(branchAngle1) * branchLen))
    ctx.move(to: CGPoint(x: b1x, y: b1y))
    ctx.addLine(to: CGPoint(x: b1x + cos(branchAngle2) * branchLen, y: b1y + sin(branchAngle2) * branchLen))

    // Branch 2 (at 35% of arm length)
    let branchLen2 = length * 0.22
    let b2x = cx + cos(angle) * (length * 0.35)
    let b2y = cy + sin(angle) * (length * 0.35)
    ctx.move(to: CGPoint(x: b2x, y: b2y))
    ctx.addLine(to: CGPoint(x: b2x + cos(branchAngle1) * branchLen2, y: b2y + sin(branchAngle1) * branchLen2))
    ctx.move(to: CGPoint(x: b2x, y: b2y))
    ctx.addLine(to: CGPoint(x: b2x + cos(branchAngle2) * branchLen2, y: b2y + sin(branchAngle2) * branchLen2))

    // Small diamond tip
    let tipSize = length * 0.06
    ctx.move(to: CGPoint(x: endX, y: endY - tipSize))
    ctx.addLine(to: CGPoint(x: endX + tipSize, y: endY))
    ctx.addLine(to: CGPoint(x: endX, y: endY + tipSize))
    ctx.addLine(to: CGPoint(x: endX - tipSize, y: endY))
    ctx.closePath()
}

let armLength = Double(size) * 0.32
let iceBlue = CGColor(red: 100/255, green: 210/255, blue: 255/255, alpha: 1.0)

// Glow layer (wider, semi-transparent)
ctx.setStrokeColor(CGColor(red: 100/255, green: 210/255, blue: 255/255, alpha: 0.25))
ctx.setLineWidth(18)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)

for i in 0..<6 {
    let angle = Double(i) * (.pi / 3) - .pi / 2
    drawArm(ctx: ctx, cx: center, cy: center, angle: angle, length: armLength, lineWidth: 18)
}
ctx.strokePath()

// Main snowflake (crisp)
ctx.setStrokeColor(iceBlue)
ctx.setLineWidth(8)

for i in 0..<6 {
    let angle = Double(i) * (.pi / 3) - .pi / 2
    drawArm(ctx: ctx, cx: center, cy: center, angle: angle, length: armLength, lineWidth: 8)
}
ctx.strokePath()

// Center hexagon
ctx.setFillColor(iceBlue)
let hexRadius = Double(size) * 0.04
let hexPath = CGMutablePath()
for i in 0..<6 {
    let angle = Double(i) * (.pi / 3) - .pi / 2
    let x = center + cos(angle) * hexRadius
    let y = center + sin(angle) * hexRadius
    if i == 0 {
        hexPath.move(to: CGPoint(x: x, y: y))
    } else {
        hexPath.addLine(to: CGPoint(x: x, y: y))
    }
}
hexPath.closeSubpath()
ctx.addPath(hexPath)
ctx.fillPath()

// Small ice particles scattered around
ctx.setFillColor(CGColor(red: 100/255, green: 210/255, blue: 255/255, alpha: 0.4))
let particles: [(Double, Double, Double)] = [
    (0.18, 0.22, 4), (0.82, 0.25, 3), (0.15, 0.78, 3.5),
    (0.85, 0.80, 4), (0.25, 0.50, 2.5), (0.78, 0.48, 3),
    (0.50, 0.15, 3), (0.48, 0.85, 2.5)
]
for (px, py, pr) in particles {
    let rect = CGRect(
        x: px * Double(size) - pr,
        y: py * Double(size) - pr,
        width: pr * 2,
        height: pr * 2
    )
    ctx.fillEllipse(in: rect)
}

// Export PNG
guard let image = ctx.makeImage() else {
    fatalError("Failed to create image")
}

let outputPath = "IceDip/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let url = URL(fileURLWithPath: outputPath)

guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Failed to create image destination")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else {
    fatalError("Failed to write PNG")
}

print("App icon generated at \(outputPath)")
