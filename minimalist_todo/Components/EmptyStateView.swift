//
//  EmptyStateView.swift
//  minimalist_todo
//
//  Elegant, illustration-style empty state with a soft gradient glyph and a
//  motivational message. Used across the planner, search and trash screens.
//

import SwiftUI

struct EmptyStateView: View {
    var symbol: String
    var title: LocalizedStringKey
    var message: LocalizedStringKey
    var tint: Color
    var actionTitle: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: symbol)
                    .font(.system(size: 46, weight: .regular))
                    .foregroundStyle(tint.gradient)
                    .symbolRenderingMode(.hierarchical)
            }
            .scaleEffect(appeared || reduceMotion ? 1 : 0.6)
            .opacity(appeared || reduceMotion ? 1 : 0)

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                Text(message)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(tint, in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appeared = true }
        }
    }
}

#Preview {
    EmptyStateView(symbol: "checkmark.circle",
                   title: "All clear",
                   message: "You have nothing scheduled for this day. Enjoy the calm.",
                   tint: .blue,
                   actionTitle: "Add a task") {}
}
