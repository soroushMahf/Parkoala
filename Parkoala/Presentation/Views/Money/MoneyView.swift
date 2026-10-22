//
//MoneyView.swift
//Parkoala
//
//  Created by jessica dao on 22/10/2026.

// The Money tab. Shows this month's spending and any finished
// sessions that still need a cost entered.

import SwiftUI

struct MoneyView: View {

    @State private var viewModel: MoneyViewModel
    @State private var sessionForCostEntry: ParkingSession?

    init(viewModel: MoneyViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? .live())
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.uncostedSessions.isEmpty
                    && viewModel.costedSessions.isEmpty
                    && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No parking costs yet",
                        systemImage: "dollarsign.circle",
                        description: Text("Finished sessions will show up here.")
                    )
                } else {
                    List {
                        Section("This month") {
                            LabeledContent("Total Spent", value: viewModel.monthSummary.totalSpent.formatted(.currency(code: "AUD")))
                            LabeledContent("Parking Sessions", value: "\(viewModel.monthSummary.sessionCount)")
                            LabeledContent("Average Spending", value: viewModel.monthSummary.averageCost.formatted(.currency(code: "AUD")))
                        }

                        if !viewModel.uncostedSessions.isEmpty {
                            Section("Sessions without costs") {
                                ForEach(viewModel.uncostedSessions) { session in
                                    Button {
                                        sessionForCostEntry = session
                                    } label: {
                                        MoneySessionRow(session: session)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if !viewModel.costedSessions.isEmpty {
                            Section("Recent") {
                                ForEach(viewModel.costedSessions) { session in
                                    Button {
                                        sessionForCostEntry = session
                                    } label: {
                                        MoneySessionRow(session: session)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Money")
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $sessionForCostEntry) { session in
                AddSessionCostView(session: session, viewModel: viewModel)
            }
        }
    }
}

private struct MoneySessionRow: View {

    let session: ParkingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.startDate.formatted(.dateTime.weekday(.wide).day().month()))
                .font(.headline)
                .foregroundStyle(.primary)

            HStack {
                Text(SessionFormat.timeRange(session))
                Spacer()
                if let cost = session.cost {
                    Text(cost.formatted(.currency(code: "AUD")))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                } else {
                    Text("Add cost")
                        .foregroundStyle(.blue)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview("With sessions") {
    MoneyView(viewModel: .preview(withSamples: true))
}

#Preview("Empty") {
    MoneyView(viewModel: .preview(withSamples: false))
}
