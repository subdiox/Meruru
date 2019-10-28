//
//  TVViewController.swift
//  Meruru
//
//  Created by subdiox on 2019/10/28.
//  Copyright © 2019 castaneai. All rights reserved.
//

import Cocoa
import VLCKit

class TVViewController: NSViewController, NSComboBoxDelegate {
    
    var mirakurun: MirakurunAPI!
    
    var statusTextField: NSTextField!
    var servicesComboBox: NSComboBox!
    
    var player: VLCMediaPlayer!
    var services: [Service] = []
    var currentService: Service?
    
    override func viewDidLoad() {
        statusTextField = NSTextField(frame: NSRect(x: 250, y: 0, width: 200, height: 24))
        statusTextField.drawsBackground = false
        statusTextField.isBordered = false
        statusTextField.isEditable = false
        statusTextField.stringValue = "Mirakurun: connecting..."
        view.addSubview(statusTextField)
        
        servicesComboBox = NSComboBox(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        servicesComboBox.delegate = self
        view.addSubview(servicesComboBox)
        
        let videoView = VLCVideoView(frame: NSRect(x: 0, y: 24, width: view.frame.width, height: view.frame.height - 24))
        videoView.autoresizingMask = [.width, .height]
        videoView.fillScreen = true
        videoView.backColor = NSColor.red
        view.addSubview(videoView)
        
        player = VLCMediaPlayer(videoView: videoView)
        
        guard let mirakurunPath = AppConfig.shared.currentData?.mirakurunPath ?? promptMirakurunPath() else {
            showErrorAndQuit(error: NSError(domain: "invalid mirakurun path", code: 0))
            return
        }

        mirakurun = MirakurunAPI(baseURL: URL(string: mirakurunPath + "/api")!)
        mirakurun.fetchStatus().then { status in
            AppConfig.shared.currentData?.mirakurunPath = mirakurunPath
            DispatchQueue.main.async {
                self.statusTextField.stringValue = "Mirakurun: v" + status.version
            }
            self.mirakurun.fetchServices().then { services in
                self.services = services
                DispatchQueue.main.async {
                    self.servicesComboBox.addItems(withObjectValues: services.map { $0.name })
                    self.servicesComboBox.selectItem(at: 0)
                }
            }.onError { error in
                self.showErrorAndQuit(error: error)
            }
        }.onError { error in
            debugPrint(error)
            self.showErrorAndQuit(error: NSError(domain: "failed to get Mirakurun's status (mirakurunPath: \(mirakurunPath))", code: 0))
        }
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
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let selectedService = services[servicesComboBox.indexOfSelectedItem]
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
    
    func getNowProgram(programs: [Program]) -> Program? {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return programs.first { $0.startAt...($0.startAt + $0.duration) ~= now }
    }
}
