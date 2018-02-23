
import XCTest
import Mutabor

class PersistentHashSetTest: XCTestCase {
    override func setUp() {
        super.setUp()
        
        super.continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    typealias RandomIntSource = () -> Int32
    
    func testBasicFunctionality() {
        let set = PersistentHashSet<Int>()
        
        XCTAssert(0 == set.count)
        
        let set2 = set.plus(3)
        
        XCTAssert(0 == set.count)
        XCTAssert(1 == set2.count)
        XCTAssert(set2.contains(3))
        XCTAssert(set2.contains(2) == false)
        XCTAssert(set2 == set2)
        
        let set3 = set2.plus(3)
        
        XCTAssert(0 == set.count)
        XCTAssert(1 == set2.count)
        XCTAssert(set2.contains(3))
        XCTAssert(set2.contains(2) == false)
        XCTAssert(1 == set3.count)
        XCTAssert(set3.contains(3))
        XCTAssert(set3.contains(2) == false)
        XCTAssert(set3 == set3)
        XCTAssert(set2 == set3)
        XCTAssert(set3 == set2)
        
        let set4 = set2.plus(5)
        XCTAssert(set3 == set3)
        XCTAssert(set2 == set3)
        XCTAssert(set3 == set2)
        XCTAssert(set4 != set2)
        XCTAssert(set2 != set4)
        XCTAssert(set4 != set3)
        XCTAssert(set3 != set4)
        
        var rm = PersistentHashSet<HighHashCollider>()
        print(rm.count)
        rm.add(HighHashCollider(1))
        print(rm.count)
        rm.add(HighHashCollider(2))
        print(rm.count)
        rm.add(HighHashCollider(2))
        print(rm.count)
        rm.remove(HighHashCollider(1))
        print(rm.count)
        
        XCTAssert(rm.count == 1)
        
        let a = HighHashCollider(randomLong())
        print("a: \(a.value)")
        let b = HighHashCollider(a.value)
        print("b: \(b.value)")
        print("a.value == b.value: \(a.value == b.value)")
        print("a == b: \(a == b)")
        XCTAssert(a == b)
    }
    
    func testRandomData() {
        for i in 0 ..< 10 {
            print(i)
        
            var set = PersistentHashSet<Int32>()
            var hashset = Set<Int32>()
        
            let n = randomSize()
        
            print("n: \(n)")
            
            var storedMaps = [(PersistentHashSet<Int32>, Int)]()
        
            for _ in 0 ..< n {
                let key = randomInt()
                
                if randomBool() {
                    set = set.plus(key)
                } else {
                    set.add(key)
                }
                
                hashset.insert(key)
                
                if randomBool(10_000) {
                    storedMaps.append((set, set.count))
                }
        
//                    if ((idx + 1) % 1000 == 0)
//                    {
//                        print(idx + 1)
//                    }
            }
        
            print("MAX: \(Max), hashset size: \(hashset.count), set size: \(set.count)")
        
            XCTAssert(hashset.count == set.count)
        
            checkEqual(hashset, set)
            checkEqual(set, hashset)
            checkListEquality(set, hashset)
            checkEqualityOperator(set, hashset)
            
            print("Checking stored set sanity...")
            
            for (set, size) in storedMaps {
                print("set of size \(size)")
                
                XCTAssert(set.count == size)
                
                var n = 0
                for _ in set {
                    n += 1
                }
                
                XCTAssert(n == size)
            }
            
            print("...finshed checking stored set sanity.")
        
            print("equal - \(i)")
            
            //checkInequality(set, hashset, randomInt)
        }
    }

    func testLow8BitsRandomDataWithRemoval() {
        randomDataWithRemovalImpl({ () -> Int32 in Int32(randomInt() & 0x000000FF) }, "low 8 bits")
    }

    func testHigh8BitsRandomDataWithRemoval() {
        randomDataWithRemovalImpl({ () -> Int32 in Int32(bitPattern: UInt32(bitPattern: randomInt()) & 0xFF000000) }, "high 8 bits")
    }

    func testLow16BitsRandomDataWithRemoval() {
    randomDataWithRemovalImpl({ () -> Int32 in Int32(randomInt() & 0x0000FFFF) }, "low 16 bits")
    }

    func testMid16BitsRandomDataWithRemoval() {
    randomDataWithRemovalImpl({ () -> Int32 in Int32(randomInt() & 0x00FFFF00) }, "mid 16 bits")
    }

    func testHigh16BitsRandomDataWithRemoval() {
        randomDataWithRemovalImpl({ () -> Int32 in Int32(bitPattern: UInt32(bitPattern: randomInt()) & 0xFFFF0000) }, "high 16 bits")
    }

    func testFullRandomDataWithRemoval() {
        randomDataWithRemovalImpl({ () -> Int32 in randomInt() }, "full")
    }

    func randomDataWithRemovalImpl(_ source: RandomIntSource, _ name: String) {
        for i in 0 ..< 10 {
            print(i)

            var set = PersistentHashSet<Int32>()
            var hashset = Set<Int32>()

            let n = randomSize()

            print("n: \(n)")
            
            var storedMaps = [(PersistentHashSet<Int32>, Int)]()

            var removalCount = 0

            for _ in 0 ..< n {
                let key = source()

                if randomBool() {
                    set = set.plus(key)
                } else {
                    set.add(key)
                }
                
                hashset.insert(key)

                let keyToRemove = (randomBool() ? key : source())

                let sizeBeforeRemoval = set.count
                if hashset.count != sizeBeforeRemoval {
                    XCTFail("Asymmetric adding behavior - set size: \(set.count), hashset size: \(hashset.count)")
                }

                if randomBool() {
                    set = set.minus(keyToRemove)
                } else {
                    set.remove(keyToRemove)
                }
                
                hashset.remove(keyToRemove)

                let sizeAfterRemoval = set.count
                if hashset.count != sizeAfterRemoval {
                    XCTFail("Asymmetric removal behavior - set size: \(set.count), hashset size: \(hashset.count)")
                }

                if sizeAfterRemoval == sizeBeforeRemoval - 1 {
                    removalCount += 1
                } else if sizeAfterRemoval != sizeBeforeRemoval {
                    XCTFail("Unexpected removal behavior - set size: \(set.count), hashset size: \(hashset.count)")
                }
                
                if randomBool(10_000) {
                    storedMaps.append((set, set.count))
                }

//                if ((idx + 1) % 1000 == 0)
//                {
//                    print(idx + 1)
//                }
            }

            print("MAX: \(Max), hashset size: \(hashset.count), set size: \(set.count)")

            print("Items removed: \(removalCount)")

            XCTAssert(hashset.count == set.count)

            checkEqual(hashset, set)
            checkEqual(set, hashset)
            checkListEquality(set, hashset)
            checkEqualityOperator(set, hashset)
            
            print("Checking stored set sanity...")
            
            for (set, size) in storedMaps {
                print("set of size \(size)")
                
                XCTAssert(set.count == size)
                
                var n = 0
                for _ in set {
                    n += 1
                }
                
                XCTAssert(n == size)
            }
            
            print("...finshed checking stored set sanity.")

            print("equal - \(i)")
            
            drain(set)
            
            //checkInequality(set, hashset, source)
        }
    }
    
    func testHighHashCollider() {
        randomObjectsWithRemovalImpl(
            source: { () -> HighHashCollider in HighHashCollider(randomLong()) }, name: "high hash collider", testRemoval: false)
    }

    func testHighHashColliderWithRemoval() {
        randomObjectsWithRemovalImpl(
            source: { () -> HighHashCollider in HighHashCollider(randomLong()) }, name: "high hash collider", testRemoval: true)
    }

    func testLowHashCollider() {
        randomObjectsWithRemovalImpl(
            source: { () -> LowHashCollider in LowHashCollider(randomLong()) }, name: "high hash collider", testRemoval: false)
    }

    func testLowHashColliderWithRemoval() {
        randomObjectsWithRemovalImpl(
            source: { () -> LowHashCollider in LowHashCollider(randomLong()) }, name: "high hash collider", testRemoval: true)
    }
    
    private func randomObjectsWithRemovalImpl<E>(source: () -> E, name: String, testRemoval: Bool) where E: Hashable, E: Comparable {
        for i in 0 ..< 10 {
            print(i)

            var set = PersistentHashSet<E>()
            var hashset = Set<E>()

            let n = randomSize()

            print("n: \(n)")
            
            var storedMaps = [(PersistentHashSet<E>, Int)]()

            var removalCount = 0

            for _ in 0 ..< n {
                let key = source()

                if randomBool() {
                    set = set.plus(key)
                } else {
                    set.add(key)
                }
                
                hashset.insert(key)

                if testRemoval {
                    let keyToRemove = (randomBool() ? key : source())

                    let sizeBeforeRemoval = set.count
                    if hashset.count != sizeBeforeRemoval {
                        XCTFail("Asymmetric adding behavior - set size: \(set.count), hashset size: \(hashset.count)")
                    }
                    
                    if randomBool() {
                        set = set.minus(keyToRemove)
                    } else {
                        set.remove(keyToRemove)
                    }
                    
                    hashset.remove(keyToRemove)

                    let sizeAfterRemoval = set.count
                    if hashset.count != sizeAfterRemoval {
                        XCTFail("Asymmetric removal behavior - set size: \(set.count), hashset size: \(hashset.count)")
                    }

                    if sizeAfterRemoval == sizeBeforeRemoval - 1 {
                        removalCount += 1
                    } else if sizeAfterRemoval != sizeBeforeRemoval {
                        XCTFail("Unexpected removal behavior - set size: \(set.count), hashset size: \(hashset.count)")
                    }
                }
                
                if randomBool(10_000) {
                    storedMaps.append((set, set.count))
                }

//				if ((idx + 1) % 1000 == 0)
//				{
//					print(idx + 1)
//				}
            }

            print("MAX: \(Max), hashset size: \(hashset.count), set size: \(set.count)")
            
            if testRemoval {
                print("Items removed: \(removalCount)")
            }
            
            XCTAssert(hashset.count == set.count)
            
            checkEqual(hashset, set)
            checkEqual(set, hashset)
            checkListEquality(set, hashset)
            checkEqualityOperator(set, hashset)
            
            print("Checking stored set sanity...")
            
            for (set, size) in storedMaps {
                print("set of size \(size)")
                
                XCTAssert(set.count == size)
                
                var n = 0
                for _ in set {
                    n += 1
                }
                
                XCTAssert(n == size)
            }
            
            print("...finshed checking stored set sanity.")
            
            print("equal - \(i)")
            
            drain(set)
            
            //checkInequality(set, hashset, source)
        }
    }

    func checkListEquality<E>(_ set: PersistentHashSet<E>, _ hashset: Set<E>) where E: Comparable {
        var hashsetList = [E](hashset)
        var setList = [E](set)
        
        XCTAssert(setList.count == hashsetList.count)
        XCTAssert(setList.count == set.count)
        XCTAssert(hashsetList.count == hashset.count)
        
        print("Checking list equality of \(set.count) entries...")
        
        defer {
            print("...finished.")
        }
        
        hashsetList.sort()
        setList.sort()

        // TODO use once named tuple comparison and / or mixed tuple comparison works
//        XCTAssert(hashsetList == setList)
//        XCTAssert(setList == hashsetList)

        let size = setList.count
        XCTAssert(hashsetList.count == size)
        for idx in 0 ..< size {
            XCTAssert(setList[idx] == hashsetList[idx], "idx: \(idx)")
        }
    }
    
    private func equal<E>(_ lhs: Set<E>, _ rhs: PersistentHashSet<E>) -> String? {
        if lhs.count != rhs.count {
            return "lhs.count: \(lhs.count), rhs.count: \(rhs.count)"
        }
        
        let size = lhs.count
        
        print("Checking equality of \(size) entries...")
        
        defer {
            print("...finished.")
        }
        
        for entry in lhs {
            if rhs.contains(entry) == false {
                return "Not contained in rhs: \(entry)"
            }
        }
        
        return nil
    }
    
    private func checkEqual<E>(_ lhs: Set<E>, _ rhs: PersistentHashSet<E>) {
        let result = equal(lhs, rhs)
        if let result = result {
            print(result)
            print("hashset size: \(lhs.count), set size: \(rhs.count)")
        }
        XCTAssert(result == nil)
    }
    
    private func equal<E>(_ lhs: PersistentHashSet<E>, _ rhs: Set<E>) -> String? {
        if lhs.count != rhs.count {
            return "lhs.count: \(lhs.count), rhs.count: \(rhs.count)"
        }
        
        let size = lhs.count
        
        print("Checking equality of \(size) entries...")
        
        defer {
            print("...finished.")
        }
        
        for entry in lhs {
            if rhs.contains(entry) == false {
                return "Not contained in rhs: \(entry)"
            }
        }
        
        return nil
    }
    
    private func checkEqual<E>(_ lhs: PersistentHashSet<E>, _ rhs: Set<E>) {
        let result = equal(lhs, rhs)
        if let result = result {
            print(result)
            print("set size: \(lhs.count), hashset size: \(rhs.count)")
        }
        XCTAssert(result == nil)
    }
    
    private func checkEqualityOperator<E>(_ set: PersistentHashSet<E>, _ hashset: Set<E>) {
        let setFromHashset = PersistentHashSet<E>(hashset)
        
        print("Checking setFromHashset == set...")
        
        XCTAssert(setFromHashset == set)
        
        print("Checking set == setFromHashset...")
        
        XCTAssert(set == setFromHashset)
        
        print("done.")
    }
    
    private func checkInequalityOperator<E>(_ set: PersistentHashSet<E>, _ hashset: Set<E>) {
        let setFromHashset = PersistentHashSet<E>(hashset)
        
        print("Checking setFromHashset != set...")
        
        XCTAssert(setFromHashset != set)
        
        print("Checking set != setFromHashset...")
        
        XCTAssert(set != setFromHashset)
        
        print("done.")
    }
    
    // TODO fix - broken for small sets!!!
    private func _checkInequality<E>(_ set: PersistentHashSet<E>, _ hashset: Set<E>, _ source: () -> E) {
        var setCopy = set
        var hashset = hashset
        
        var removedValue: E? = nil
        
        while true {
            let value = source()
            
            if setCopy.contains(value) {
                setCopy.remove(value)
                checkInequalityOperator(setCopy, hashset)
                removedValue = value
                break
            }
        }
        
        while true {
            let value = source()
            
            if value != removedValue && set.contains(value) == false {
                setCopy.add(value)
                XCTAssert(setCopy.count == hashset.count)
                checkInequalityOperator(setCopy, hashset)
                break
            }
        }
        
        while true {
            let value = source()
            
            if hashset.contains(value) {
                hashset.remove(value)
                checkInequalityOperator(set, hashset)
                removedValue = value
                break
            }
        }
        
        while true {
            let value = source()
            
            if value != removedValue && hashset.contains(value) == false {
                hashset.insert(value)
                XCTAssert(set.count == hashset.count)
                checkInequalityOperator(set, hashset)
                break
            }
        }
    }
}

func drain<E>(_ set: PersistentHashSet<E>) {
    if randomBool() {
        drainPersistently(set)
        drainInPlace(set)
    } else {
        drainInPlace(set)
        drainPersistently(set)
    }
}

func drainPersistently<E>(_ set: PersistentHashSet<E>) {
    var set = set
    
    if set.count == 0 {
        return
    }
    
    print("draining persistently set of size \(set.count)")
    
    let sizeBefore = set.count
    var size = sizeBefore
    
    var firstEntry: E?
    var lastEntry: E?
    
    for entry in set {
        set = set.minus(entry)
        
        size -= 1
        
        XCTAssertEqual(set.count, size)
        
        if firstEntry == nil {
            firstEntry = entry
        }
        
        lastEntry = entry
    }
    
    XCTAssertEqual(set.count, 0)
    
    set = set.plus(firstEntry!)
    
    XCTAssertEqual(set.count, 1)
    
    if sizeBefore > 1 {
        print("shuffling first, last")
        
        set = set.plus(lastEntry!)
        
        XCTAssertEqual(set.count, 2)
        
        set = set.minus(firstEntry!)
        
        XCTAssertEqual(set.count, 1)
        
        set = set.minus(lastEntry!)
    } else {
        set = set.minus(firstEntry!)
    }
    
    XCTAssertEqual(set.count, 0)
}

func drainInPlace<E>(_ set: PersistentHashSet<E>) {
    var set = set
    
    if set.count == 0 {
        return
    }
    
    print("draining in place set of size \(set.count)")
    
    let sizeBefore = set.count
    var size = sizeBefore
    
    var firstEntry: E?
    var lastEntry: E?
    
    for entry in set {
        set.remove(entry)
        
        size -= 1
        
        XCTAssertEqual(set.count, size)
        
        if firstEntry == nil {
            firstEntry = entry
        }
        
        lastEntry = entry
    }
    
    XCTAssertEqual(set.count, 0)
    
    set.add(firstEntry!)
    
    XCTAssertEqual(set.count, 1)
    
    if sizeBefore > 1 {
        print("shuffling first, last")
        
        set.add(lastEntry!)
        
        XCTAssertEqual(set.count, 2)
        
        set.remove(firstEntry!)
        
        XCTAssertEqual(set.count, 1)
        
        set.remove(lastEntry!)
    } else {
        set.remove(firstEntry!)
    }
    
    XCTAssertEqual(set.count, 0)
}
