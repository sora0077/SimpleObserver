//
//  ObservingTests.swift
//  SimpleObserver
//
//  Created by 林達也 on 2015/02/11.
//  Copyright (c) 2015年 spika.co.jp. All rights reserved.
//

import UIKit
import XCTest
@testable import SimpleObserver

let when = { sec in dispatch_time(DISPATCH_TIME_NOW, Int64(sec * Double(NSEC_PER_SEC))) }
extension XCTestCase {
    
    typealias DoneStatement = () -> Void
    func wait(till num: Int = 1, message: String = __FUNCTION__, _ block: (() -> Void) -> (() -> Void)) {
        self.wait(till: num, message: message, timeout: 1, block)
        
    }
    func wait(till num: Int, message: String = __FUNCTION__, timeout: NSTimeInterval, _ block: (() -> Void) -> (() -> Void)) {
        
        let expectation = self.expectationWithDescription(message)
        let queue = dispatch_queue_create("XCTestCase.wait", nil)
        var living = num
        
        var completion: (() -> Void)!
        let done: DoneStatement = {
            dispatch_async(queue) { //シングルキューで必ず順番に処理する
                living--
                if living == 0 {
                    completion?()
                    expectation.fulfill()
                }
            }
        }
        
        completion = block(done)
        
        self.waitForExpectationsWithTimeout(timeout) { (error) -> Void in
            completion?()
            return
        }
    }
}

class MockObserver: NSObject {
    
}

class Hoge {
    var id: Int = 0
}

class ObservingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func test_基本的な動作() {
        // This is an example of a functional test case.
        
        wait { done in
            var cnt = 0
            let hoge = Observing(false, ==)
            let counter = { ++cnt }
            
            hoge.watch(self) { (e, _) in
                XCTAssertTrue(e.newValue, "")
                XCTAssertFalse(e.oldValue, "")
                XCTAssertEqual(1, counter(), "")
                
                done()
            }
            
            hoge.value = true
            
            return {
                XCTAssertEqual(1, cnt, "")
            }
        }
        
    }
    
    func test_基本的な動作_それぞれの呼び出し順序() {
        
        wait { done in
            var cnt = 0
            let hoge = Observing(false, ==)
            let counter = { ++cnt }
            
            hoge.watch(self) { e in
                XCTAssertEqual(2, counter(), "")
                done()
            }
            
            hoge.value = true
            XCTAssertEqual(1, counter(), "")
            
            return {
                
                XCTAssertEqual(2, cnt, "")
            }
        }
    }
    
    func test_基本的な動作_複数での監視() {
        
        wait(till: 2) { done in
            var cnt = 0
            let counter = { ++cnt }
            let hoge = Observing(false, ==)
            
            hoge.watch(self) { (e, _) in
                XCTAssertTrue(e.newValue, "")
                XCTAssertFalse(e.oldValue, "")
                
                XCTAssertEqual(2, counter(), "")
                done()
            }
            hoge.watch(self) { (e, _) in
                XCTAssertTrue(e.newValue, "")
                XCTAssertFalse(e.oldValue, "")
                
                XCTAssertEqual(1, counter(), "")
                
                done()
            }
            
            hoge.value = true
            
            return {
                
                XCTAssertEqual(2, cnt, "")
            }
        }
    }
    
    func test_デフォルトキューの設定() {
        let hoge = Observing(false, ==)
        
        XCTAssertTrue(hoge.default_queue === dispatch_get_main_queue(), "")
        
        let queue = dispatch_queue_create("", nil)
        let fuga = Observing(false, ==, queue: queue)
        
        XCTAssertTrue(fuga.default_queue === queue, "")
    }
    
    func test_unwatchされたら通知されない() {
        
        var cnt = 0
        let counter = { ++cnt }
        let hoge = Observing(false, ==)
        wait { done in
            
            hoge.watch(self) { _ in
                counter()
                done()
            }
            
            dispatch_after(when(0.5), dispatch_get_main_queue()) {
                done()
            }
            
            hoge.unwatch(self)
            
            hoge.value = true
            
            return {
                XCTAssertEqual(0, cnt, "")
            }
        }
    }
    
    
    func test_Arrayを監視() {
        
        var cnt = 0
        let counter = { ++cnt }
        let hoge = Observing<NSArray>([1], ==)
        
        wait { done in
            hoge.watch(self) { (e, _) in
                XCTAssertEqual([1], e.oldValue, "")
                XCTAssertEqual([2, 1], e.newValue, "")
                counter()
                done()
            }
            
            hoge.value = [2, 1]
            
            return {
                XCTAssertEqual(1, cnt, "")
            }
        }
        
    }
    
    func test_Arrayに独自クラスを入れた場合() {
        
        var cnt = 0
        let counter = { ++cnt }
        let hoge = Observing<NSArray>([Hoge()], ==)
        
        wait { done in
            
            hoge.watch(self) { (e, _) in
                XCTAssertEqual(0, (e.newValue[0] as! Hoge).id, "")
                counter()
                done()
            }
            
            hoge.value = [Hoge(), Hoge()]
            
            return {
                XCTAssertEqual(1, cnt, "")
            }
        }
        
    }
    
    func test_配列の中身が同じ場合呼び出されない() {
        
        var cnt = 0
        let counter = { ++cnt }
        let expected = Hoge()
        let hoge = Observing<NSArray>([expected], ==)
        
        wait { done in
            
            hoge.watch(self) { (e, _) in
                XCTAssertEqual([expected], e.oldValue, "")
                counter()
            }
            hoge.value = [expected]
            
            done()
            
            return {
                XCTAssertEqual(0, cnt, "")
            }
        }
        
    }
    
    func test_基本的な動作_変更を複数回行う() {
        
        wait(till: 2) { done in
            
            var cnt = 0
            let counter = { ++cnt }
            let hoge = Observing(false, ==)
            var expected: Bool = true
            
            var call_1st = false
            var call_2nd = false
            
            let queue = dispatch_queue_create("", nil)
            
            hoge.watch(self, queue) { (e, _) in
                
                switch counter() {
                case 1:
                    XCTAssertEqual(true, e.newValue, "")
                    XCTAssertEqual(false, e.oldValue, "")
                    call_1st = true
                    done()
                case 2:
                    XCTAssertEqual(false, e.newValue, "")
                    XCTAssertEqual(true, e.oldValue, "")
                    call_2nd = true
                    done()
                default:
                    break
                }
            }
            
            hoge.value = expected
            expected = !expected
            
            hoge.value = expected
            expected = !expected
            
            return {
                XCTAssertEqual(false, hoge.value, "")
                XCTAssertEqual(2, cnt, "")
                
                XCTAssertTrue(call_1st, "")
                XCTAssertTrue(call_2nd, "")
            }
        }
    }
    
    func test_正常な呼び出し回数_監視対象のオブジェクトがクリアされた時は呼び出されない() {
        
        wait { done in
            var cnt = 0
            let hoge = Observing(false, ==)
            let counter = { ++cnt }
            
            autoreleasepool {
                
                let mock = MockObserver()
                
                hoge.watch(mock) { (e, o) in
                    XCTAssertNotNil(o.description, "")
                    XCTAssertFalse(true, "")
                    counter()
                }
                hoge.watch(mock) { _ in
                    XCTAssertFalse(true, "")
                    counter()
                }
            }
            
            hoge.watch(self) { vv in
                XCTAssertEqual(1, counter(), "")
                done()
            }
            
            XCTAssertEqual(3, hoge.observers.count, "")
            
            hoge.value = true
            
            XCTAssertEqual(0, cnt, "インクリメント前")
            XCTAssertEqual(1, hoge.observers.count, "")
            
            return {
                XCTAssertEqual(1, cnt, "cntは一回のみ")
            }
        }
    }
    
}
