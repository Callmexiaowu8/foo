import AppKit
import SwiftUI
import os.log

@available(macOS 14.0, *)
final class FullscreenAlertManager: NSObject, NSWindowDelegate {
    static let shared = FullscreenAlertManager()

    private var fullscreenWindow: NSWindow?
    private var hostingView: NSHostingView<FullscreenAlertContent>?
    private var autoDismissTimer: Timer?
    private var pendingCompletion: (() -> Void)?
    private var currentDismissSeconds: Int = 15
    private var remainingSeconds: Int = 15
    private var currentTimer: CountdownTimer?
    private static let logger = Logger(subsystem: "com.foo.CountdownReminder", category: "FullscreenAlert")

    class KeyEventView: NSView {
        var onKeyDown: ((NSEvent) -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            if event.keyCode == 53 {
                onKeyDown?(event)
            }
        }

        override var frame: NSRect {
            didSet {
                subviews.forEach { $0.frame = bounds }
            }
        }

        override func layout() {
            super.layout()
            subviews.forEach { $0.frame = bounds }
        }
    }

    private override init() {
        super.init()
    }

    func showAlert(timer: CountdownTimer, autoDismissSeconds: Int? = nil, completion: @escaping () -> Void) {
        Self.logger.info("Showing fullscreen alert for timer: \(timer.title), autoDismiss: \(autoDismissSeconds ?? timer.autoDismissSeconds)s")

        currentTimer = timer
        currentDismissSeconds = autoDismissSeconds ?? timer.autoDismissSeconds
        remainingSeconds = currentDismissSeconds
        pendingCompletion = completion

        createAndShowFullscreenWindow(timer: timer)
    }

    func dismissAlert() {
        Self.logger.info("Dismissing fullscreen alert")

        DispatchQueue.main.async { [weak self] in
            SoundManager.shared.stopAllSounds()
            self?.autoDismissTimer?.invalidate()
            self?.autoDismissTimer = nil
            self?.hideFullscreenWindow()
            self?.pendingCompletion?()
            self?.pendingCompletion = nil
        }
    }

    private func handleSkip() {
        if let timer = currentTimer, timer.soundEnabled {
            SoundManager.shared.playSkipSound()
        }
        dismissAlert()
    }

    func updateRemainingSeconds(_ seconds: Int) {
        remainingSeconds = seconds
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
            onNaturalEnd: { [weak self] in
                if timer.soundEnabled {
                    SoundManager.shared.playAlertSound()
                }
                self?.dismissAlert()
            },
            onSkip: { [weak self] in
                if timer.soundEnabled {
                    SoundManager.shared.playSkipSound()
                }
                self?.dismissAlert()
            },
            onSecondElapse: { [weak self] remaining in
                self?.remainingSeconds = remaining
            }
        )

        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = screen.frame

        let keyEventView = KeyEventView()
        keyEventView.frame = screen.frame
        keyEventView.onKeyDown = { [weak self] _ in
            self?.handleSkip()
        }
        keyEventView.addSubview(hostingView)

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
        window.contentView = keyEventView
        window.orderFrontRegardless()
        window.makeFirstResponder(keyEventView)

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
    var onNaturalEnd: (() -> Void)?
    var onSkip: (() -> Void)?
    var onDismiss: (() -> Void)?
    var onSecondElapse: ((Int) -> Void)?

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var showContent = false
    @State private var remainingSeconds: Int
    @State private var ringProgress: Double = 1.0
    @State private var backgroundOpacity: Double = 0
    @State private var textColor: Color = .clear
    @State private var countdownTimer: Timer?

    init(timerTitle: String, timerDescription: String, initialSeconds: Int, soundEnabled: Bool = true, onNaturalEnd: (() -> Void)? = nil, onSkip: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil, onSecondElapse: ((Int) -> Void)? = nil) {
        self.timerTitle = timerTitle
        self.timerDescription = timerDescription
        self.initialSeconds = initialSeconds
        self.soundEnabled = soundEnabled
        self.onNaturalEnd = onNaturalEnd
        self.onSkip = onSkip
        self.onDismiss = onDismiss
        self.onSecondElapse = onSecondElapse
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

                    Button(action: {
                        self.stopCountdownTimer()
                        onSkip?()
                    }) {
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
        }
        .focusable()
        .onKeyPress(.escape) {
            self.stopCountdownTimer()
            onSkip?()
            return .handled
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

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] timer in
            DispatchQueue.main.async {
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                    self.ringProgress = Double(self.remainingSeconds) / Double(self.initialSeconds)
                    self.onSecondElapse?(self.remainingSeconds)

                    if self.remainingSeconds <= 0 {
                        timer.invalidate()
                        self.countdownTimer = nil
                        self.onNaturalEnd?()
                    }
                } else {
                    timer.invalidate()
                    self.countdownTimer = nil
                }
            }
        }
    }

    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}
