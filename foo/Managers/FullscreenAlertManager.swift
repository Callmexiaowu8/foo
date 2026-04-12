import AppKit
import SwiftUI
import os.log

@available(macOS 14.0, *)
final class FullscreenAlertManager: NSObject, NSWindowDelegate {
    static let shared = FullscreenAlertManager()

    private var fullscreenWindow: NSWindow?
    private var hostingView: NSHostingView<FullscreenAlertContent>?
    private var autoDismissTimer: Timer?
    private var countdownTimer: Timer?
    private var pendingCompletion: (() -> Void)?
    private var currentDismissSeconds: Int = 15
    private var remainingSeconds: Int = 15
    private static let logger = Logger(subsystem: "com.foo.CountdownReminder", category: "FullscreenAlert")

    private override init() {
        super.init()
    }

    func showAlert(timer: CountdownTimer, autoDismissSeconds: Int? = nil, completion: @escaping () -> Void) {
        Self.logger.info("Showing fullscreen alert for timer: \(timer.title), autoDismiss: \(autoDismissSeconds ?? timer.autoDismissSeconds)s")

        currentDismissSeconds = autoDismissSeconds ?? timer.autoDismissSeconds
        remainingSeconds = currentDismissSeconds
        pendingCompletion = completion

        createAndShowFullscreenWindow(timer: timer)
    }

    func dismissAlert() {
        Self.logger.info("Dismissing fullscreen alert")

        DispatchQueue.main.async { [weak self] in
            self?.autoDismissTimer?.invalidate()
            self?.autoDismissTimer = nil
            self?.countdownTimer?.invalidate()
            self?.countdownTimer = nil
            self?.hideFullscreenWindow()
            self?.pendingCompletion?()
            self?.pendingCompletion = nil
        }
    }

    func updateRemainingSeconds(_ seconds: Int) {
        remainingSeconds = seconds
    }

    private static func playSystemSound() {
        let soundNames = ["Breeze", "Pop", "Glass", "Mail"]
        for name in soundNames {
            if let sound = NSSound(named: name) {
                sound.volume = 0.8
                sound.play()
                return
            }
        }
        NSSound.beep()
    }

    private func createAndShowFullscreenWindow(timer: CountdownTimer) {
        hideFullscreenWindow()

        guard let screen = NSScreen.main else {
            Self.logger.error("No main screen available")
            return
        }

        let content = FullscreenAlertContent(
            timerTitle: timer.title,
            timerDescription: timer.timerDescription ?? "",
            initialSeconds: currentDismissSeconds,
            soundEnabled: timer.soundEnabled,
            onDismiss: { [weak self] in
                self?.dismissAlert()
            },
            onSecondElapse: { [weak self] remaining in
                self?.remainingSeconds = remaining
            },
            onPlaySound: {
                FullscreenAlertManager.playSystemSound()
            }
        )

        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = screen.frame

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        window.delegate = self
        window.contentView = hostingView
        window.orderFrontRegardless()

        self.hostingView = hostingView
        self.fullscreenWindow = window

        Self.logger.info("Fullscreen window created on screen: \(screen.localizedName)")
    }

    private func hideFullscreenWindow() {
        fullscreenWindow?.orderOut(nil)
        fullscreenWindow = nil
        hostingView = nil
    }

    func windowWillClose(_ notification: Notification) {
        Self.logger.info("Fullscreen window will close")
    }

    func windowDidResignKey(_ notification: Notification) {
        Self.logger.info("Fullscreen window resigned key")
    }
}

@available(macOS 14.0, *)
struct FullscreenAlertContent: View {
    let timerTitle: String
    let timerDescription: String
    let initialSeconds: Int
    let soundEnabled: Bool
    let onDismiss: () -> Void
    var onSecondElapse: ((Int) -> Void)?
    var onPlaySound: (() -> Void)?

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var showContent = false
    @State private var remainingSeconds: Int
    @State private var ringProgress: Double = 1.0
    @State private var backgroundOpacity: Double = 0
    @State private var textColor: Color = .clear

    init(timerTitle: String, timerDescription: String, initialSeconds: Int, soundEnabled: Bool = true, onDismiss: @escaping () -> Void, onSecondElapse: ((Int) -> Void)? = nil, onPlaySound: (() -> Void)? = nil) {
        self.timerTitle = timerTitle
        self.timerDescription = timerDescription
        self.initialSeconds = initialSeconds
        self.soundEnabled = soundEnabled
        self.onDismiss = onDismiss
        self.onSecondElapse = onSecondElapse
        self.onPlaySound = onPlaySound
        _remainingSeconds = State(initialValue: initialSeconds)
    }

    var body: some View {
        ZStack {
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 3.0), value: backgroundOpacity)

            if showContent {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 120)

                    VStack(spacing: 40) {
                        countdownRingView
                            .foregroundColor(textColor)
                            .animation(.easeInOut(duration: 3.0), value: textColor)

                        titleSection
                            .foregroundColor(textColor)
                            .animation(.easeInOut(duration: 3.0), value: textColor)
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        HStack(spacing: 10) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 18))
                            Text("跳过")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(textColor)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.bottom, 140)
                }
                .scaleEffect(scale)
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showContent = true
            }

            withAnimation(.easeInOut(duration: 3.0)) {
                backgroundOpacity = 1.0
                textColor = .white
            }

            startCountdownTimer()

            if soundEnabled {
                onPlaySound?()
            }
        }
    }

    private var countdownRingView: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 10)
                .frame(width: 160, height: 160)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("\(remainingSeconds)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("秒")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .shadow(color: Color.orange.opacity(0.6), radius: 30, x: 0, y: 0)
    }

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text(timerTitle)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

            if !timerDescription.isEmpty {
                Text(timerDescription)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private func startCountdownTimer() {
        ringProgress = 1.0

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                ringProgress = Double(remainingSeconds) / Double(initialSeconds)
                onSecondElapse?(remainingSeconds)

                if remainingSeconds <= 0 {
                    timer.invalidate()
                    onDismiss()
                }
            } else {
                timer.invalidate()
            }
        }
    }
}

@available(macOS 14.0, *)
extension FullscreenAlertContent {
    struct KeyEventHandler: NSViewRepresentable {
        let onKeyDown: (NSEvent) -> Bool

        func makeNSView(context: Context) -> NSView {
            let view = KeyEventView()
            view.onKeyDown = onKeyDown
            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {}
    }

    class KeyEventView: NSView {
        var onKeyDown: ((NSEvent) -> Bool)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            if event.keyCode == 53 {
                onKeyDown?(event)
            }
        }
    }
}
