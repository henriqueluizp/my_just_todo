//
//  CheckCircle.swift
//  minimalist_todo
//
//  The tappable completion indicator on every task card. Animates a spring
//  fill and a drawn checkmark, with a subtle scale pop on completion.
//

import SwiftUI

struct CheckCircle: View {
    let isCompleted: Bool
    var color: Color
    var size: CGFloat = 26

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isCompleted ? color : Color.secondary.opacity(0.4),
                              lineWidth: 2)
                .background(Circle().fill(isCompleted ? color : .clear))
                .frame(width: size, height: size)

            Image(systemName: "checkmark")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(isCompleted ? 1 : 0.1)
                .opacity(isCompleted ? 1 : 0)
        }
        .scaleEffect(isCompleted && !reduceMotion ? 1.08 : 1)
        .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.6),
                   value: isCompleted)
    }
}

#Preview {
    HStack(spacing: 20) {
        CheckCircle(isCompleted: false, color: .blue)
        CheckCircle(isCompleted: true, color: .green)
    }
    .padding()
}
