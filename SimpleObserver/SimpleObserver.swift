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

/**
*
*/
public protocol ObservingProtocol {
    
    typealias ValueType
    typealias Element
    typealias EquatableProvider
    typealias Event
    
    var value: ValueType { get set }
    
    init(_ value: ValueType, _ equatable: EquatableProvider, queue: dispatch_queue_t)
    
    func watch<O: AnyObject>(target: O, emitter: (event: Event, observer: O) -> Void)
    func watch<O: AnyObject>(target: O, _ queue: dispatch_queue_t, emitter: (event: Event, observer: O) -> Void)
    
    func unwatch(target: AnyObject)
}


private protocol ObservingProtocolPrivate: ObservingProtocol {
    
    var equatable: EquatableProvider { get }
    var default_queue: dispatch_queue_t { get }
    
    var observers: [Observer] { get }
    
    func appendObserver(observer: Observer)
    func removeObserverAtIndex(idx: Int)
    
    func fire(newValue: ValueType, oldValue: ValueType)
}


//MARK:

private func ObservingWatch<T: ObservingProtocolPrivate, O : AnyObject>(observing: T, target: O, queue: dispatch_queue_t, emitter: (event: T.Event, observer: O) -> Void) {
    
    let observer = Observer(owner: target, queue: queue) { [weak target] in
        if let target = target {
            emitter(event: ($0 as T.Event), observer: target)
        }
    }
    
    observing.appendObserver(observer)
}

private func ObservingUnwatch<T: ObservingProtocolPrivate>(observing: T, target: AnyObject) {
    
    for i in reverse(0..<observing.observers.count) {
        let v = observing.observers[i]
        if target === v.owner || v.owner == nil {
            observing.removeObserverAtIndex(i)
        }
    }
}

private func ObservingTrigger<T: ObservingProtocolPrivate>(observing: T, event: T.Event) {
    
    for i in reverse(0..<observing.observers.count) {
        let o = observing.observers[i]
        if let owner: AnyObject = o.owner {
            dispatch_async(o.queue) {
                o.emitter(event)
            }
        } else {
            observing.removeObserverAtIndex(i)
        }
    }
}

//private func ObservingFire<T: ObservingProtocolPrivate>(observing: T, newValue: T.Element, oldValue: T.Element) {
//    
//    if !observing.equatable(newValue: newValue, oldValue: oldValue) {
//        
//    }
//}

//MARK:
/**
*
*/
public final class Observing<T>: ObservingProtocol, ObservingProtocolPrivate {
    
    public typealias ValueType = T
    public typealias Element = T
    public typealias EquatableProvider = (newValue: Element, oldValue: Element) -> Bool
    public typealias Event = (newValue: ValueType, oldValue: ValueType)
    
    let equatable: EquatableProvider
    let default_queue: dispatch_queue_t
    var observers: [Observer] = []
    
    public var value: ValueType {
        didSet {
            self.fire(self.value, oldValue: oldValue)
        }
    }
    
    public init(_ value: ValueType, _ equatable: EquatableProvider, queue: dispatch_queue_t = dispatch_get_main_queue()) {
        
        self.value = value
        self.equatable = equatable
        self.default_queue = queue
    }
    
    public func watch<O : AnyObject>(target: O, emitter: (event: Event, observer: O) -> Void) {
        
        ObservingWatch(self, target, self.default_queue, emitter)
    }
    
    public func watch<O : AnyObject>(target: O, _ queue: dispatch_queue_t, emitter: (event: Event, observer: O) -> Void) {
        
        ObservingWatch(self, target, queue, emitter)
    }
    
    public func unwatch(target: AnyObject) {
        
        ObservingUnwatch(self, target)
    }
    
    func trigger(e: Event) {
        
        ObservingTrigger(self, e)
    }
    
    private func appendObserver(observer: Observer) {
        self.observers.append(observer)
    }
    
    private func removeObserverAtIndex(idx: Int) {
        self.observers.removeAtIndex(idx)
    }
    
    private func fire(newValue: ValueType, oldValue: ValueType) {
        
        if !self.equatable(newValue: newValue, oldValue: oldValue) {
            ObservingTrigger(self, (newValue: newValue, oldValue: oldValue))
        }
    }
}

public final class OptionalObserving<U>: ObservingProtocol, ObservingProtocolPrivate {
    
    public typealias ValueType = U?
    public typealias Element = U
    public typealias EquatableProvider = (newValue: Element, oldValue: Element) -> Bool
    public typealias Event = (newValue: ValueType, oldValue: ValueType)
    
    let equatable: EquatableProvider
    let default_queue: dispatch_queue_t
    var observers: [Observer] = []
    
    public var value: ValueType {
        didSet {
            self.fire(self.value, oldValue: oldValue)
        }
    }
    
    public init(_ value: ValueType, _ equatable: EquatableProvider, queue: dispatch_queue_t = dispatch_get_main_queue()) {
        
        self.value = value
        self.equatable = equatable
        self.default_queue = queue
    }
    public func watch<O : AnyObject>(target: O, emitter: (event: Event, observer: O) -> Void) {
        
        ObservingWatch(self, target, self.default_queue, emitter)
    }
    
    public func watch<O : AnyObject>(target: O, _ queue: dispatch_queue_t, emitter: (event: Event, observer: O) -> Void) {
        
        ObservingWatch(self, target, queue, emitter)
    }
    
    public func unwatch(target: AnyObject) {
        
        ObservingUnwatch(self, target)
    }
    
    func trigger(e: Event) {
        
        ObservingTrigger(self, e)
    }
    
    private func appendObserver(observer: Observer) {
        self.observers.append(observer)
    }
    
    private func removeObserverAtIndex(idx: Int) {
        self.observers.removeAtIndex(idx)
    }
    
    private func fire(newValue: ValueType, oldValue: ValueType) {
        
        switch (newValue, oldValue) {
        case let (.Some(newValue), .Some(oldValue)):
            if !self.equatable(newValue: newValue, oldValue: oldValue) {
                ObservingTrigger(self, (newValue: newValue, oldValue: oldValue))
            }
        case (.Some, .None), (.None, .Some):
            ObservingTrigger(self, (newValue: newValue, oldValue: oldValue))
        case (.None, .None):
            break
        }
    }
}

public final class ObservingArray<T>: ObservingProtocol, ObservingProtocolPrivate {
    
    public typealias ValueType = [T]
    public typealias Element = T
    public typealias EquatableProvider = (newValue: Element, oldValue: Element) -> Bool
    public typealias Event = (newValue: ValueType, oldValue: ValueType, change: KeyValueChange<Element>)
    
    let equatable: EquatableProvider
    let default_queue: dispatch_queue_t
    var observers: [Observer] = []
    
    private var _value: ValueType = []
    
    public var value: ValueType {
        set {
            let oldValue = self._value
            self._value = newValue
            
            let e: Event = (newValue: newValue, oldValue: oldValue, change: .Setting)
            ObservingTrigger(self, e)
        }
        get {
            return self._value
        }
    }
    
    public init(_ value: ValueType, _ equatable: EquatableProvider, queue: dispatch_queue_t = dispatch_get_main_queue()) {
        
        self._value = value
        self.equatable = equatable
        self.default_queue = queue
    }
    public func watch<O : AnyObject>(target: O, emitter: (event: Event, observer: O) -> Void) {
        
        ObservingWatch(self, target, self.default_queue, emitter)
    }
    
    public func watch<O : AnyObject>(target: O, _ queue: dispatch_queue_t, emitter: (event: Event, observer: O) -> Void) {
        
        ObservingWatch(self, target, queue, emitter)
    }
    
    public func unwatch(target: AnyObject) {
        
        ObservingUnwatch(self, target)
    }
    
    func trigger(e: Event) {
        
        ObservingTrigger(self, e)
    }
    
    private func appendObserver(observer: Observer) {
        self.observers.append(observer)
    }
    
    private func removeObserverAtIndex(idx: Int) {
        self.observers.removeAtIndex(idx)
    }
    
    private func fire(newValue: ValueType, oldValue: ValueType) {
        
    }
}

extension ObservingArray {
    
    public var count: Int { return self.value.count }
    
    /// `true` if and only if the `Array` is empty
    public var isEmpty: Bool { return self.value.isEmpty }
    
    /// The first element, or `nil` if the array is empty
    public var first: Element? { return self.value.first }
    
    /// The last element, or `nil` if the array is empty
    public var last: Element? { return self.value.last }
    
    
}

extension ObservingArray {
    
    public subscript(idx: Int) -> Element {
        get {
            return self._value[idx]
        }
        set {
            let oldValue = self._value[idx]
            let oldValues = self._value
            self._value[idx] = newValue
        
            if !self.equatable(newValue: newValue, oldValue: oldValue) {
                let e: Event = (newValue: self._value, oldValue: oldValues, change: .Replacement(Box(newValue), idx))
                self.trigger(e)
            }
        }
    }
    
    public func append(newElement: Element) {
        self.insert(newElement, atIndex: self.count)
    }
    
    public func insert(newElement: Element, atIndex index: Int) {
        let oldValue = self._value
        self._value.insert(newElement, atIndex: index)
        let newValue = self._value
        
        let e: Event = (newValue: newValue, oldValue: oldValue, change: .Insertion(Box(newElement), index))
        self.trigger(e)
    }
    
    public func extend(newElements: [Element]) {
        for (idx, v) in enumerate(newElements) {
            self.insert(v, atIndex: idx)
        }
    }
    
    public func removeAtIndex(index: Int) -> Element {
        let oldValue = self._value
        let v = self._value.removeAtIndex(index)
        let newValue = self._value
        
        let e: Event = (newValue: newValue, oldValue: oldValue, change: .Removal(Box(v), index))
        self.trigger(e)
        
        return v
    }
    
    public func removeLast() -> Element {
        
        return self.removeAtIndex(self.count - 1)
    }
    
    public func removeAll() {
        
        for _ in reverse(self._value) {
            self.removeLast()
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
