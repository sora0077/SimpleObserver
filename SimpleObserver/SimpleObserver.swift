//
//  SimpleObserver.swift
//  SimpleObserver
//
//  Created by 林達也 on 2015/01/30.
//  Copyright (c) 2015年 林達也. All rights reserved.
//

import Foundation


final class Observer {
    
    private weak var owner: AnyObject?
    private let queue: dispatch_queue_t
    private let emitter: (Any) -> Void
    
    init(owner: AnyObject, queue: dispatch_queue_t, emitter: (Any) -> Void) {
        
        self.owner = owner
        self.queue = queue
        self.emitter = emitter
    }
}

protocol ObservingProtocol {
    
    typealias Element
}

public class UnsafeObserving<T>: ObservingProtocol {

    typealias Element = T
    typealias Event = (newValue: Element, oldValue: Element)
    typealias Emitter = (Event) -> Void

    let equatable: (newValue: Element, oldValue: Element) -> Bool
    let default_queue: dispatch_queue_t
    lazy var observers: [Observer] = []

    public var value: Element {
        didSet {
            self.fire(self.value, oldValue: oldValue)
        }
    }

    public init(_ value: Element, equatable: ((newValue: Element, oldValue: Element) -> Bool)? = nil, queue: dispatch_queue_t = dispatch_get_main_queue()) {
        self.value = value
        self.default_queue = queue
        if let equatable = equatable {
            self.equatable = equatable
        } else {
            self.equatable = { _ in true }
        }
    }

    public func watch<O: AnyObject>(target: O, emitter: (event: Event, observer: O) -> Void) {
        self.watch(target, self.default_queue, emitter: emitter)
    }

    public func watch<O: AnyObject>(target: O, _ queue: dispatch_queue_t, emitter: (event: Event, observer: O) -> Void) {

        let observer = Observer(owner: target, queue: queue) { [weak target] in
            emitter(event: ($0 as Event), observer: target!)
        }
        self.observers.append(observer)
    }

    public func unwatch(target: AnyObject) {

        for i in reverse(0..<self.observers.count) {
            let v = self.observers[i]
            if target === v.owner || v.owner == nil {
                self.observers.removeAtIndex(i)
            }
        }
    }

    private func trigger(e: Event) {

        for i in reverse(0..<self.observers.count) {
            let o = self.observers[i]
            if let owner: AnyObject = o.owner {
                dispatch_async(o.queue) {
                    o.emitter(e)
                }
            } else {
                self.observers.removeAtIndex(i)
            }
        }
    }
    
    private func fire(newValue: Element, oldValue: Element) {
        
        if !self.equatable(newValue: newValue, oldValue: oldValue) {
            self.trigger((newValue: newValue, oldValue: oldValue))
        }
    }
}

/**
*
*/
public final class Observing<T: Equatable>: UnsafeObserving<T> {
    
    public init(_ value: Element, queue: dispatch_queue_t = dispatch_get_main_queue()) {
        super.init(value, equatable: { vv in
            vv.newValue == vv.oldValue
            }, queue: queue)
    }
}

/**
*
*/
public final class ObjectObserving<T: AnyObject>: UnsafeObserving<T> {
    
    public init(_ value: Element, queue: dispatch_queue_t = dispatch_get_main_queue()) {
        super.init(value, equatable: { vv in
            vv.newValue === vv.oldValue
            }, queue: queue)
    }
}

/**
*
*/
public final class OptionalObserving<U>: UnsafeObserving<U?> {
    
    private let customEquatable: ((newValue: U, oldValue: U) -> Bool)?
    
    public override init(_ value: Element, equatable: ((newValue: Element, oldValue: Element) -> Bool)?, queue: dispatch_queue_t = dispatch_get_main_queue()) {
        super.init(value, equatable: equatable, queue: queue)
    }
    
    public init(_ value: U, equatable: ((newValue: U, oldValue: U) -> Bool)? = nil, queue: dispatch_queue_t = dispatch_get_main_queue()) {
        if let equatable = equatable {
            self.customEquatable = equatable
        } else {
            self.customEquatable = { _ in true }
        }
        super.init(Optional(value), equatable: nil, queue: queue)
    }
    
    private override func fire(newValue: Element, oldValue: Element) {
        
        switch (newValue, oldValue) {
        case let (.Some(newValue), .Some(oldValue)):
            if let custom = self.customEquatable {
                if !custom(newValue: newValue, oldValue: oldValue) {
                    self.trigger((newValue: Optional(newValue), oldValue: Optional(oldValue)))
                }
            } else {
                if !self.equatable(newValue: newValue, oldValue: oldValue) {
                    self.trigger((newValue: Optional(newValue), oldValue: Optional(oldValue)))
                }
            }
        case (.Some, .None), (.None, .Some):
            if !self.equatable(newValue: newValue, oldValue: oldValue) {
                self.trigger((newValue: newValue, oldValue: oldValue))
            }
        case (.None, .None):
            break
        }
    }
}


public final class Box<T> {
    
    public let unbox: T
    
    init(_ v: T) {
        self.unbox = v
    }
}

public enum KeyValueChange<T> {
    case Setting
    case Insertion(Box<T>, Int)
    case Removal(Box<T>, Int)
    case Replacement(Box<T>, Int)
}

extension KeyValueChange: Printable {

    public var description: String {
        switch self {
        case .Setting:
            return "Setting"
        case .Insertion:
            return "Insertion"
        case .Removal:
            return"Removal"
        case .Replacement:
            return "Replacement"
        }
    }
}

public class ObservingArray<T>: ObservingProtocol {
    
    typealias Element = T
    typealias Event = (newValue: [Element], oldValue: [Element], change: KeyValueChange<T>)
    typealias Emitter = (Event) -> Void

    let default_queue: dispatch_queue_t
    lazy var observers: [Observer] = []
    
    var _values: [Element] = []
    public var values: [Element] {
        set {
            let oldValue = self._values
            self._values = newValue
            
            let e: Event = (newValue: newValue, oldValue: oldValue, change: .Setting)
            self.trigger(e)
        }
        get {
            return self._values
        }
    }
    
    public var count: Int { return self.values.count }
    
    /// `true` if and only if the `Array` is empty
    public var isEmpty: Bool { return self.values.isEmpty }
    
    /// The first element, or `nil` if the array is empty
    public var first: T? { return self.values.first }
    
    /// The last element, or `nil` if the array is empty
    public var last: T? { return self.values.last }
    
    
    
    public init(_ values: [Element] = [], queue: dispatch_queue_t = dispatch_get_main_queue()) {
        self._values = values
        self.default_queue = queue
    }
    
    public func watch<O: AnyObject>(target: O, emitter: (event: Event, observer: O) -> Void) {
        self.watch(target, self.default_queue, emitter: emitter)
    }
    
    public func watch<O: AnyObject>(target: O, _ queue: dispatch_queue_t, emitter: (event: Event, observer: O) -> Void) {
        
        let observer = Observer(owner: target, queue: queue) { [weak target] in
            emitter(event: ($0 as Event), observer: target!)
        }
        self.observers.append(observer)
    }
    
    public func unwatch(target: AnyObject) {

        for i in reverse(0..<self.observers.count) {
            let v = self.observers[i]
            if target === v.owner || v.owner == nil {
                self.observers.removeAtIndex(i)
            }
        }
    }
    
    private func trigger(e: Event) {
        
        for i in reverse(0..<self.observers.count) {
            let o = self.observers[i]
            if let owner: AnyObject = o.owner {
                dispatch_async(o.queue) {
                    o.emitter(e)
                }
            } else {
                self.observers.removeAtIndex(i)
            }
        }
    }
}

extension ObservingArray {

    public subscript(idx: Int) -> Element {
        get {
            return self._values[idx]
        }
        set {
            let oldValue = self._values
            self._values[idx] = newValue

            let e: Event = (newValue: self._values, oldValue: oldValue, change: .Replacement(Box(newValue), idx))
            self.trigger(e)
        }
    }
    
    public func append(newElement: Element) {
        self.insert(newElement, atIndex: self.count)
    }
    
    public func insert(newElement: Element, atIndex index: Int) {
        let oldValue = self._values
        self._values.insert(newElement, atIndex: index)
        let newValue = self._values
        
        var change: KeyValueChange<Element>!
        if oldValue.count == newValue.count {
            change = .Replacement(Box(newElement), index)
        } else {
            change = .Insertion(Box(newElement), index)
        }
        
        let e: Event = (newValue: newValue, oldValue: oldValue, change: change)
        self.trigger(e)
    }
    
    public func extend(newElements: [Element]) {
        for (idx, v) in enumerate(newElements) {
            self.insert(v, atIndex: idx)
        }
    }
    
    public func removeAtIndex(index: Int) -> Element {
        let oldValue = self._values
        let v = self._values.removeAtIndex(index)
        let newValue = self._values
        
        let e: Event = (newValue: newValue, oldValue: oldValue, change: .Removal(Box(v), index))
        self.trigger(e)
        
        return v
    }
    
    public func removeLast() -> Element {
        
        return self.removeAtIndex(self.count - 1)
    }
    
    public func removeAll() {
        
        for _ in reverse(self._values) {
            self.removeLast()
        }
    }
}

infix operator <= { associativity right }
public func <= <T>(lhs: UnsafeObserving<T>, rhs: T) {
    lhs.value = rhs
}

public func <= <T: Equatable>(lhs: Observing<T>, rhs: T) {
    lhs.value = rhs
}

public func <= <T>(lhs: ObservingArray<T>, rhs: [T]) {
    lhs.values = rhs
}
