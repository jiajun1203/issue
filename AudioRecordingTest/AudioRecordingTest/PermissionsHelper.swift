//
//  PermissionsHelper.swift
//  YiYuanFang
//
//  Created by Vic on 2022/4/11.
//

import Foundation
import AVFoundation
import Photos
import Contacts
import UIKit

typealias PermissionsBlock = (_ authorized: Bool) -> ()

class PermissionsHelper : NSObject {
    class func camera(complation:@escaping PermissionsBlock, alert: Bool) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
            if authStatus == .restricted || authStatus == .denied {
                print("相机权限被拒绝")
                complation(false)
                if alert {
                    let title = "无法使用相机"
                    let message = "请在iPhone的\"设置-隐私-相机\"中允许访问相机"
                    let ac = UIAlertController.show(style: .alert, title: title, message: message)
                    ac.addCancelAction(title: "取消", handler: nil)
                    ac.addAction(title: "设置") { action in
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    }
                }
            } else if authStatus == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    ThreadHelper.perform(main: { [self] in
                        camera(complation: complation, alert: alert)
                    })
                }
            } else {
                complation(true)
            }
        } else {
            print("该设备无法打开相机")
        }
    }
    
    class func microphone(complation:@escaping PermissionsBlock, alert: Bool) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if authStatus == .restricted || authStatus == .denied {
            print("麦克风权限被拒绝")
            complation(false)
            if alert {
                let title = "无法使用麦克风"
                let message = "请在iPhone的\"设置-隐私-相机\"中允许访问麦克风"
                let ac = UIAlertController.show(style: .alert,title: title, message: message)
                ac.addCancelAction(title: "取消", handler: nil)
                ac.addAction(title: "设置") { action in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }
            }
        } else if authStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                ThreadHelper.perform(main: { [self] in
                    microphone(complation: complation, alert: alert)
                })
            }
        } else {
            complation(true)
        }
    }
    
    class func photo(complation:@escaping PermissionsBlock, alert: Bool) {
        let authStatus = PHPhotoLibrary.authorizationStatus()
        if authStatus == .restricted || authStatus == .denied {
            print("相册权限被拒绝")
            complation(false)
            if alert {
                let title = "无法使用相册"
                let message = "请在iPhone的\"设置-隐私-相机\"中允许访问相册"
                let ac = UIAlertController.show(style: .alert,title: title, message: message)
                ac.addCancelAction(title: "取消", handler: nil)
                ac.addAction(title: "设置") { action in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }
            }
        } else if authStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization() { status in
                ThreadHelper.perform(main: { [self] in
                    microphone(complation: complation, alert: alert)
                })
            }
        } else {
            complation(true)
        }
    }
    
    class func contact(complation:@escaping PermissionsBlock, alert: Bool) {
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authStatus == .restricted || authStatus == .denied {
            print("通讯录权限被拒绝")
            complation(false)
            if alert {
                let title = "无法使用通讯录"
                let message = "请在iPhone的\"设置-隐私-相机\"中允许访问通讯录"
                let ac = UIAlertController.show(style: .alert,title: title, message: message)
                ac.addCancelAction(title: "取消", handler: nil)
                ac.addAction(title: "设置") { action in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                }
            }
        } else if authStatus == .notDetermined {
            CNContactStore().requestAccess(for: .contacts) { granted, error in
                ThreadHelper.perform(main: { [self] in
                    microphone(complation: complation, alert: alert)
                })
            }
        } else {
            complation(true)
        }
    }
}

extension UIAlertController {
    @discardableResult class func show(style: UIAlertController.Style, title: String?, message: String?, actions:[String] = [], actionColor: UIColor? = nil, handler:((Int, UIAlertAction) -> Void)? = nil, cancel: String,  cancelColor: UIColor? = nil, cancelHandler:((UIAlertAction) -> Void)? = nil)  -> UIAlertController {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: style)
        for (index, actionTitle) in actions.enumerated() {
            alert.addAction(title: actionTitle, titleColor: actionColor) { action in
                handler?(index, action)
            }
        }
        alert.addCancelAction(title: cancel, titleColor: cancelColor, handler: cancelHandler)
        GetCurrentVC()?.present(alert, animated: true, completion: nil)
        return alert
    }
    //MARK: 弹窗/选项
    class func show(style: UIAlertController.Style, title: String?, message: String?) -> UIAlertController {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: style)
        GetCurrentVC()?.present(alert, animated: true, completion: nil)
        return alert
    }
    //MARK: 普通按钮
    @discardableResult func addAction(title: String, titleColor: UIColor? = nil, handler: ((UIAlertAction) -> Void)? = nil) -> Self  {
        let action = UIAlertAction.init(title: title, style: .default, handler: handler)
        if let color = titleColor {
            action.setValue(color, forKey: "titleTextColor")
        }
        addAction(action)
        return self
    }
    //MARK: 强调按钮
    @discardableResult func addDestructiveAction(title: String, titleColor: UIColor? = nil, handler: ((UIAlertAction) -> Void)? = nil) -> Self {
        let action = UIAlertAction.init(title: title, style: .destructive, handler: handler)
        if let color = titleColor {
            action.setValue(color, forKey: "titleTextColor")
        }
        addAction(action)
        return self
    }
    //MARK: 取消按钮
    @discardableResult func addCancelAction(title: String, titleColor: UIColor? = nil, handler: ((UIAlertAction) -> Void)? = nil) -> Self {
        let action = UIAlertAction.init(title: title, style: .cancel, handler: handler)
        if let color = titleColor {
            action.setValue(color, forKey: "titleTextColor")
        }
        addAction(action)
        return self
    }
}
func GetCurrentVC() -> UIViewController? {
    return UIViewController.currentVC()
}
extension UIViewController {
    //MARK: 获取当前VC
    class func currentVC() -> UIViewController?{
        // 获取当先显示的window
        if let currentWindow = currentWindow() {
            return UIViewController.nextController(currentWindow.rootViewController)
        }
        return nil
    }
    class func currentWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    if windowScene.activationState == .foregroundActive ||
                        windowScene.activationState == .foregroundInactive {
                        for window in windowScene.windows {
                            if window.windowLevel == UIWindow.Level.normal {
                                return window
                            }
                        }
                    }
                }
            }
        } else {
            var currentWindow = UIApplication.shared.keyWindow ?? UIWindow()
            if currentWindow.windowLevel != UIWindow.Level.normal {
                let windowArr = UIApplication.shared.windows
                for window in windowArr {
                    if window.windowLevel == UIWindow.Level.normal {
                        currentWindow = window
                        break
                    }
                }
            }
            return currentWindow
        }
        return nil
    }
    private class func nextController(_ nextController: UIViewController?) -> UIViewController? {
        if nextController == nil {
            return nil
        }else if nextController?.presentedViewController != nil {
            return UIViewController.nextController(nextController?.presentedViewController)
        }else if let tabbar = nextController as? UITabBarController {
            return UIViewController.nextController(tabbar.selectedViewController)
        }else if let nav = nextController as? UINavigationController {
            return UIViewController.nextController(nav.visibleViewController)
        }
        return nextController
    }
}
