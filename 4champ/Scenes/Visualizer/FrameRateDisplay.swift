import UIKit

class FrameRateMonitor {
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0

    // Label to display the frame rate
    private let fpsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.backgroundColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        return label
    }()

    init() {
        setupDisplayLink()
    }

    deinit {
        displayLink?.invalidate()
    }

    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func displayLinkDidFire(displayLink: CADisplayLink) {
        guard lastTimestamp != 0 else {
            lastTimestamp = displayLink.timestamp
            return
        }

        // Calculate frame count and time delta
        frameCount += 1
        let delta = displayLink.timestamp - lastTimestamp

        // Update the frame rate every second
        if delta >= 1.0 {
            let fps = Double(frameCount) / delta
            fpsLabel.text = String(format: "%.1f FPS", fps)
            lastTimestamp = displayLink.timestamp
            frameCount = 0
        }
    }

    func addFpsLabel(to view: UIView) {
        view.addSubview(fpsLabel)
        fpsLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        fpsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
    }
}
