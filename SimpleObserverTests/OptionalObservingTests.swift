//
//  OptionalObservingTests.swift
//  SimpleObserver
//
//  Created by 林達也 on 2015/02/11.
//  Copyright (c) 2015年 spika.co.jp. All rights reserved.
//

import UIKit
import XCTest
@testable import SimpleObserver

class OptionalObservingTests: XCTestCase {

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
            let hoge = OptionalObserving(false, ==)
            let counter = { ++cnt }
            
            hoge.watch(self) { (e, _) in
                XCTAssertTrue(e.newValue!, "")
                XCTAssertFalse(e.oldValue!, "")
                XCTAssertEqual(1, counter(), "")
                
                done()
            }
            
            hoge.value = true
            
            return {
                XCTAssertEqual(1, cnt, "")
            }
        }
    }
    
    func test_基本的な動作_nil() {
        // This is an example of a functional test case.
        
        wait { done in
            var cnt = 0
            let hoge = OptionalObserving(false, ==)
            let counter = { ++cnt }
            
            hoge.watch(self) { (e, _) in
                XCTAssertNil(e.newValue, "")
                XCTAssertFalse(e.oldValue!, "")
                XCTAssertEqual(1, counter(), "")
                
                done()
            }
            
            hoge.value = nil
            
            return {
                XCTAssertEqual(1, cnt, "")
            }
        }
    }
    
    func test_基本的な動作_nilその２() {
        // This is an example of a functional test case.
        
        wait { done in
            var cnt = 0
            let hoge = OptionalObserving<Bool>(nil, ==)
            let counter = { ++cnt }
            
            hoge.watch(self) { (e, _) in
                XCTAssertFalse(true, "")
                XCTAssertEqual(1, counter(), "")
                
                done()
            }
            
            dispatch_after(when(0.5), dispatch_get_main_queue()) {
                done()
            }
            
            hoge.value = nil
            
            return {
                XCTAssertEqual(0, cnt, "")
            }
        }
    }

}
