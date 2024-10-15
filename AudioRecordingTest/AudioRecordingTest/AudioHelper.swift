//
//  AudioHelper.swift
//
//
//  Created by test on 2022/3/24.
//

import Foundation
import AVFoundation

//MARK: - 音频工具
@discardableResult func GetAudioHelper() -> AudioHelper {
    return AudioHelper.helper
}
//MARK: 音频工具类代理
@objc protocol AudioHelperDelegate {
    //MARK: 录音
    @objc optional func audioRecorderFinish(data: Data?, duration: Double)
    @objc optional func audioRecorderUpdate(volumeMeters: CGFloat)
    @objc optional func audioRecorderUpdate(duration: Int)
    //MARK: 播放
    @objc optional func audioPlayEnd(error: Bool, tag: Int)
    @objc optional func audioPlayUpdate(duration: Int)
}

//MARK: 音频工具类
class AudioHelper: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    fileprivate weak var delegate: AudioHelperDelegate?
    deinit {
        recorderTimer?.invalidate()
        recorderTimer = nil
        playerTimer?.invalidate()
        playerTimer = nil
    }
    typealias GetAudioData = (_ data:Data)->Void;

    //MARK: 播放
    private var player: AVAudioPlayer?
    private var nowTag: Int = NSNotFound
    //MARK: 播放调用
    func startPlay(file: String, delegate newDelegate: AudioHelperDelegate?, tag: Int = 0, stopWhenPlayed: Bool = false, getData: GetAudioData? = nil, speaker: Bool = true) {
        if notStop(tag: tag, stopWhenPlayed: stopWhenPlayed) {
            if file.hasPrefix("http") {
                do {
                    if let url = URL(string: file) {
                        let data = try Data(contentsOf: url)
                        getData?(data)
                        startPlay(data: data, delegate: delegate, tag: tag, stopWhenPlayed: stopWhenPlayed)
                    } else {
                        print("网路音频地址错误")
                        delegate?.audioPlayEnd?(error: true, tag: tag)
                    }
                } catch {
                    print("获取网路音频数据失败")
                    delegate?.audioPlayEnd?(error: true, tag: tag)
                }
            } else {
                var path = file
                if path.hasPrefix("file://") {
                    let offset = "file://".count
                    path = String(path[path.index(path.startIndex, offsetBy: offset)..<path.endIndex])
                }
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                    getData?(data)
                    startPlay(data: data, delegate: delegate, tag: tag, stopWhenPlayed: stopWhenPlayed, speaker: speaker)
                } catch {
                    print("获取音频数据失败")
                    delegate?.audioPlayEnd?(error: true, tag: tag)
                }
            }
        }
    }
    
    func startPlay(data: Data, delegate newDelegate: AudioHelperDelegate?, tag: Int = 0, stopWhenPlayed: Bool = false, speaker: Bool = true) {
        if notStop(tag: tag, stopWhenPlayed: stopWhenPlayed) {
            stopPlayAudio()
            stopRecording()
            do {
                if speaker {
                    try? AVAudioSession.sharedInstance().setCategory(.playback)
                } else {
                    try? AVAudioSession.sharedInstance().setCategory(.playAndRecord)
                }
                player = try AVAudioPlayer(data: data)
                player?.delegate = self
            } catch {
                print("初始化播放器失败")
                delegate?.audioPlayEnd?(error: true, tag: tag)
            }
            player?.prepareToPlay()
            if player?.play() != true {
                print("播放器播放失败")
                delegate?.audioPlayEnd?(error: true, tag: tag)
            } else {
                delegate = newDelegate
                nowTag = tag
                createPlayerTimer()
            }
        }
    }
    
    private func notStop(tag: Int, stopWhenPlayed stop: Bool) -> Bool {
        if stop && tag == nowTag && tag != NSNotFound && player?.isPlaying == true {
            stopPlayAudio()
            return false
        } else {
            return true
        }
    }
    
    func stopPlayAudio() {
        if player?.isPlaying == true {
            player?.stop()
            print("音频提前结束")
            delegate?.audioPlayEnd?(error: false, tag: nowTag)
        }
        nowTag = NSNotFound
        player = nil
        playerTimer?.invalidate()
        playerTimer = nil
    }
    
    func stopPlayingAudio(tag: Int) {
        if tag == nowTag && player?.isPlaying == true {
            stopPlayAudio()
        }
    }
    
    //MARK: 播放代理
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            print("音频播放结束")
        } else {
            print("音频播放错误")
        }
        delegate?.audioPlayEnd?(error: flag, tag: nowTag)
        nowTag = NSNotFound
        playerTimer?.invalidate()
        playerTimer = nil
    }
    
    //MARK: 计时
    private var playerTimer: Timer?
    private var playTime: Int = 0
    private func createPlayerTimer() {
        playTime = 0
        lastTime = -1
//        playerTimer = Timer(timeInterval: 1, target: YYWeakProxy(target: self), selector: #selector(playTimewait), userInfo: nil, repeats: true)
//        RunLoop.current.add(playerTimer!, forMode: .default)
        playerTimer?.fire()
    }
    
    @objc private func playTimewait() {
        playTime += 1
        print("音频播放中", playTime, "秒")
        delegate?.audioPlayUpdate?(duration: playTime)
    }
    
    //MARK: 录音
    private var recorderTimer: Timer?
    private var filePath = ""
    private lazy var recorder: AVAudioRecorder? = {
        var settings: [String : Any] = [:]
        settings[AVSampleRateKey] = NSNumber(value: 16000)
        settings[AVFormatIDKey] = NSNumber(value: kAudioFormatLinearPCM)
        settings[AVLinearPCMBitDepthKey] = NSNumber(value: 16)
        settings[AVNumberOfChannelsKey] = NSNumber(value: 2)
        settings[AVLinearPCMIsBigEndianKey] = NSNumber(value: false)
        settings[AVLinearPCMIsFloatKey] = NSNumber(value: false)

        configFile()
        
        let audioRecorder = try? AVAudioRecorder(url: URL(fileURLWithPath: filePath), settings: settings)
        audioRecorder?.prepareToRecord()
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        return audioRecorder
    }()
    
    //MARK: 录音调用
    var maxTime: Int = 0 //录制时间上限秒，0为无上限
    var converToMp3: Bool = true
    func startRecording(delegate newDelegate: AudioHelperDelegate?) {
        PermissionsHelper.microphone(complation: { [self] authorized in
            if authorized {
                stopPlayAudio()
                stopRecording()
                delegate = newDelegate
                try? AVAudioSession.sharedInstance().setCategory(.record)
                try? AVAudioSession.sharedInstance().setActive(true)
                recorder?.record()
                createRecorderTimer()
            } else {
                delegate?.audioRecorderFinish?(data: nil, duration: 0)
            }
        }, alert: true)
    }

    func stopRecording() {
        if recorder?.isRecording == true {
            recorder?.stop()
        }
        recorderTimer?.invalidate()
        recorderTimer = nil
    }
    
    func cancelRecording() {
        delegate = nil
        stopRecording()
    }
    
    //MARK: 计时
    private var timing: Float = 0
    private var lastTime: Int = -1
    private func createRecorderTimer() {
        timing = 0
        lastTime = -1
        recorderTimer = Timer(timeInterval: 0.1, target: self, selector: #selector(recorderTimewait), userInfo: nil, repeats: true)
        RunLoop.current.add(recorderTimer!, forMode: .default)
        recorderTimer?.fire()
    }
    
    @objc private func recorderTimewait() {
        if recorder?.isRecording == true {
            recorder?.updateMeters()
            var value: CGFloat = pow(10, 0.05*CGFloat(recorder?.peakPower(forChannel: 0) ?? 0))
            value = min(max(value, 0), 1)
            delegate?.audioRecorderUpdate?(volumeMeters: value)
            timing += 0.1
            let time = Int(timing)
            if time != lastTime {
                lastTime = time
                print("录制音频中", lastTime, "秒")
                delegate?.audioRecorderUpdate?(duration: lastTime)
                if maxTime > 0 && lastTime >= maxTime { //超过设置的最大时间，自动结束录制
                    stopRecording()
                }
            }
        } else {
            print("音频未在录制中")
        }
    }
    
    //MARK: 录音代理
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let audioAsset = AVURLAsset(url: URL(fileURLWithPath: filePath))
        let duration = CMTimeGetSeconds(audioAsset.duration)
        if flag {
            var data: Data?
            var path = filePath
            if converToMp3 {
//                path = LameTool.audio(toMP3: filePath, isDeleteSourchFile: false)
            }
            print("录音完成，路径", path, "文件大小为", fileSize(), "时长", duration, "秒")
            data = try? Data(contentsOf: URL(fileURLWithPath: path))
            delegate?.audioRecorderFinish?(data: data, duration: duration)
        } else {
            delegate?.audioRecorderFinish?(data: nil, duration: 0)
        }
        recorderTimer?.invalidate()
        recorderTimer = nil
    }
    
    //MARK: 文件管理
    private func configFile() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String + "/Recording/"
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) == false {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("创建文件夹失败！")
            }
            print("创建文件夹成功，文件路径\(path)")
        }
        filePath = path + "recordeAudio.wav"
    }
    
    private func fileSize() -> String {
        var size: Double = 0
        let manager = FileManager.default
        if manager.fileExists(atPath: filePath) {
            do {
                size = try manager.attributesOfItem(atPath: filePath)[FileAttributeKey.size] as! Double
            } catch {
            }
            if size >= pow(1024, 3) {
                // size >= 1GB
                return "\(size / pow(1024, 3))GB"
            } else if size >= pow(1024, 2) {
                // 1GB > size >= 1MB
                return "\(size / pow(1024, 2))KB"
            } else if size >= 1024 {
                // 1MB > size >= 1KB
                return "\(size / 1024)KB"
            } else {
                // 1KB > size
                return "\(size)"
            }
        }
        return "\(size)"
    }
    
    //MARK: 单例
    fileprivate static let helper = AudioHelper()
    private override init() {}
    override func copy() -> Any { return self }
    override func mutableCopy() -> Any { return self }
    func reset() {}
}
