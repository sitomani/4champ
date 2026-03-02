//
//  CarPlayController.swift
//  4champ Amiga Music Player
//
//  Copyright © 2026 Aleksi Sitomaniemi. All rights reserved.
//

import CarPlay
import Foundation
import MediaPlayer

class CarPlayController: NSObject {

    private weak var interfaceController: CPInterfaceController?
    private var fetcher: ModuleFetcher?
    private var lastPlayedModules: [MMD] = []
    private var nowPlayingTemplate: CPListTemplate?

    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        super.init()
        modulePlayer.addPlayerObserver(self)
        setupRemoteCommands()
    }

    deinit {
        teardownRemoteCommands()
        modulePlayer.removePlayerObserver(self)
    }

    // MARK: - Root template

    func makeRootTemplate() -> CPListTemplate {
        let item = CPListItem(text: "Last played",
                             detailText: "Recently played modules",
                             image: nil,
                             showsDisclosureIndicator: true)
        item.handler = { [weak self] _, done in
            DispatchQueue.main.async { self?.pushLastPlayedTemplate() }
            done()
        }
        return CPListTemplate(title: "4champ", sections: [CPListSection(items: [item])])
    }

    // MARK: - Remote command centre

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.playCommand.addTarget { _ in
            modulePlayer.resume()
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { _ in
            modulePlayer.pause()
            return .success
        }

        center.stopCommand.isEnabled = true
        center.stopCommand.addTarget { _ in
            modulePlayer.stop()
            return .success
        }

        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { _ in
            modulePlayer.playNext()
            return .success
        }

        center.previousTrackCommand.isEnabled = true
        center.previousTrackCommand.addTarget { _ in
            modulePlayer.playPrev()
            return .success
        }
    }

    private func teardownRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.stopCommand.removeTarget(nil)
        center.nextTrackCommand.removeTarget(nil)
        center.previousTrackCommand.removeTarget(nil)
    }

    // MARK: - Custom Now Playing template

    private func makeNowPlayingSections(module: MMD, isPlaying: Bool) -> [CPListSection] {
        // Info row: album art + module name + composer/type
        let parts = [module.composer, module.type].compactMap { $0 }.filter { !$0.isEmpty }
        let detail = parts.joined(separator: " • ")
        let artwork = UIImage(named: "albumart")
        let infoItem = CPListItem(text: module.name,
                                  detailText: detail.isEmpty ? nil : detail,
                                  image: artwork,
                                  showsDisclosureIndicator: false)
        infoItem.accessoryType = .none
        infoItem.handler = { _, done in done() }

        // Playback control rows
        let toggleItem = CPListItem(text: isPlaying ? "Pause" : "Play", detailText: nil,
                                    image: controlIcon(named: isPlaying ? "pause-small" : "play-small"))
        toggleItem.handler = { _, done in
            if modulePlayer.status == .playing { modulePlayer.pause() } else { modulePlayer.resume() }
            done()
        }

        let prevItem = CPListItem(text: "Previous", detailText: nil, image: controlIcon(named: "prev-small"))
        prevItem.handler = { _, done in
            modulePlayer.playPrev()
            done()
        }

        let nextItem = CPListItem(text: "Next", detailText: nil, image: controlIcon(named: "next-small"))
        nextItem.handler = { _, done in
            modulePlayer.playNext()
            done()
        }

        return [
            CPListSection(items: [infoItem]),
            CPListSection(items: [toggleItem, prevItem, nextItem])
        ]
    }

    private func showOrUpdateNowPlaying(module: MMD, isPlaying: Bool) {
        let sections = makeNowPlayingSections(module: module, isPlaying: isPlaying)
        if let existing = nowPlayingTemplate,
           interfaceController?.topTemplate === existing {
            existing.updateSections(sections)
        } else {
            let template = CPListTemplate(title: "Now Playing", sections: sections)
            nowPlayingTemplate = template
            interfaceController?.pushTemplate(template, animated: true, completion: nil)
        }
    }

    // MARK: - MPNowPlayingInfoCenter (lock screen / AirPlay)

    private func setNowPlayingInfo(for module: MMD, playbackRate: Double) {
        let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { _ in
            UIImage(named: "albumart") ?? UIImage()
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle:                    module.name,
            MPMediaItemPropertyArtist:                   module.composer ?? "",
            MPMediaItemPropertyArtwork:                  artwork,
            MPNowPlayingInfoPropertyPlaybackRate:         NSNumber(value: playbackRate),
            MPNowPlayingInfoPropertyElapsedPlaybackTime:  NSNumber(value: Double(modulePlayer.renderer.currentPosition())),
            MPMediaItemPropertyPlaybackDuration:          NSNumber(value: Double(modulePlayer.renderer.moduleLength()))
        ]
    }

    private func updatePlaybackRate(_ rate: Double) {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: rate)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Image helpers

    private func controlIcon(named name: String) -> UIImage? {
        guard let image = UIImage(named: name) else { return nil }
        let size = CGSize(width: 12, height: 12)
        return UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Navigation helpers

    private func pushLastPlayedTemplate() {
        let items: [CPListItem]
        if lastPlayedModules.isEmpty {
            items = [CPListItem(text: "No modules played yet", detailText: nil)]
        } else {
            items = lastPlayedModules.map { mmd in
                let parts = [mmd.composer, mmd.type].compactMap { $0 }.filter { !$0.isEmpty }
                let detail = parts.joined(separator: " • ")
                let item = CPListItem(text: mmd.name, detailText: detail.isEmpty ? nil : detail)
                item.handler = { [weak self] _, done in
                    DispatchQueue.main.async { self?.playOrFetch(mmd: mmd) }
                    done()
                }
                return item
            }
        }
        let template = CPListTemplate(title: "Last played", sections: [CPListSection(items: items)])
        interfaceController?.pushTemplate(template, animated: true, completion: nil)
    }

    private func playOrFetch(mmd: MMD) {
        if mmd.fileExists() {
            modulePlayer.play(mmd: mmd)
        } else if let id = mmd.id {
            fetcher?.cancel()
            fetcher = ModuleFetcher(delegate: self)
            fetcher?.fetchModule(ampId: id)
        }
    }
}

// MARK: - ModuleFetcherDelegate

extension CarPlayController: ModuleFetcherDelegate {

    func fetcherStateChanged(_ fetcher: ModuleFetcher, state: FetcherState) {
        switch state {
        case .done(let mmd):
            DispatchQueue.main.async { modulePlayer.play(mmd: mmd) }
        case .failed:
            DispatchQueue.main.async { [weak self] in
                let action = CPAlertAction(title: "OK", style: .default, handler: { _ in })
                let alert = CPAlertTemplate(titleVariants: ["Download Failed"], actions: [action])
                self?.interfaceController?.presentTemplate(alert, animated: true, completion: nil)
            }
        default:
            break
        }
    }
}

// MARK: - ModulePlayerObserver

extension CarPlayController: ModulePlayerObserver {

    func statusChanged(status: PlayerStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch status {
            case .playing:
                guard let module = modulePlayer.currentModule else { return }
                self.setNowPlayingInfo(for: module, playbackRate: 1.0)
                self.showOrUpdateNowPlaying(module: module, isPlaying: true)
            case .paused:
                self.updatePlaybackRate(0.0)
                if let module = modulePlayer.currentModule {
                    self.nowPlayingTemplate?.updateSections(
                        self.makeNowPlayingSections(module: module, isPlaying: false)
                    )
                }
            default:
                break
            }
        }
    }

    func moduleChanged(module: MMD, previous: MMD?) {
        lastPlayedModules.removeAll { $0.id == module.id }
        lastPlayedModules.insert(module, at: 0)
        if lastPlayedModules.count > 20 {
            lastPlayedModules = Array(lastPlayedModules.prefix(20))
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.setNowPlayingInfo(for: module, playbackRate: 1.0)
            self.nowPlayingTemplate?.updateSections(
                self.makeNowPlayingSections(module: module, isPlaying: modulePlayer.status == .playing)
            )
        }
    }

    func errorOccurred(error: PlayerError) {}
    func queueChanged(changeType: QueueChange) {}
}
