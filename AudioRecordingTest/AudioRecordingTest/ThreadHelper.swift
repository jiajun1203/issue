//
//  ThreadHelper.swift
//  YiYuanFang
//
//  Created by Vic on 2022/3/24.
//

import Foundation

//MARK: - 线程根据工具
typealias ThreadBlock = () -> ()
typealias ThreadQueueBlock = (_ finish:@escaping () -> ()) -> ()
class ThreadHelper: NSObject {
    //MARK: 先执行子线程， 再执行主线程
    class func perform(background: ThreadBlock?, main: ThreadBlock?) {
        perform(background:background, main:main, UntileDone: false)
    }
    
    //MARK: 子线程和主线程，是否同时执行
    class func perform(background: ThreadBlock?, main: ThreadBlock?, UntileDone: Bool) {
        let concurrentQueue = DispatchQueue(label: "kit.core.threadhelper")
        let mainQueue = DispatchQueue.main
        
        let operation = background ?? {}
        let completion = main ?? {}
        
        if UntileDone {
            concurrentQueue.sync(execute: operation)
            if Thread.isMainThread {
                completion()
            } else {
                mainQueue.async(execute: {
                    completion()
                })
            }
        } else {
            concurrentQueue.async(execute: {
                operation()
                mainQueue.async(execute: {
                    completion()
                })
            })
        }
    }
    
    //MARK: 子线程
    class func perform(background: ThreadBlock?) {
        perform(background: background, main: nil)
    }
    
    //MARK: 主线程
    class func perform(main: ThreadBlock?) {
        DispatchQueue.main.async {
            main?()
        }
    }
    
    //MARK: 延迟执行
    class func perform(main: ThreadBlock?, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            main?()
        }
    }
    
    //MARK: 线程队列
    let workingGroup = DispatchGroup()
    let workingQueue = DispatchQueue(label: "request_queue")
    var queueBlocks: [ThreadQueueBlock] = []
    func addQueue(main:@escaping ThreadQueueBlock) {
        queueBlocks.append(main)
    }
    
    func done(handle:@escaping ThreadBlock) {
        if queueBlocks.count == 0 {
            handle()
        } else {
            for block in queueBlocks {
                workingGroup.enter()
                block({ [self] in
                    workingGroup.leave()
                })
            }
            workingGroup.notify(queue: .main, execute: { [self] in
                handle()
                queueBlocks.removeAll()
            })
        }
    }
}
