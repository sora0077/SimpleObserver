//
//  SimpleObserverTests.swift
//  SimpleObserverTests
//
//  Created by 林達也 on 2015/01/30.
//  Copyright (c) 2015年 林達也. All rights reserved.
//

import UIKit
import XCTest
//import SimpleObserver


let when = { sec in dispatch_time(DISPATCH_TIME_NOW, Int64(sec * Double(NSEC_PER_SEC))) }
extension XCTestCase {
    
    typealias DoneStatement = () -> Void
    func wait(till num: Int = 1, _ block: (() -> Void) -> (() -> Void)) {
        self.wait(till: num, message: "", timeout: 10, block)
        
    }
    func wait(till num: Int, message: String, timeout: NSTimeInterval, _ block: (() -> Void) -> (() -> Void)) {
        
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
        
        self.waitForExpectationsWithTimeout(timeout) { (error) -> Void in }
    }
}

class MockObserver: NSObject {
    
}

class Hoge: Equatable {
    var id: Int = 0
}
func == (lhs: Hoge, rhs: Hoge) -> Bool {
    return lhs.id == rhs.id
}

class NotEquatable {
    
    var val: Int = 0
    
    init(_ v: Int = 0) {
        self.val = v
    }
}




class SimpleObserverTests: XCTestCase {
    
    
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
            let hoge = Observing(false)
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
            let hoge = Observing(false)
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
            let hoge = Observing(false)
            
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
        let hoge = Observing(false)

        XCTAssertEqual(hoge.default_queue, dispatch_get_main_queue(), "")

        let queue = dispatch_queue_create("", nil)
        let fuga = Observing(false, queue: queue)

        XCTAssertEqual(fuga.default_queue, queue, "")
    }
    
    func test_Arrayを監視() {
        
        var cnt = 0
        let counter = { ++cnt }
        let hoge = Observing<NSArray>([1])
        
        wait { done in
            hoge.watch(self) { (e, _) in
                XCTAssertEqual([1], e.oldValue, "")
                XCTAssertEqual([2, 1], e.newValue, "")
                counter()
                done()
            }
            
            hoge <= [2, 1]
            
            return {
                XCTAssertEqual(1, cnt, "")
            }
        }
        
    }
    
    func test_Arrayに独自クラスを入れた場合() {
        
        var cnt = 0
        let counter = { ++cnt }
        let hoge = Observing<NSArray>([Hoge()])
        
        wait { done in
            
            hoge.watch(self) { (e, _) in
                XCTAssertEqual(0, (e.newValue[0] as Hoge).id, "")
                counter()
                done()
            }
            
            hoge <= [Hoge(), Hoge()]
            
            return {
                XCTAssertEqual(1, cnt, "")
            }
        }
        
    }
    
    func test_配列の中身が同じ場合呼び出されない() {
        
        var cnt = 0
        let counter = { ++cnt }
        let expected = Hoge()
        let hoge = Observing<NSArray>([expected])
        
        wait { done in
            
            hoge.watch(self) { (e, _) in
                XCTAssertEqual([expected], e.oldValue, "")
                counter()
            }
            hoge <= [expected]
            
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
            let hoge = Observing(false)
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
            let hoge = Observing(false)
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
    
    
    func test_Observableに包み込めば監視出来る() {
        wait { done in
            var cnt = 0
            let counter = { ++cnt }
            
            let hoge = Observing(Observable(NotEquatable()))
            
            hoge.watch(self) { (e, _) in
                counter()
                XCTAssertEqual(1, e.newValue.value.val, "")
                done()
            }
            
            hoge.value = Observable(NotEquatable(1))
            
            return {
                XCTAssertEqual(1, cnt, "")
            }
        }
    }
    
    
    func test_Observableに包み込んだオブジェクトが同一でも通知される() {
        wait { done in
            var cnt = 0
            let counter = { ++cnt }
            
            let expected = NotEquatable()
            let hoge = Observing(Observable(expected))
            
            hoge.watch(self) { (e, _) in
                counter()
                return
            }
            
            hoge.value = Observable(expected)
            done()
            
            return {
                XCTAssertEqual(1, cnt, "")
            }
        }
    }
}
