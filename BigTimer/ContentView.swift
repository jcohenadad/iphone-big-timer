import SwiftUI

struct ContentView: View {
    @Environment(TimerModel.self) private var timer
    @State private var showSetup = false

    static let presets: [Int] = [1, 2, 3, 5, 10, 15, 20, 30, 45, 60]   // minutes

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            ZStack {
                background.ignoresSafeArea()

                VStack(spacing: landscape ? 8 : 16) {
                    infoLine
                    digits
                    progressBar
                    if timer.phase == .idle && !landscape { presetChips }
                    controls(compact: landscape)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, landscape ? 8 : 16)
            }
        }
        .sheet(isPresented: $showSetup) { SetupView() }
        .onAppear { timer.scenePhaseChanged(.active) }
    }

    // MARK: - Pieces

    private var isFlashOn: Bool {
        timer.phase == .finished && Int(timer.now.timeIntervalSince1970 * 2) % 2 == 0
    }

    private var background: Color {
        isFlashOn ? .red : .black
    }

    private var digitColor: Color {
        switch timer.phase {
        case .finished: return isFlashOn ? .white : .red
        case .paused: return .white.opacity(0.45)
        case .running where timer.remaining <= 10: return .orange
        default: return .white
        }
    }

    private var digits: some View {
        GeometryReader { geo in
            let text = TimerModel.format(timer.remaining)
            // Size the font to fill the available box (digits ≈ 0.6 em wide in rounded mono).
            let chars = CGFloat(max(text.count, 4))
            let size = min(geo.size.width / (chars * 0.58), geo.size.height * 0.95)
            Text(text)
                .font(.system(size: max(size, 10), weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(digitColor)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if timer.phase == .idle { showSetup = true } else { timer.primaryAction() }
        }
        .accessibilityLabel("Time remaining \(TimerModel.format(timer.remaining))")
    }

    private var infoLine: some View {
        HStack {
            switch timer.phase {
            case .idle: Text("Tap the time to change it")
            case .running:
                if let end = timer.endDate { Text("Ends at \(end.formatted(date: .omitted, time: .shortened))") }
            case .paused: Text("Paused — tap to resume")
            case .finished: Text("TIME'S UP").bold()
            }
        }
        .font(.headline)
        .foregroundStyle(.white.opacity(0.6))
        .frame(height: 22)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.15))
                Capsule().fill(digitColor).frame(width: geo.size.width * timer.progress)
            }
        }
        .frame(height: 6)
        .opacity(timer.phase == .idle ? 0 : 1)
    }

    private var presetChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Self.presets, id: \.self) { min in
                    let selected = Int(timer.duration) == min * 60
                    Button("\(min) min") { timer.setDuration(TimeInterval(min * 60)) }
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(selected ? Color.orange : Color.white.opacity(0.12), in: Capsule())
                        .foregroundStyle(selected ? Color.black : Color.white)
                }
            }
        }
    }

    private func controls(compact: Bool) -> some View {
        let side: CGFloat = compact ? 52 : 68
        return HStack(spacing: 16) {
            circleButton("arrow.counterclockwise", size: side) { timer.reset() }
                .disabled(timer.phase == .idle)
                .opacity(timer.phase == .idle ? 0.3 : 1)

            Button(action: timer.primaryAction) {
                Text(primaryTitle)
                    .font(.system(size: compact ? 22 : 28, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: side)
                    .background(primaryColor, in: Capsule())
                    .foregroundStyle(.black)
            }

            if timer.phase == .idle {
                circleButton("slider.horizontal.3", size: side) { showSetup = true }
            } else {
                Button { timer.add(60) } label: {
                    Text("+1:00")
                        .font(.system(size: compact ? 15 : 17, weight: .bold, design: .rounded))
                        .frame(width: side, height: side)
                        .background(.white.opacity(0.15), in: Circle())
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(maxWidth: 600)
    }

    private var primaryTitle: String {
        switch timer.phase {
        case .idle: return "Start"
        case .running: return "Pause"
        case .paused: return "Resume"
        case .finished: return "Stop"
        }
    }

    private var primaryColor: Color {
        switch timer.phase {
        case .idle, .paused: return .green
        case .running: return .orange
        case .finished: return .white
        }
    }

    private func circleButton(_ symbol: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.38, weight: .bold))
                .frame(width: size, height: size)
                .background(.white.opacity(0.15), in: Circle())
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    ContentView().environment(TimerModel())
}
