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

    // MARK: - Private helpers

    private func updateNowPlayingInfo(for module: MMD, playbackRate: Double) {
        let artwork = MPMediaItemArtwork(boundsSize: CGSize(width: 300, height: 300)) { _ in
            UIImage(named: "albumart") ?? UIImage()
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: module.name,
            MPMediaItemPropertyArtist: module.composer ?? "",
            MPMediaItemPropertyArtwork: artwork,
            MPNowPlayingInfoPropertyPlaybackRate: playbackRate,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: modulePlayer.renderer.currentPosition(),
            MPMediaItemPropertyPlaybackDuration: modulePlayer.renderer.moduleLength()
        ]
    }

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
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Last played", sections: [section])
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
            modulePlayer.play(mmd: mmd)
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
        switch status {
        case .playing:
            if let module = modulePlayer.currentModule {
                updateNowPlayingInfo(for: module, playbackRate: 1.0)
            }
            DispatchQueue.main.async { [weak self] in
                guard let controller = self?.interfaceController else { return }
                guard !(controller.topTemplate is CPNowPlayingTemplate) else { return }
                controller.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
            }
        case .paused:
            if let module = modulePlayer.currentModule {
                updateNowPlayingInfo(for: module, playbackRate: 0.0)
            }
        default:
            break
        }
    }

    /// Tracks every module that starts playing, newest first, capped at 20.
    func moduleChanged(module: MMD, previous: MMD?) {
        lastPlayedModules.removeAll { $0.id == module.id }
        lastPlayedModules.insert(module, at: 0)
        if lastPlayedModules.count > 20 {
            lastPlayedModules = Array(lastPlayedModules.prefix(20))
        }
        updateNowPlayingInfo(for: module, playbackRate: 1.0)
    }

    func errorOccurred(error: PlayerError) {}
    func queueChanged(changeType: QueueChange) {}
}
