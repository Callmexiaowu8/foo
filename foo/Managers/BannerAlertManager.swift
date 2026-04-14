import AppKit
import SwiftUI
import os.log

@available(macOS 14.0, *)
final class BannerAlertManager: NSObject, NSWindowDelegate {
    static let shared = BannerAlertManager()

    private var bannerWindows: [UUID: NSWindow] = [:]
    private var dismissTimers: [UUID: Timer] = [:]
    private static let logger = Logger(subsystem: "com.foo.CountdownReminder", category: "BannerAlert")

    private override init() {
        super.init()
    }

    func showBanner(timer: CountdownTimer, autoDismissSeconds: TimeInterval = 10, completion: @escaping () -> Void) {
        Self.logger.info("Showing banner alert for timer: \(timer.title)")

        DispatchQueue.main.async { [weak self] in
            self?.createAndShowBanner(timer: timer, autoDismissSeconds: autoDismissSeconds, completion: completion)
        }
    }

    func dismissBanner(for timerId: UUID) {
        Self.logger.info("Dismissing banner for timer: \(timerId.uuidString)")

        DispatchQueue.main.async { [weak self] in
            self?.hideBanner(for: timerId)
        }
    }

    func dismissAllBanners() {
        Self.logger.info("Dismissing all banners")

        DispatchQueue.main.async { [weak self] in
            self?.dismissTimers.values.forEach { $0.invalidate() }
            self?.dismissTimers.removeAll()

            for (_, window) in self?.bannerWindows ?? [:] {
                self?.animateBannerOut(window: window)
            }
            self?.bannerWindows.removeAll()
        }
    }

    private func createAndShowBanner(timer: CountdownTimer, autoDismissSeconds: TimeInterval, completion: @escaping () -> Void) {
        hideBanner(for: timer.id)

        guard let screen = NSScreen.main else {
            Self.logger.error("No main screen available")
            return
        }

        let bannerWidth: CGFloat = 320
        let bannerHeight: CGFloat = 100
        let rightMargin: CGFloat = 20
        let topMargin: CGFloat = 80

        let bannerRect = NSRect(
            x: screen.frame.width - bannerWidth - rightMargin,
            y: screen.frame.height - bannerHeight - topMargin,
            width: bannerWidth,
            height: bannerHeight
        )

        let content = BannerAlertContent(
            timerTitle: timer.title,
            timerDescription: timer.timerDescription ?? "",
            onDismiss: { [weak self] in
                self?.hideBanner(for: timer.id)
                completion()
            }
        )

        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(origin: .zero, size: bannerRect.size)

        let window = NSWindow(
            contentRect: bannerRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        window.delegate = self
        window.contentView = hostingView

        let initialFrame = NSRect(
            x: bannerRect.origin.x,
            y: bannerRect.origin.y + 20,
            width: bannerWidth,
            height: bannerHeight
        )
        window.setFrame(initialFrame, display: false)
        window.alphaValue = 0

        window.orderFront(nil)
        window.makeKeyAndOrderFront(nil)
        animateBannerIn(window: window, finalFrame: bannerRect)

        bannerWindows[timer.id] = window

        let dismissTimer = Timer.scheduledTimer(withTimeInterval: autoDismissSeconds, repeats: false) { [weak self] _ in
            self?.hideBanner(for: timer.id)
            completion()
        }
        dismissTimers[timer.id] = dismissTimer
    }

    private func hideBanner(for timerId: UUID) {
        dismissTimers[timerId]?.invalidate()
        dismissTimers.removeValue(forKey: timerId)

        if let window = bannerWindows.removeValue(forKey: timerId) {
            animateBannerOut(window: window)
        }
    }

    private func animateBannerIn(window: NSWindow, finalFrame: NSRect) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(finalFrame, display: true)
        }
    }

    private func animateBannerOut(window: NSWindow) {
        let currentFrame = window.frame
        let exitFrame = NSRect(
            x: currentFrame.origin.x,
            y: currentFrame.origin.y + 20,
            width: currentFrame.width,
            height: currentFrame.height
        )

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
            window.animator().setFrame(exitFrame, display: true)
        }, completionHandler: {
            window.orderOut(nil)
        })
    }

    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            for (id, w) in bannerWindows {
                if w === window {
                    bannerWindows.removeValue(forKey: id)
                    dismissTimers[id]?.invalidate()
                    dismissTimers.removeValue(forKey: id)
                    break
                }
            }
        }
    }
}

@available(macOS 14.0, *)
struct BannerAlertContent: View {
    let timerTitle: String
    let timerDescription: String
    let onDismiss: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "timer")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("时间到！")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)

                    Text(timerTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if !timerDescription.isEmpty {
                        Text(timerDescription)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.15))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }

            HStack {
                Spacer()

                Button(action: onDismiss) {
                    Text("知道了")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(14)
        .frame(width: 320, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}
