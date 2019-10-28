//
//  TVViewController.swift
//  Meruru
//
//  Created by subdiox on 2019/10/28.
//  Copyright © 2019 castaneai. All rights reserved.
//

import Cocoa
import VLCKit

class TVViewController: NSViewController {
    
    var mirakurun: MirakurunAPI!
    
    @IBOutlet var servicesPopUpButton: NSPopUpButton!
    @IBOutlet var videoView: VLCVideoView!
    @IBOutlet var statusTextField: NSTextField!
    
    var player: VLCMediaPlayer!
    var services: [Service] = []
    var currentService: Service?
    
    override func viewDidLoad() {
        servicesPopUpButton.removeAllItems()
        servicesPopUpButton.action = #selector(servicesPopUpButtonDidSelect)
        
        guard let mirakurunPath = AppConfig.shared.currentData?.mirakurunPath ?? promptMirakurunPath() else {
            showErrorAndQuit(error: NSError(domain: "invalid mirakurun path", code: 0))
            return
        }
        
        player = VLCMediaPlayer(videoView: videoView)
        
        mirakurun = MirakurunAPI(baseURL: URL(string: mirakurunPath + "/api")!)
        mirakurun.fetchStatus().then { status in
            AppConfig.shared.currentData?.mirakurunPath = mirakurunPath
            DispatchQueue.main.async {
                self.statusTextField.stringValue = "Mirakurun: v" + status.version
            }
            self.mirakurun.fetchServices().then { services in
                self.services = services
                DispatchQueue.main.async {
                    self.servicesPopUpButton.addItems(withTitles: services.map { $0.name })
                    self.servicesPopUpButton.selectItem(at: 0)
                }
            }.onError { error in
                self.showErrorAndQuit(error: error)
            }
        }.onError { error in
            debugPrint(error)
            self.showErrorAndQuit(error: NSError(domain: "failed to get Mirakurun's status (mirakurunPath: \(mirakurunPath))", code: 0))
        }
    }
    
    @objc func servicesPopUpButtonDidSelect(sender: NSPopUpButton) {
        let selectedService = services[sender.indexOfSelectedItem]
        debugPrint(selectedService)
        currentService = selectedService
        mirakurun.fetchPrograms(service: selectedService).then { programs in
            guard let program = self.getNowProgram(programs: programs) else {
                return
            }
            DispatchQueue.main.async {
                self.view.window?.title = "Meruru - \(program.name) - \(selectedService.name)"
            }
        }.onError { error in
            print(error)
        }
        player.stop()
        let media = VLCMedia(url: mirakurun.getStreamURL(service: selectedService))
        player.media = media
        player.play()
    }
    
    func showErrorAndQuit(error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
        NSApplication.shared.terminate(self)
    }
    
    func promptMirakurunPath() -> Optional<String> {
        let alert = NSAlert()
        alert.messageText = "Please input path of Mirakurun (e.g, http://192.168.x.x:40772)"
        alert.alertStyle = .informational
        let tf = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = tf
        alert.addButton(withTitle: "OK")
        let res = alert.runModal()
        if res == .alertFirstButtonReturn {
            return tf.stringValue
        }
        return nil
    }
    
    func getNowProgram(programs: [Program]) -> Program? {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return programs.first { $0.startAt...($0.startAt + $0.duration) ~= now }
    }
}
