
import Foundation

//miniTest()

struct Oops : Error {
    var message: String
}

func f() throws {
    var x = 5
    
    try x += g() + g() + g()
}

func g() throws -> Int {
    throw Oops(message: "hi! :)")
}

do {
    try f()
} catch let error {
    print("message: \(error)")
}

struct Notoops : Error {
}

let list = [Error](arrayLiteral: Oops(message: "hi! :)"), Notoops())

for o in list {
    switch(o) {
    case let x as Oops:
        print("oops " + x.message)
    default:
        print("not an oops")
    }
}

/*var copy: Dictionary<Int, Int>

var dict = Dictionary<Int, Int>()

let n = 5 * 1000// * 1000

for var idx = 0; idx < n; ++idx {
    dict[idx] = idx
    
    copy = dict
    
    if idx % 1000 == 0 {
        print("\(idx) / \(n)")
    }
}*/

protocol EventVisitor {
    func visit(_ event: TimeEvent)
    func visit(_ event: StatusEvent)
}

protocol Event {
    var ts: Int64 { get set }
    
    func accept(_ visitor: EventVisitor)
}

struct TimeEvent : Event {
    var ts: Int64
    var time: Int64
    
    func accept(_ visitor: EventVisitor) {
        visitor.visit(self)
    }
}

protocol StatusEventVisitor {
    func visit(_ event: StatusLostStatusEvent)
    func visit(_ event: StatusChangedStatusEvent)
}

protocol StatusEvent : Event {
    var deviceId: Int64 { get set }
    
    func accept(_ visitor: StatusEventVisitor)
}

struct StatusLostStatusEvent : StatusEvent {
    var ts: Int64
    var deviceId: Int64
    var reason: String
    
    func accept(_ visitor: EventVisitor) {
        visitor.visit(self)
    }
    
    func accept(_ visitor: StatusEventVisitor) {
        visitor.visit(self)
    }
}

struct StatusChangedStatusEvent : StatusEvent {
    var ts: Int64
    var deviceId: Int64
    var newStatus: UInt32
    var oldStatus: UInt32
    
    func accept(_ visitor: EventVisitor) {
        visitor.visit(self)
    }
    
    func accept(_ visitor: StatusEventVisitor) {
        visitor.visit(self)
    }
}

func readEvent(_ fd: Int) -> Event {
    return TimeEvent(ts: 123, time: 56789)
}

func example() {
    class Visitor : EventVisitor {
        var status: UInt32 = 3
        func visit(_ event: TimeEvent) {
            print("A time event: \(event)")
        }
        
        func visit(_ event: StatusEvent) {
            print("A status event: \(event)")
            
            if let change = event as? StatusChangedStatusEvent {
                status = change.newStatus
            }
        }
    }
    
    let visitor = Visitor()
    
    readEvent(1).accept(visitor)
    
    print("status: \(visitor.status)")
}

var events = [Event]()

enum E {
    case X(value: Int)
    
    mutating func f() {
        switch e {
        case let .X(value):
            self = .X(value: value + 5)
        }
    }
    
    var x: Int {
        get {
            return 5
        }
        
        set(value) {
            print(value)
        }
    }
}

var e = E.X(value: 3)

print(e)

e.f()

print(e)

let whatever: Int

if case .X(var x) = e {
    whatever = 5
} else {
    whatever = 7
}

print(whatever)

print(e)

class Internal {
    func f() -> Bool {
        unowned var x = self
        return isKnownUniquelyReferenced(&x)
    }
}

class C {
    var int = Internal()
    
    func f() -> Bool {
        unowned var x = self
        return isKnownUniquelyReferenced(&x)
    }
}

var c1 = C()

print(isKnownUniquelyReferenced(&c1))
print(isKnownUniquelyReferenced(&c1.int))
print("c1.f(): \(c1.f())")
print("c1.int.f(): \(c1.int.f())")

var c2 = c1

print(isKnownUniquelyReferenced(&c1))
print(isKnownUniquelyReferenced(&c2))
print(isKnownUniquelyReferenced(&c1.int))
print(isKnownUniquelyReferenced(&c2.int))
print("c1.f(): \(c1.f())")
print("c1.int.f(): \(c1.int.f())")
print("c2.f(): \(c2.f())")
print("c2.int.f(): \(c2.int.f())")

c2 = C()

print(isKnownUniquelyReferenced(&c1))
print(isKnownUniquelyReferenced(&c1.int))
print("c1.f(): \(c1.f())")
print("c1.int.f(): \(c1.int.f())")

var cs = [C?]()
cs.append(C())

print(isKnownUniquelyReferenced(&cs[0]))

if let thec = cs[0] {
    print(isKnownUniquelyReferenced(&cs[0]))
}

print(isKnownUniquelyReferenced(&cs[0]))

var pm = PersistentHashMap<Int, Int>()
var numbers = [Int]()
var maps = [PersistentHashMap<Int, Int>]()

for idx in 0 ..< 5 * 1000// * 1000 {
    let n = Int(arc4random())
    pm.put(n, value: n * 3)
    numbers.append(n)
    if (arc4random() % 17 == 0) {
        maps.append(pm)
    }
}

for idx in 0 ..< 5 * 1000// * 1000 {
    let n = numbers[idx]
    let result = pm.get(n)
    print(result as Any, " / n: \(n)")
    if (result != 3 * n) {
        fatalError()
    }
}

let u = UINT32_MAX
let i = Int32(bitPattern: u)
print(i)

    let dict = ["A": 1, "B": 2, "C": 3, "D": 4]

    let keys = dict.keys.sorted()

    for c in keys {
        print(dict["\(c)"]!, terminator: "")
    }

    print()
