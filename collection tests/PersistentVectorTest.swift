import XCTest

import Mutabor

private let MAX = VECTOR_TEST_MAX
private let ReplacementRounds = 100 * 1000

class PersistentVectorTest: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMiniTest_() {
        var before = CFAbsoluteTimeGetCurrent()
        
        var arrayList = [Int]()
        
        for i in 0 ... 350_000 {
            arrayList.append(i)
        }
        
        var after = CFAbsoluteTimeGetCurrent()
        
        print("finished constructing ArrayList of size \(arrayList.count) in \(after - before)")
        
        before = CFAbsoluteTimeGetCurrent()
        
        let vector = PersistentVector<Int>(seq: arrayList)
        
        after = CFAbsoluteTimeGetCurrent()
        
        print("finished constructing Vector of size \(vector.count), depth \(vector.depth) from ArrayList in \(after - before) - deltaT per creation: \( (after - before) / Double(vector.count) )")
    }
    
    func testMiniTest() {
        var vec = PersistentVector<Int>()
        
        print(vec)
        
        var n = 0
        var deltaTSum = 0.0
        
        for idx in 0 ..< 350_001 {
            let before = CFAbsoluteTimeGetCurrent()
            vec.add(idx)
            let after = CFAbsoluteTimeGetCurrent()
            
            deltaTSum += after - before
            n += 1
            
            if (idx % 100000) == 0 {
                print("\(idx)")
            }
            
            //println(vec)
            
            /*if vec.count != idx + 1 {
             fatalError("wrong size for idx \(idx): \(vec.count)")
             }
             
             for idx2 in 0 ... idx {
             if vec.get(idx2) != idx2 {
             fatalError("Mismatch for idx \(idx), idx2 \(idx2)")
             }
             }*/
        }
        
        print("n: \(n), deltaTSum: \(deltaTSum), deltaT per creation: \(deltaTSum / Double(n))")
        
        print("size: \(vec.count), depth: \(vec.depth)")
    }
    
    func testVectorBasics() {
        print("vectorBasics...")
        
        var vec = PersistentVector<Int>()
        
        print(vec)
        
        for idx in 0 ..< 300 {
            vec.add(idx)
            //println(vec)
            
            if idx % 100 == 0 {
                print("idx: \(idx)")
            }
            
            XCTAssert(vec.count == idx + 1, "vec.count [\(vec.count)] != idx [\(idx)] + 1")
            
            for idx2 in 0 ... idx {
                XCTAssert(vec.get(idx2) == idx2, "vec.get(idx2) [\(vec.get(idx2))] != idx2 [\(idx2)], with idx \(idx)")
            }
            
            var idx3 = 0
            for e in vec {
                XCTAssert(e == idx3,"e [\(e)] != idx3 [\(idx3)]")
                idx3 += 1
            }
        }
        
        print("")
    }
    
    // ported from Java
    
    func testArrayListGrowingBehavior() {
        print("arrayListGrowingBehavior...")
        
        var arrayList = [Int]()
        
        var lastTs = CFAbsoluteTimeGetCurrent()
        
        var lastTsIndex = -1
        
        for i in 0 ... MAX {
            arrayList.append(i)
            
            if i - lastTsIndex >= (1 << 16) {
                let tsNow = CFAbsoluteTimeGetCurrent()
                
                let deltaT = tsNow - lastTs
                let deltaTPerElement = deltaT / Double(i - lastTsIndex) * 1000.0 * 1000.0
                
                print(NSString(format: "i: %12d, depth: -, deltaT: %f, deltaT / million elements: %f%n", i, deltaT, deltaTPerElement))
                
                lastTs = tsNow
                lastTsIndex = i
            }
        }
        
        print("Creating vector...")
        
        lastTs = CFAbsoluteTimeGetCurrent()
        
        let vector = PersistentVector<Int>(seq: arrayList)
        
        let deltaT = (CFAbsoluteTimeGetCurrent() - lastTs)
        
        print(NSString(format: "Vector created from arrayList of size %d - size: %d, depth: %d - deltaT: %f%n", arrayList.count, vector.count, vector.depth, deltaT))
        
        XCTAssertEqual(vector.count, arrayList.count)
        
        print("Sizes match.")
        
        for i in 0 ... MAX {
            if i % (1 << 16) == 0 {
                print(i)
            }
            
            if i != vector.get(i) {
                fatalError("i != vector.get(i) for i: \(i)")
            }
        }
        
        print("Elements match.")
        
        let before = CFAbsoluteTimeGetCurrent()
        
        var i = 0
        for value in vector {
            if i % (1 << 16) == 0 {
                print(i)
            }
            
            if i != value {
                fatalError("i != value for i: \(i), value: \(value)")
            }
            
            i += 1
        }
        
        let after = CFAbsoluteTimeGetCurrent()
        
        print(NSString(format: "deltaT for iterator-based comparison: %.3f ms%n", (after - before) * 1000.0))
        
        print("equality tests succeeded")
        
        print("")
        
        drain(vector)
    }
    
    func testGrowingBehavior() {
        print("growingBehavior...")
        
        var vector = PersistentVector<Int>()
        
        var lastDepth: Int? = nil
        var lastTs = CFAbsoluteTimeGetCurrent()
        var lastTsIndex = -1
        
        for i in 0 ... MAX {
            if randomBool() {
                vector.add(i)
            } else {
                vector = vector.plus(i)
            }
            
            let depth = vector.depth
            
            if depth != lastDepth || (i - lastTsIndex >= 1024 * 1024) {
                let tsNow = CFAbsoluteTimeGetCurrent()
                let deltaT = tsNow - lastTs
                let deltaTPerElement = deltaT / Double(i - lastTsIndex) * 1000.0 * 1000.0
                
                print(NSString(format: "i: %12d, depth: %d, hashCode: %08x, deltaT: %f, deltaT / million elements: %f%n", i, depth, vector.hashValue, deltaT, deltaTPerElement))
                
                lastDepth = depth
                lastTs = tsNow
                lastTsIndex = i
            }
        }
        
        for i in 0 ... MAX {
            XCTAssertEqual(i, vector.get(i))
        }
        
        XCTAssertEqual(vector.count, MAX + 1)
        
        if vector.count == MAX + 1 {
            print("Sizes match - vactor.count: \(vector.count), MAX: \(MAX)")
        }
        
        lastTs = CFAbsoluteTimeGetCurrent()
        
        let arrayList = [Int](vector)
        
        var deltaT = CFAbsoluteTimeGetCurrent() - lastTs
        
        print(NSString(format: "ArrayList created from vector - size: %d - deltaT: %f%n", arrayList.count, deltaT))
        
        XCTAssertEqual(arrayList.count, vector.count)
        
        lastTs = CFAbsoluteTimeGetCurrent()
        
        vector = PersistentVector<Int>(seq: arrayList)
        
        deltaT = CFAbsoluteTimeGetCurrent() - lastTs
        
        print(NSString(format: "Vector created again from arrayList - size: %d, depth: %d - deltaT: %f%n", vector.count, vector.depth, deltaT))
        
        XCTAssertEqual(vector.count, arrayList.count)
        
        print("")
        
        drain(vector)
    }
    
    func testGrowingBehaviorWithRemoval() {
        print("growingBehaviorWithRemoval...")
        
        var vector = PersistentVector<Int>()
        
        var lastDepth: Int? = nil
        var lastTs = CFAbsoluteTimeGetCurrent()
        var lastTsIndex = -1
        
        var list = [Int]()
        
        for i in 0 ... MAX {
            if randomBool() {
                vector.add(i)
            } else {
                vector = vector.plus(i)
            }
            
            if randomBool() {
                list.append(i)
            } else {
                if randomBool() {
                    vector.removeLast()
                } else {
                    vector = vector.withoutLast()
                }
            }
            
            let depth = vector.depth
            
            if depth != lastDepth || (i - lastTsIndex >= 1024 * 1024) {
                let tsNow = CFAbsoluteTimeGetCurrent()
                let deltaT = tsNow - lastTs
                let deltaTPerElement = deltaT / Double(i - lastTsIndex) * 1000.0 * 1000.0
                
                print(NSString(format: "i: %12d, depth: %d, hashCode: %08x, deltaT: %f, deltaT / million elements: %f%n", i, depth, vector.hashValue, deltaT, deltaTPerElement))
                
                lastDepth = depth
                lastTs = tsNow
                lastTsIndex = i
            }
        }
        
        XCTAssertEqual(list.count, vector.count)
        XCTAssertTrue(eq(list, vector))
        XCTAssertTrue(eq(vector, list))
        lastTs = CFAbsoluteTimeGetCurrent()
        
        let arrayList = [Int](vector)
        
        var deltaT = CFAbsoluteTimeGetCurrent() - lastTs
        
        print(NSString(format: "ArrayList created from vector - size: %d - deltaT: %f%n", arrayList.count, deltaT))
        
        XCTAssertEqual(arrayList.count, vector.count)
        
        lastTs = CFAbsoluteTimeGetCurrent()
        
        vector = PersistentVector<Int>(seq: arrayList)
        
        deltaT = CFAbsoluteTimeGetCurrent() - lastTs
        
        print(NSString(format: "Vector created again from arrayList - size: %d, depth: %d - deltaT: %f%n", vector.count, vector.depth, deltaT))
        
        XCTAssertEqual(vector.count, arrayList.count)
        
        print("")
        
        drain(vector)
    }
    
    func testEmptyInstance() {
        print("emptyInstance...")
        
        var vector = PersistentVector<String>()
        let emptyVector = vector
        for i in 0 ..< 1000 {
            vector.add(i.description)
            XCTAssertEqual(vector.count, i + 1)
            XCTAssertEqual(emptyVector.count, 0)
        }
        
        print("")
    }
    
    func testWith() {
        print("with...")
        
        var before = CFAbsoluteTimeGetCurrent()
        
        var arrayList = [Int]()
        
        for i in 0 ... MAX {
            arrayList.append(i)
        }
        
        var after = CFAbsoluteTimeGetCurrent()
        
        print("finished constructing ArrayList of size \(arrayList.count) in \(after - before)")
        
        before = CFAbsoluteTimeGetCurrent()
        
        var vector = PersistentVector<Int>(seq: arrayList)
        
        after = CFAbsoluteTimeGetCurrent()
        
        print("finished constructing Vector of size \(vector.count), depth \(vector.depth) from ArrayList in \(after - before)")
        
        before = CFAbsoluteTimeGetCurrent()
        
        XCTAssertEqual(vector.count, arrayList.count)
        
        for i in 0 ... MAX {
            XCTAssertEqual(i, vector.get(i))
        }
        
        after = CFAbsoluteTimeGetCurrent()
        
        print("finished checking equality in \(after - before)")
        
        before = CFAbsoluteTimeGetCurrent()
        
        // guard block
        if true {
            var i = 0
            for value in vector {
                XCTAssertEqual(i, value)
                i += 1
            }
        }
        
        after = CFAbsoluteTimeGetCurrent()
        
        print("finished checking values with iterator in \(after - before)")
        
        srandom(0x01234567)
        
        let size = UInt32(vector.count)
        
        let originalArrayList = [Int](arrayList)
        let originalVector = vector
        
        before = CFAbsoluteTimeGetCurrent()
        
        for i in 0 ..< ReplacementRounds {
            let newValue = Int(arc4random())
            let idx = boundedRandom(size)
            
            arrayList[idx] = newValue
            
            if randomBool() {
                vector.set(idx, value: newValue)
            } else {
                vector = vector.with(idx, value: newValue)
            }
            
            if i % 100000 == 0 { print("finished replacement round \(i)") }
        }
        
        after = CFAbsoluteTimeGetCurrent()
        
        print(NSString(format: "deltaT for %d rounds of replacement: %.3f ms%n", ReplacementRounds, (after - before) * 1000.0))
        
        before = CFAbsoluteTimeGetCurrent()
        
        if eq(vector, arrayList) == false || eq(arrayList, vector) == false {
            fatalError("vector and arrayList do not match.");// - vector: " + vector + ", arrayList: " + arrayList)
        }
        
        after = CFAbsoluteTimeGetCurrent()
        
        print("ArrayList / vector equality tests succeeded in \(after - before)")
        
        before = CFAbsoluteTimeGetCurrent()
        
        if eq(originalArrayList, originalVector) == false || eq(originalVector, originalArrayList) == false {
            fatalError("originalArrayList and originalVector do not match.")
        }
        
        after = CFAbsoluteTimeGetCurrent()
        
        print("old / new vector equality tests succeeded in \(after - before)")
        
        //println("vector: \(vector)")
        
        print("")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
}

// TODO replace with a correct, integer-only implementation
func boundedRandom(_ bound: UInt32) -> Int {
    precondition(bound > 0, "bound > 0")
    
    // TODO fix
    return Int(arc4random_uniform(bound))
}

func eq<A: Sequence, B: Sequence>
    (_ a: A, _ b: B) -> Bool
    where A.Iterator.Element: Equatable, B.Iterator.Element == A.Iterator.Element {
    var aGenerator = a.makeIterator()
    var bGenerator = b.makeIterator()
    
    while true {
        let aOption = aGenerator.next()
        let bOption = bGenerator.next()
        
        if aOption == nil && bOption == nil {
            return true
        } else if aOption == nil || bOption == nil {
            return false
        } else if aOption! != bOption! {
            return false
        }
        
        // both are non-nil and have equal values, continue...
    }
}

func drain<E>(_ set: PersistentVector<E>) {
    if randomBool() {
        drainPersistently(set)
        drainInPlace(set)
    } else {
        drainInPlace(set)
        drainPersistently(set)
    }
}

func drainPersistently<E>(_ vector: PersistentVector<E>) {
    var vector = vector
    
    if vector.count == 0 {
        return
    }
    
    print("draining persistently vector of size \(vector.count)")
    
    let sizeBefore = vector.count
    var size = sizeBefore
    
    var firstEntry: E?
    var lastEntry: E?
    
    for entry in vector {
        vector = vector.withoutLast()
        
        size -= 1
        
        XCTAssertEqual(vector.count, size)
        
        if firstEntry == nil {
            firstEntry = entry
        }
        
        lastEntry = entry
    }
    
    XCTAssertEqual(vector.count, 0)
    
    vector = vector.plus(firstEntry!)
    
    XCTAssertEqual(vector.count, 1)
    
    if sizeBefore > 1 {
        print("shuffling first, last")
        
        vector = vector.plus(lastEntry!)
        
        XCTAssertEqual(vector.count, 2)
        
        vector = vector.withoutLast()
        
        XCTAssertEqual(vector.count, 1)
        
        vector = vector.withoutLast()
    } else {
        vector = vector.withoutLast()
    }
    
    XCTAssertEqual(vector.count, 0)
}

func drainInPlace<E>(_ vector: PersistentVector<E>) {
    var vector = vector
    
    if vector.count == 0 {
        return
    }
    
    print("draining in place vector of size \(vector.count)")
    
    let sizeBefore = vector.count
    var size = sizeBefore
    
    var firstEntry: E?
    var lastEntry: E?
    
    for entry in vector {
        vector.removeLast()
        
        size -= 1
        
        XCTAssertEqual(vector.count, size)
        
        if firstEntry == nil {
            firstEntry = entry
        }
        
        lastEntry = entry
    }
    
    XCTAssertEqual(vector.count, 0)
    
    vector.add(firstEntry!)
    
    XCTAssertEqual(vector.count, 1)
    
    if sizeBefore > 1 {
        print("shuffling first, last")
        
        vector.add(lastEntry!)
        
        XCTAssertEqual(vector.count, 2)
        
        vector.removeLast()
        
        XCTAssertEqual(vector.count, 1)
        
        vector.removeLast()
    } else {
        vector.removeLast()
    }
    
    XCTAssertEqual(vector.count, 0)
}
