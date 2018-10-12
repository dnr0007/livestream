//
//  LiveOverlayViewController.swift
//  Live
//
//  Created by leo on 16/7/12.
//  Copyright © 2016年 io.ltebean. All rights reserved.
//

import UIKit
import SocketIO
import IHKeyboardAvoiding
import ReplayKit
class LiveOverlayViewController: UIViewController {
    
    @IBOutlet weak var emitterView: WaveEmitterView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var inputContainer: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var giftArea: GiftDisplayArea!
    @IBOutlet weak var recordBtn: UIButton!
    
    let recorder = RPScreenRecorder.shared()
    private var isRecording = false
    
    var comments: [Comment] = []

    var room: Room!
    
    var socket: SocketIOClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
      
        textField.delegate = self
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 30
        tableView.rowHeight = UITableViewAutomaticDimension

        
        
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(LiveOverlayViewController.tick(_:)), userInfo: nil, repeats: true)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(LiveOverlayViewController.handleTap(_:)))
        view.addGestureRecognizer(tap)
        
        recordBtn.addTarget(self, action: #selector(startRecording), for: .touchUpInside)


        KeyboardAvoiding.setAvoidingView(inputContainer, withTriggerView: inputContainer)
        
     //   IHKeyboardAvoiding.setAvoiding(inputContainer)
/*
        socket.on("upvote") {[weak self] data ,ack in
            self?.emitterView.emitImage(R.image.heart()!)
        }
        
        socket.on("comment") {[weak self] data ,ack in
            let comment = Comment(dict: data[0] as! [String: AnyObject])
            self?.comments.append(comment)
            self?.tableView.reloadData()
        }
        
        socket.on("gift") {[weak self] data ,ack in
            let event = GiftEvent(dict: data[0] as! [String: AnyObject])
            self?.giftArea.pushGiftEvent(event)
        }
 */
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.contentInset.top = tableView.bounds.height
        tableView.reloadData()
    }
    
    func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        textField.resignFirstResponder()
    }
    
    func tick(_ timer: Timer) {
        guard comments.count > 0 else {
            return
        }
        if tableView.contentSize.height > tableView.bounds.height {
            tableView.contentInset.top = 0
        }
        tableView.scrollToRow(at: IndexPath(row: comments.count - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
    }
    func startRecording(sender: UIButton!) {
        self.recordBtn.setImage(UIImage.init(named: "cam_red"), for: .normal)

        print("1")
        guard recorder.isAvailable else {
            print("Recording is not available at this time.")
            return
        }
      
        if #available(iOS 10.0, *) {
            recorder.startRecording{ [unowned self] (error) in
                
                guard error == nil else {
                    print("There was an error starting the recording.")
                    return
                }
                
                print("Started Recording Successfully")
                self.recordBtn.removeTarget(self, action: #selector(self.startRecording), for: .touchUpInside)
                self.recordBtn.addTarget(self, action: #selector(self.stopRecording), for: .touchUpInside)

                self.recorder.isMicrophoneEnabled = true
                self.isRecording = true
            }
        } else {
            // Fallback on earlier versions
        }
        
    }
    func stopRecording(sender: UIButton) {
        print("Stop press")
        RPScreenRecorder.shared().stopRecording { (previewController, error) in
            
                if previewController != nil {
                    self.isRecording = false

                    let alertController = UIAlertController(title: "Recording", message: "Do you wish to discard or view your gameplay recording?", preferredStyle: .alert)
                    
                    let discardAction = UIAlertAction(title: "Discard", style: .default) { (action: UIAlertAction) in
                        RPScreenRecorder.shared().discardRecording(handler: { () -> Void in
                            // Executed once recording has successfully been discarded
                        })
                    }
                    
                    let viewAction = UIAlertAction(title: "View", style: .default, handler: { (action: UIAlertAction) -> Void in
                        self.present(previewController!, animated: true, completion: nil)
                    })
                    
                    alertController.addAction(discardAction)
                    alertController.addAction(viewAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                    
                   // self.recordBtn.backgroundColor = UIColor.clear
                    self.recordBtn.setImage(UIImage.init(named: "cam_white"), for: .normal)
                    


                    
                    self.recordBtn.removeTarget(self, action: #selector(self.stopRecording), for: .touchUpInside)
                    self.recordBtn.addTarget(self, action: #selector(self.startRecording), for: .touchUpInside)
                    
                } else {
                    // Handle error
                }
            }
        
    
    }
    
    @IBAction func giftButtonPressed(_ sender: AnyObject) {
        let vc = R.storyboard.main.giftChooser()!
      //3  vc.socket = socket
      //4  vc.room = room
        vc.modalPresentationStyle = .custom
        present(vc, animated: true, completion: nil)
        
    }
    
    @IBAction func recordButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func upvoteButtonPressed(_ sender: AnyObject) {
       //1 socket.emit("upvote", room.key)
    }
}

extension LiveOverlayViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            textField.resignFirstResponder()
            if let text = textField.text , text != "" {
         /*2       socket.emit("comment", [
                    "roomKey": room.key,
                    "text": text
                ])
                 
 */
                let cmnt = Comment(dict: [
                    "roomKey": room.key as AnyObject,
                    "text": text as AnyObject
                    ])
                comments.append(cmnt)
                tableView.reloadData()
                
            }
            
            textField.text = ""
            return false
        }
        return true
    }
}

extension LiveOverlayViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CommentCell
        cell.comment = comments[(indexPath as NSIndexPath).row]

        return cell
    }
    
}


class CommentCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var commentContainer: UIView!
    
    var comment: Comment! {
        didSet {
            updateUI()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commentContainer.layer.cornerRadius = 3
    }
    
    func updateUI() {
       // let abc = "ahjada ajdbd ajdbad jad"
        titleLabel.attributedText = comment.text.attributedComment()
     //   titleLabel.attributedText = abc.attributedComment()

    }
    
}
