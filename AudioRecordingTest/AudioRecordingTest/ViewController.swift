//
//  ViewController.swift
//  AudioRecordingTest
//
//  Created by 陈征征 on 2024/10/11.
//

import UIKit

class ViewController: UIViewController,AudioHelperDelegate {
    var helper : AudioHelper?
    @IBOutlet weak var btn_Record: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func click_recording(_ sender: Any) {
        if btn_Record.isSelected == false {
            helper = GetAudioHelper()
            helper?.startRecording(delegate: self)
        } else {
            helper?.stopRecording()
        }
        btn_Record.isSelected = !btn_Record.isSelected
    }
    func audioRecorderUpdate(duration: Int) {
        let second = duration%60
        let min = duration/60
        btn_Record.setTitle(String(format: "录制中 %d:%02d", min, second), for: .normal)
    }

    func audioRecorderFinish(data: Data?, duration: Double) {
        if let voiceData = data {
            btn_Record.setTitle("录制完成", for: .normal)
        } else {
            
            btn_Record.setTitle("录制失败", for: .normal)
            
        }
    }
}

