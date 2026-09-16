import SwiftUI

struct SetupView: View {
    @Environment(TimerModel.self) private var timer
    @Environment(\.dismiss) private var dismiss
    @State private var hours = 0
    @State private var minutes = 5
    @State private var seconds = 0

    private var total: Int { hours * 3600 + minutes * 60 + seconds }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text(TimerModel.format(TimeInterval(total)))
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .monospacedDigit()

                    HStack(spacing: 0) {
                        wheel($hours, 0..<24, "h")
                        wheel($minutes, 0..<60, "min")
                        wheel($seconds, 0..<60, "sec")
                    }
                    .frame(height: 200)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                        ForEach(ContentView.presets, id: \.self) { min in
                            Button("\(min)m") { apply(min * 60) }
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(total == min * 60 ? Color.orange : Color.white.opacity(0.12),
                                            in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(total == min * 60 ? Color.black : Color.white)
                        }
                    }

                    HStack(spacing: 10) {
                        ForEach([10, 30, 60, 300], id: \.self) { step in
                            Button("+" + (step < 60 ? "\(step)s" : "\(step / 60)m")) { apply(min(total + step, 86_399)) }
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Button {
                        timer.setDuration(TimeInterval(total))
                        timer.start()
                        dismiss()
                    } label: {
                        Text("Start")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(Color.green, in: Capsule())
                            .foregroundStyle(.black)
                    }
                    .disabled(total == 0)
                    .opacity(total == 0 ? 0.4 : 1)
                }
                .padding()
            }
            .navigationTitle("Set timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        timer.setDuration(TimeInterval(total))
                        dismiss()
                    }
                    .disabled(total == 0)
                }
            }
        }
        .onAppear { apply(Int(timer.duration)) }
    }

    private func apply(_ totalSeconds: Int) {
        hours = totalSeconds / 3600
        minutes = (totalSeconds % 3600) / 60
        seconds = totalSeconds % 60
    }

    private func wheel(_ value: Binding<Int>, _ range: Range<Int>, _ unit: String) -> some View {
        Picker(unit, selection: value) {
            ForEach(range, id: \.self) { Text("\($0) \(unit)").tag($0) }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}
