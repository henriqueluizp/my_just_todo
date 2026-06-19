//
//  OnboardingView.swift
//  minimalist_todo
//
//  A short, elegant first-run flow. Three paged screens introduce the
//  planner, organisation and insights, then mark onboarding complete.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.container) private var container
    @Environment(\.theme) private var theme
    var onFinish: () -> Void

    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let title: LocalizedStringKey
        let message: LocalizedStringKey
    }

    private let pages: [Page] = [
        .init(symbol: "calendar.day.timeline.left",
              title: "Plan with calm",
              message: "Glide through your days, weeks and months. Plan any date with a swipe."),
        .init(symbol: "checklist",
              title: "Organise effortlessly",
              message: "Priorities, categories and colour tags keep everything tidy and clear."),
        .init(symbol: "chart.line.uptrend.xyaxis",
              title: "Build momentum",
              message: "Track streaks and completion rates, and watch your progress grow.")
    ]

    var body: some View {
        VStack {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                    pageView(item).tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(action: advance) {
                Text(buttonLabel)
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.accent.gradient, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(theme.screenBackground)
    }

    private func pageView(_ item: Page) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: item.symbol)
                .font(.system(size: 84, weight: .light))
                .foregroundStyle(theme.accent.gradient)
                .symbolRenderingMode(.hierarchical)
            VStack(spacing: 12) {
                Text(item.title)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.center)
                Text(item.message)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
        }
    }

    private var buttonLabel: LocalizedStringKey {
        page == pages.count - 1 ? "Get started" : "Continue"
    }

    private func advance() {
        container.haptics.tap()
        if page < pages.count - 1 {
            withAnimation(.snappy) { page += 1 }
        } else {
            onFinish()
        }
    }
}
