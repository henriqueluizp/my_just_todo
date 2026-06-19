//
//  StatisticsView.swift
//  minimalist_todo
//
//  Productivity dashboard: streak, today's completions, all-time total, and
//  weekly/monthly completion rates, plus a 7-day completion bar chart.
//

import Charts
import SwiftUI

struct StatisticsView: View {
    @Environment(\.theme) private var theme
    @State private var viewModel: StatisticsViewModel

    init(viewModel: StatisticsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacingL) {
                    streakBanner
                    statGrid
                    weeklyChart
                    ratesCard
                }
                .padding(theme.spacingM)
            }
            .background(theme.screenBackground)
            .navigationTitle("Insights")
            .onAppear { viewModel.recompute() }
        }
    }

    private var streakBanner: some View {
        HStack(spacing: theme.spacingM) {
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange.gradient)
                .symbolEffect(.bounce, value: viewModel.currentStreak)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.currentStreak)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("day streak")
                    .font(theme.callout).foregroundStyle(.secondary)
            }
            Spacer()
            Text(streakMessage)
                .font(theme.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 130)
        }
        .padding(theme.spacingL)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.radiusL))
        .softShadow()
    }

    private var statGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            StatCard(title: "Completed today", value: "\(viewModel.completedToday)",
                     symbol: "checkmark.circle.fill", tint: theme.accent)
            StatCard(title: "All-time done", value: "\(viewModel.totalCompleted)",
                     symbol: "trophy.fill", tint: .yellow)
            StatCard(title: "This week", value: "\(Int(viewModel.weeklyRate * 100))%",
                     symbol: "calendar", tint: .green)
            StatCard(title: "This month", value: "\(Int(viewModel.monthlyRate * 100))%",
                     symbol: "calendar.badge.clock", tint: .purple)
        }
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: theme.spacingM) {
            Text("Last 7 days").font(theme.headline)
            Chart(viewModel.last7Days) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Completed", day.completed)
                )
                .foregroundStyle(theme.accent.gradient)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3))
            }
            .frame(height: 180)
        }
        .padding(theme.spacingM)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.radiusL))
        .softShadow()
    }

    private var ratesCard: some View {
        VStack(spacing: theme.spacingM) {
            RateBar(title: "Weekly completion", fraction: viewModel.weeklyRate, tint: .green)
            RateBar(title: "Monthly completion", fraction: viewModel.monthlyRate, tint: .purple)
        }
        .padding(theme.spacingM)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.radiusL))
        .softShadow()
    }

    private var streakMessage: LocalizedStringKey {
        switch viewModel.currentStreak {
        case 0: "Complete a task today to start a streak"
        case 1..<3: "Keep it going!"
        case 3..<7: "You're building a habit"
        default: "Incredible consistency 🎉"
        }
    }
}

// MARK: - Building blocks

private struct StatCard: View {
    let title: LocalizedStringKey
    let value: String
    let symbol: String
    let tint: Color
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(tint.gradient)
            Text(value)
                .font(.system(.title, design: .rounded).weight(.bold))
                .contentTransition(.numericText())
            Text(title)
                .font(theme.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacingM)
        .background(theme.cardBackground, in: RoundedRectangle(cornerRadius: theme.radiusM))
        .softShadow()
    }
}

private struct RateBar: View {
    let title: LocalizedStringKey
    let fraction: Double
    let tint: Color
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(theme.callout)
                Spacer()
                Text("\(Int(fraction * 100))%")
                    .font(.system(.callout, design: .rounded).weight(.semibold))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(tint.opacity(0.15))
                    Capsule().fill(tint.gradient)
                        .frame(width: max(8, geo.size.width * fraction))
                }
            }
            .frame(height: 10)
        }
    }
}
