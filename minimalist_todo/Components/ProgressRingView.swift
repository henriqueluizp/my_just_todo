//
//  ProgressRingView.swift
//  minimalist_todo
//
//  Circular daily-progress ring with a centred percentage. Used in the day
//  header and the statistics dashboard.
//

import SwiftUI

struct ProgressRingView: View {
    var progress: Double          // 0...1
    var color: Color
    var lineWidth: CGFloat = 8
    var size: CGFloat = 64
    var showsPercentage: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.8),
                           value: progress)

            if showsPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel("Daily progress")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}

#Preview {
    ProgressRingView(progress: 0.66, color: .blue)
        .padding()
}
