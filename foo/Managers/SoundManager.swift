import Foundation
import AppKit

@available(macOS 10.9, *)
final class SoundManager {
    static let shared = SoundManager()

    private(set) var isSoundEnabled: Bool = true
    private var currentPlayId: Int = 0
    private var activeTimers: [Int: Timer] = [:]
    private var activeSounds: [Int: NSSound] = [:]

    private init() {}

    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
        if !enabled {
            stopAllSounds()
        }
    }

    func playAlertSound() {
        guard isSoundEnabled else { return }

        currentPlayId += 1
        let playId = currentPlayId

        let soundName = "Breeze"
        if let sound = NSSound(named: soundName) {
            sound.volume = 0.0
            sound.play()

            activeSounds[playId] = sound

            fadeIn(sound: sound, playId: playId, targetVolume: 0.25)

            scheduleTask(playId: playId, delay: 1.5) { [weak self] in
                self?.fadeOutAndStop(playId: playId)
            }

            scheduleTask(playId: playId, delay: 2.5) { [weak self] in
                self?.cleanup(playId: playId)
            }
        } else {
            NSSound.beep()
        }
    }

    func stopAllSounds() {
        for (_, timer) in activeTimers {
            timer.invalidate()
        }
        activeTimers.removeAll()

        for (_, sound) in activeSounds {
            sound.stop()
        }
        activeSounds.removeAll()

        currentPlayId = 0
    }

    private func scheduleTask(playId: Int, delay: TimeInterval, task: @escaping () -> Void) {
        let timer = Timer(timeInterval: delay, target: self, selector: #selector(executeScheduledTask(_:)), userInfo: ["playId": playId, "task": TaskWrapper(task)], repeats: false)
        RunLoop.main.add(timer, forMode: .common)
        activeTimers[playId] = timer
    }

    @objc private func executeScheduledTask(_ timer: Timer) {
        guard let userInfo = timer.userInfo as? [String: Any],
              let taskWrapper = userInfo["task"] as? TaskWrapper else {
            return
        }

        taskWrapper.task()
        timer.invalidate()

        if let playId = userInfo["playId"] as? Int {
            activeTimers.removeValue(forKey: playId)
        }
    }

    private func fadeIn(sound: NSSound, playId: Int, targetVolume: Float) {
        let timer = Timer(timeInterval: 0.05, target: self, selector: #selector(fadeInStep(_:)), userInfo: ["sound": sound, "playId": playId, "targetVolume": targetVolume], repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        activeTimers[playId * 100 + 1] = timer
    }

    @objc private func fadeInStep(_ timer: Timer) {
        guard let userInfo = timer.userInfo as? [String: Any],
              let sound = userInfo["sound"] as? NSSound,
              let targetVolume = userInfo["targetVolume"] as? Float else {
            timer.invalidate()
            return
        }

        if sound.volume < targetVolume {
            sound.volume += 0.02
        } else {
            timer.invalidate()
        }
    }

    private func fadeOutAndStop(playId: Int) {
        guard let sound = activeSounds[playId] else { return }

        let timer = Timer(timeInterval: 0.05, target: self, selector: #selector(fadeOutStep(_:)), userInfo: ["sound": sound, "playId": playId], repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        activeTimers[playId * 100 + 2] = timer
    }

    @objc private func fadeOutStep(_ timer: Timer) {
        guard let userInfo = timer.userInfo as? [String: Any],
              let sound = userInfo["sound"] as? NSSound,
              let playId = userInfo["playId"] as? Int else {
            timer.invalidate()
            return
        }

        if sound.volume > 0.05 {
            sound.volume -= 0.03
        } else {
            sound.stop()
            timer.invalidate()
            activeSounds.removeValue(forKey: playId)
            activeTimers.removeValue(forKey: playId * 100 + 2)
        }
    }

    private func cleanup(playId: Int) {
        activeSounds.removeValue(forKey: playId)
        activeTimers.removeValue(forKey: playId * 100 + 1)
        activeTimers.removeValue(forKey: playId * 100 + 2)
    }

    func playSystemSound() {
        guard isSoundEnabled else { return }

        currentPlayId += 1
        let playId = currentPlayId

        let soundName = "Pop"
        if let sound = NSSound(named: soundName) {
            sound.volume = 0.0
            sound.play()

            activeSounds[playId] = sound

            fadeIn(sound: sound, playId: playId, targetVolume: 0.2)

            scheduleTask(playId: playId, delay: 1.0) { [weak self] in
                self?.fadeOutAndStop(playId: playId)
            }

            scheduleTask(playId: playId, delay: 1.5) { [weak self] in
                self?.cleanup(playId: playId)
            }
        } else {
            NSSound.beep()
        }
    }

    func playSkipSound() {
        guard isSoundEnabled else { return }

        let soundName = "Pop"
        if let sound = NSSound(named: soundName) {
            sound.volume = 0.15
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}

private class TaskWrapper {
    let task: () -> Void

    init(_ task: @escaping () -> Void) {
        self.task = task
    }
}
