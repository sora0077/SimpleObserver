//
//  ObservingArrayTests.swift
//  SimpleObserver
//
//  Created by 林達也 on 2015/02/12.
//  Copyright (c) 2015年 spika.co.jp. All rights reserved.
//

import UIKit
import XCTest

class ObservingArrayTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    
    func test_Array() {
        
        wait { done in
            
            let hoge = ObservingArray([1], ==)
            let expected = 2
            
            hoge.watch(self) { (e, _) in
                XCTAssertEqual(1, e.oldValue.count, "")
                XCTAssertEqual(2, e.newValue.count, "")
                switch e.change {
                case let .Insertion(box, idx):
                    XCTAssertEqual(expected, box.unbox, "")
                    done()
                default:
                    XCTAssertFalse(true, "error")
                }
            }
            
            hoge.append(expected)
            
            return {}
        }
        
    }
    
    func test_Replace() {
        
        wait { done in
            var cnt = 0
            let counter = { ++cnt }
            
            let hoge = ObservingArray([1], ==)
            
            hoge.watch(self) { (e, _) in
                switch e.change {
                case let .Replacement(box, idx):
                    XCTAssertEqual(box.unbox, 2, "")
                    counter()
                    done()
                default:
                    XCTAssertFalse(true, "error \(e.change)")
                }
            }
            
            hoge[0] = 2
            
            return {
                
                XCTAssertEqual(1, cnt, "")
            }
        }
    }
    
    func test_Replace_同じ値は呼ばれない() {
        
        wait { done in
            var cnt = 0
            let counter = { ++cnt }
            
            let hoge = ObservingArray([1], ==)
            
            hoge.watch(self) { (e, _) in
                switch e.change {
                case let .Replacement(box, idx):
                    XCTAssertEqual(box.unbox, 2, "")
                    counter()
                    done()
                default:
                    XCTAssertFalse(true, "error \(e.change)")
                }
            }
            
            dispatch_after(when(0.1), dispatch_get_main_queue()) {
                done()
            }
            
            hoge[0] = 1
            
            return {
                
                XCTAssertEqual(0, cnt, "")
            }
        }
    }
    
    func test_Arrayを丸ごと入れ替えた場合() {
        
        wait { done in
            var cnt = 0
            let counter = { ++cnt }
            
            let hoge = ObservingArray([1], ==)
            let expected = [2]
            
            hoge.watch(self) { (e, _) in
                counter()
                XCTAssertEqual(1, e.oldValue.count, "")
                XCTAssertEqual(expected.count, e.newValue.count, "")
                switch e.change {
                case .Setting:
                    XCTAssertEqual(expected, e.newValue, "")
                    done()
                default:
                    XCTAssertFalse(true, "error")
                }
            }
            
            hoge.value = expected
            
            return {
                XCTAssertEqual(1, cnt, "")
            }
        }
        
    }
    
    func test_unwatchされたら通知されない() {
        
        var cnt = 0
        let counter = { ++cnt }
        let hoge = ObservingArray([1], ==)
        let expected = [2]
        wait { done in
            
            hoge.watch(self) { _ in
                counter()
                done()
            }
            
            dispatch_after(when(0.1), dispatch_get_main_queue()) {
                done()
            }
            
            hoge.unwatch(self)
            
            hoge.value = expected
            
            return {
                XCTAssertEqual(0, cnt, "")
            }
        }
    }
}
