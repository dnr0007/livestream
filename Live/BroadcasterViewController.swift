//
//  BroadcasterViewController.swift
//  Live
//
//  Created by leo on 16/7/11.
//  Copyright © 2016年 io.ltebean. All rights reserved.
//

import UIKit
import SocketIO
import LFLiveKit
import IHKeyboardAvoiding
import SVProgressHUD

class BroadcasterViewController: UIViewController {
        
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var titleTextField: TextField!
    @IBOutlet weak var inputTitleOverlay: UIVisualEffectView!
    @IBOutlet weak var inputContainer: UIView!
    @IBOutlet weak var cameraBtn: DesignableButton!
    
    var socket : SocketIOClient?
    
    let manager = SocketManager(socketURL: URL(string: Config.serverUrl )!, config: [.log(true), .forcePolling(true)])

    lazy var session: LFLiveSession = {
        let audioConfiguration = LFLiveAudioConfiguration.default()
        let videoConfiguration = LFLiveVideoConfiguration.defaultConfiguration(for: .medium3)
        
        let session = LFLiveSession(audioConfiguration: audioConfiguration, videoConfiguration: videoConfiguration)!
        session.delegate = self
        session.captureDevicePosition = .front
        session.preView = self.previewView
        return session
    }()
    
    var room: Room!
    
    var overlayController: LiveOverlayViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.socket = manager.defaultSocket
            // Do any additional setup after loading the view, typically from a nib.
        KeyboardAvoiding.setAvoidingView(inputContainer, withTriggerView: inputContainer)
     //   IHKeyboardAvoiding.setAvoiding(inputContainer)
        cameraBtn.alpha = 0
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        session.running = true
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.running = false
        stop()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "overlay" {
            overlayController = segue.destination as! LiveOverlayViewController
            overlayController.socket = socket
        }
    }

    func start() {
        room = Room(dict: [
            "title": titleTextField.text! as AnyObject,
            "key": String.random() as AnyObject
        ])
        
        overlayController.room = room
        let stream = LFLiveStreamInfo()
        stream.url = "\(Config.rtmpPushUrl)deep"
       // stream.url = "\(Config.rtmpDemoUrl)\(room.key)"
        session.startLive(stream)

        socket?.connect()
        print("socket 1111111111111")
        socket?.once("connect") {[weak self] data, ack in
            guard let this = self else {
                return
            }
            this.socket?.emit("create_room", this.room.toDict())
        }
 
        print(room)
        infoLabel.text = "Room: \(room.key)"
        KeyboardAvoiding.setAvoidingView(overlayController.inputContainer, withTriggerView: overlayController.inputContainer)
     //   IHKeyboardAvoiding.setAvoiding(overlayController.inputContainer)
    }
    
    func stop() {
        guard room != nil else {
            return
        }
        session.stopLive()
        socket?.disconnect()
    }
    
    @IBAction func startButtonPressed(_ sender: AnyObject) {
        titleTextField.resignFirstResponder()
        start()
        UIView.animate(withDuration: 0.2, animations: {
            self.inputTitleOverlay.alpha = 0
            self.cameraBtn.alpha = 1.0
        }, completion: { finished in
            self.inputTitleOverlay.isHidden = true
        })
    }
    @IBAction func changeCameraPressed(_ sender: Any) {
        
        if session.captureDevicePosition != .back {
            session.captureDevicePosition = .back
            session.preView = self.previewView
        }else{
            session.captureDevicePosition = .front
           // session.preView = self.previewView
        }

    }
    
    @IBAction func closeButtonPressed(_ sender: AnyObject) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}

extension BroadcasterViewController: LFLiveSessionDelegate {
    
    func liveSession(_ session: LFLiveSession?, liveStateDidChange state: LFLiveState) {
        switch state {
        case .error:
            statusLabel.text = "error"
        case .pending:
            statusLabel.text = "pending"
        case .ready:
            statusLabel.text = "ready"
        case.start:
            statusLabel.text = "Live"
        case.stop:
            statusLabel.text = "stop"
        case .refresh:
            statusLabel.text = "refresh"

        }
    }
    
    func liveSession(_ session: LFLiveSession?, debugInfo: LFLiveDebug?) {
        
    }
    
    func liveSession(_ session: LFLiveSession?, errorCode: LFLiveSocketErrorCode) {
        print("error: \(errorCode)")
        
    }
}

