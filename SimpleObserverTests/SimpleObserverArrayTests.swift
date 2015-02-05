//
//  SimpleObserverArrayTests.swift
//  SimpleObserver
//
//  Created by 林達也 on 2015/02/02.
//  Copyright (c) 2015年 林達也. All rights reserved.
//

import UIKit
import XCTest

class SimpleObserverArrayTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    func test_Array() {
        
        wait { done in
            
            let hoge = ObservingArray([1])
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

            let hoge = ObservingArray([1])

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
    
    func test_Arrayを丸ごと入れ替えた場合() {
        
        wait { done in
            var cnt = 0
            let counter = { ++cnt }
            
            let hoge = ObservingArray([1])
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
            
            hoge.values = expected
            
            return {
                XCTAssertEqual(1, cnt, "")
            }
        }
        
    }
    
}
