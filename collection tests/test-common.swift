
import Foundation
import Mutabor

let VECTOR_TEST_MAX = 3500 * 100

let MAP_TEST_MAX = 5000 * 10

let ApproxMax = MAP_TEST_MAX
let CubicRoot = Int32(pow(Double(ApproxMax), 1.0 / 3.0))
let Max = (CubicRoot - 1) * (CubicRoot - 1) * (CubicRoot - 1) + 1023

func randomBool(_ module: UInt32 = 2) -> Bool {
    return (arc4random() % module) == 0
}

func randomInt() -> Int32 {
    return Int32(bitPattern: arc4random())
}

func randomInt(_ max: Int32) -> Int32 {
    return Int32(bitPattern: arc4random_uniform(UInt32(max) + 1))
}

func randomLong() -> Int64 {
    let result = UInt64(arc4random_uniform(1 << 24)) &* UInt64(ReasonablePrime) &* UInt64(ReasonablePrime) &* UInt64(ReasonablePrime)
    return Int64(bitPattern: result)
}

func randomSize() -> Int32 {
    return randomInt(CubicRoot) * randomInt(CubicRoot) * randomInt(CubicRoot) + randomInt(1024)
}

struct HighHashCollider : Hashable, Equatable, Comparable {
    let value: Int64
    
    init(_ value: Int64) {
        self.value = value
    }
    
    var hashValue : Int {
        get {
            return value.hashValue & 0xFFFF0000
        }
    }
}

func == (lhs: HighHashCollider, rhs: HighHashCollider) -> Bool {
    return lhs.value == rhs.value
}

func < (lhs: HighHashCollider, rhs: HighHashCollider) -> Bool {
    return lhs.value < rhs.value
}

struct LowHashCollider : Hashable, Equatable, Comparable {
    let value: Int64
    
    init(_ value: Int64) {
        self.value = value
    }
    
    var hashValue : Int {
        get {
            return value.hashValue & 0x0000FFFF
        }
    }
}

func == (lhs: LowHashCollider, rhs: LowHashCollider) -> Bool {
    return lhs.value == rhs.value
}

func < (lhs: LowHashCollider, rhs: LowHashCollider) -> Bool {
    return lhs.value < rhs.value
}
