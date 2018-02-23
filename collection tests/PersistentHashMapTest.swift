
import XCTest
import Mutabor

class PersistentHashMapTest: XCTestCase {
    override func setUp() {
        super.setUp()
        
        super.continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBasicAssumptions() {
        XCTAssert(HASH_BITS == 32 || HASH_BITS == 64)
        print("HASH_BITS: \(HASH_BITS)")
        XCTAssert(MemoryLayout<Int>.size == 4 || MemoryLayout<Int>.size == 8)
        XCTAssert(MemoryLayout<Int32>.size == 4)
        XCTAssert(MemoryLayout<Int64>.size == 8)
    }
    
    typealias RandomIntSource = () -> Int32
    
    func testBasicFunctionality() {
        let map = PersistentHashMap<Int, String>()
        
        XCTAssert(0 == map.count)
        
        let map2 = map.with(3, value: "hallo")
        
        XCTAssert(0 == map.count)
        XCTAssert(1 == map2.count)
        XCTAssert("hallo" == map2.get(3))
        XCTAssert(nil == map2.get(2))
        XCTAssert(map2 == map2)
        
        let map3 = map2.with(3, value: "whatever")
        
        XCTAssert(0 == map.count)
        XCTAssert(1 == map2.count)
        XCTAssert("hallo" == map2.get(3))
        XCTAssert(nil == map2.get(2))
        XCTAssert(1 == map3.count)
        XCTAssert("whatever" == map3.get(3))
        XCTAssert(nil == map3.get(2))
        XCTAssert(map2 == map2)
        XCTAssert(map3 == map3)
        XCTAssert(map2 != map3)
        XCTAssert(map3 != map2)
        
        let map4 = map.with(3, value: "hallo").with(3, value: "whatever")
        XCTAssert(map4 == map4)
        XCTAssert(map4 == map3)
        XCTAssert(map3 == map4)
        XCTAssert(map4 != map2)
        XCTAssert(map2 != map4)
        
        var rm = PersistentHashMap<HighHashCollider, Int>()
        print(rm.count)
        rm.put(HighHashCollider(1), value: 2)
        print(rm.count)
        rm.put(HighHashCollider(2), value: 3)
        print(rm.count)
        rm.put(HighHashCollider(2), value: 5)
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
        
            var map = PersistentHashMap<Int32, Int32>()
            var hashmap = [Int32: Int32]()
        
            let n = randomSize()
        
            print("n: \(n)")
            
            var storedMaps = [(PersistentHashMap<Int32, Int32>, Int)]()
        
            for _ in 0 ..< n {
                let key = randomInt()
                let value = randomInt()
                
                if randomBool() {
                    map = map.with(key, value: value)
                } else {
                    map.put(key, value: value)
                }
                
                hashmap[key] = value
                
                if randomBool(10_000) {
                    storedMaps.append((map, map.count))
                }
        
//                    if ((idx + 1) % 1000 == 0)
//                    {
//                        print(idx + 1)
//                    }
            }
        
            print("MAX: \(Max), hashmap size: \(hashmap.count), map size: \(map.count)")
        
            XCTAssert(hashmap.count == map.count)
        
            checkEqual(hashmap, map)
            checkEqual(map, hashmap)
            checkListEquality(map, hashmap)
            checkEqualityOperator(map, hashmap)
            
            print("Checking stored map sanity...")
            
            for (map, size) in storedMaps {
                print("map of size \(size)")
                
                XCTAssert(map.count == size)
                
                var n = 0
                for _ in map {
                    n += 1
                }
                
                XCTAssert(n == size)
            }
            
            print("...finshed checking stored map sanity.")
        
            print("equal - \(i)")
            
            //checkInequality(map, hashmap, randomInt, randomInt)
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

            var map = PersistentHashMap<Int32, Int32>()
            var hashmap = [Int32: Int32]()

            let n = randomSize()

            print("n: \(n)")
            
            var storedMaps = [(PersistentHashMap<Int32, Int32>, Int)]()

            var removalCount = 0

            for _ in 0 ..< n {
                let key = source()
                let value = randomInt()

                if randomBool() {
                    map = map.with(key, value: value)
                } else {
                    map.put(key, value: value)
                }
                
                hashmap[key] = value

                let keyToRemove = (randomBool() ? key : source())

                let sizeBeforeRemoval = map.count
                if hashmap.count != sizeBeforeRemoval {
                    XCTFail("Asymmetric adding behavior - map size: \(map.count), hashmap size: \(hashmap.count)")
                }

                if randomBool() {
                    map = map.without(keyToRemove)
                } else {
                    map.remove(keyToRemove)
                }
                
                hashmap.removeValue(forKey: keyToRemove)

                let sizeAfterRemoval = map.count
                if hashmap.count != sizeAfterRemoval {
                    XCTFail("Asymmetric removal behavior - map size: \(map.count), hashmap size: \(hashmap.count)")
                }

                if (sizeAfterRemoval == sizeBeforeRemoval - 1) {
                    removalCount += 1
                } else if (sizeAfterRemoval != sizeBeforeRemoval) {
                    XCTFail("Unexpected removal behavior - map size: \(map.count), hashmap size: \(hashmap.count)")
                }
                
                if randomBool(UInt32(n / 10 + 1)) {
                    storedMaps.append((map, map.count))
                }

//                if ((idx + 1) % 1000 == 0)
//                {
//                    print(idx + 1)
//                }
            }

            print("MAX: \(Max), hashmap size: \(hashmap.count), map size: \(map.count)")

            print("Items removed: \(removalCount)")

            XCTAssert(hashmap.count == map.count)

            checkEqual(hashmap, map)
            checkEqual(map, hashmap)
            checkListEquality(map, hashmap)
            checkEqualityOperator(map, hashmap)
            
            print("Checking stored map sanity...")
            
            for (map, size) in storedMaps {
                print("map of size \(size)")
                
                XCTAssert(map.count == size)
                
                var n = 0
                for _ in map {
                    n += 1
                }
                
                XCTAssert(n == size)
            }
            
            print("...finshed checking stored map sanity.")

            print("equal - \(i)")
            
            drain(map)
            
            //checkInequality(map, hashmap, source, randomInt)
        }
    }
    
    func testHighHashCollider() {
        randomObjectsWithRemovalImpl(
            keySource: { () -> HighHashCollider in HighHashCollider(randomLong()) }, valueSource: { () -> Int32 in randomInt() }, name: "high hash collider", testRemoval: false)
    }

    func testHighHashColliderWithRemoval() {
        randomObjectsWithRemovalImpl(
            keySource: { () -> HighHashCollider in HighHashCollider(randomLong()) }, valueSource: { () -> Int32 in randomInt() }, name: "high hash collider", testRemoval: true)
    }

    func testLowHashCollider() {
        randomObjectsWithRemovalImpl(
            keySource: { () -> LowHashCollider in LowHashCollider(randomLong()) }, valueSource: { () -> Int32 in randomInt() }, name: "high hash collider", testRemoval: false)
    }

    func testLowHashColliderWithRemoval() {
        randomObjectsWithRemovalImpl(
            keySource: { () -> LowHashCollider in LowHashCollider(randomLong()) }, valueSource: { () -> Int32 in randomInt() }, name: "high hash collider", testRemoval: true)
    }
    
    private func randomObjectsWithRemovalImpl<K, V>(keySource: () -> K, valueSource: () -> V, name: String, testRemoval: Bool) where K: Hashable, K: Comparable, V: Equatable {
        for i in 0 ..< 10 {
            print(i)

            var map = PersistentHashMap<K, V>()
            var hashmap = [K: V]()

            let n = randomSize()

            print("n: \(n)")
            
            var storedMaps = [(PersistentHashMap<K, V>, Int)]()

            var removalCount = 0

            for _ in 0 ..< n {
                let key = keySource()
                let value = valueSource()

                if randomBool() {
                    map = map.with(key, value: value)
                } else {
                    map.put(key, value: value)
                }
                
                hashmap[key] = value

                if (testRemoval) {
                    let keyToRemove = (randomBool() ? key : keySource())

                    let sizeBeforeRemoval = map.count
                    if (hashmap.count != sizeBeforeRemoval) {
                        XCTFail("Asymmetric adding behavior - map size: \(map.count), hashmap size: \(hashmap.count)")
                    }
                    
                    if randomBool() {
                        map = map.without(keyToRemove)
                    } else {
                        map.remove(keyToRemove)
                    }
                    
                    hashmap.removeValue(forKey: keyToRemove)

                    let sizeAfterRemoval = map.count
                    if (hashmap.count != sizeAfterRemoval) {
                        XCTFail("Asymmetric removal behavior - map size: \(map.count), hashmap size: \(hashmap.count)")
                    }

                    if (sizeAfterRemoval == sizeBeforeRemoval - 1) {
                        removalCount += 1
                    } else if (sizeAfterRemoval != sizeBeforeRemoval) {
                        XCTFail("Unexpected removal behavior - map size: \(map.count), hashmap size: \(hashmap.count)")
                    }
                }
                
                if randomBool(UInt32(n / 10 + 1)) {
                    storedMaps.append((map, map.count))
                }

//				if ((idx + 1) % 1000 == 0)
//				{
//					print(idx + 1)
//				}
            }

            print("MAX: \(Max), hashmap size: \(hashmap.count), map size: \(map.count)")
            
            if (testRemoval) {
                print("Items removed: \(removalCount)")
            }
            
            XCTAssert(hashmap.count == map.count)
            
            checkEqual(hashmap, map)
            checkEqual(map, hashmap)
            checkListEquality(map, hashmap)
            checkEqualityOperator(map, hashmap)
            
            print("Checking stored map sanity...")
            
            for (map, size) in storedMaps {
                print("map of size \(size)")
                
                XCTAssert(map.count == size)
                
                var n = 0
                for _ in map {
                    n += 1
                }
                
                XCTAssert(n == size)
            }
            
            print("...finshed checking stored map sanity.")
            
            print("equal - \(i)")
            
            drain(map)
            
            //checkInequality(map, hashmap, keySource, valueSource)
        }
    }

    func checkListEquality<K, V: Equatable>(_ map: PersistentHashMap<K, V>, _ hashmap: [K: V]) where K: Comparable {
        var hashmapList = [(key: K, value: V)](hashmap)
        var mapList = [(K, V)](map)
        
        XCTAssert(mapList.count == hashmapList.count)
        XCTAssert(mapList.count == map.count)
        XCTAssert(hashmapList.count == hashmap.count)
        
        print("Checking list equality of \(map.count) entries...")
        
        defer {
            print("...finished.")
        }
        
        let keyComparator = { (lhs: (K, V), rhs: (K, V)) -> Bool in lhs.0 < rhs.0 }
        
        hashmapList.sort(by: keyComparator)
        mapList.sort(by: keyComparator)

        // TODO use once named tuple comparison and / or mixed tuple comparison works
//        XCTAssert(hashmapList == mapList)
//        XCTAssert(mapList == hashmapList)

        let size = mapList.count
        XCTAssert(hashmapList.count == size)
        for idx in 0 ..< size {
            XCTAssert(mapList[idx].0 == hashmapList[idx].0 && mapList[idx].1 == hashmapList[idx].1, "idx: \(idx)")
        }
    }
    
    private func equal<K, V: Equatable>(_ lhs: [K: V], _ rhs: PersistentHashMap<K, V>) -> String? {
        if (lhs.count != rhs.count) {
            return "lhs.count: \(lhs.count), rhs.count: \(rhs.count)"
        }
        
        let size = lhs.count
        
        print("Checking equality of \(size) entries...")
        
        defer {
            print("...finished.")
        }
        
        for entry in lhs {
            let value = rhs.get(entry.0)
            
            if value == nil {
                return "No value for key \(entry.0) found in rhs"
            }
            
            if value != entry.1 {
                return "Value \(value.debugDescription) from rhs is not equal to value \(entry.1) from lhs"
            }
        }
            
        return nil
    }
        
    private func checkEqual<K, V: Equatable>(_ lhs: [K: V], _ rhs: PersistentHashMap<K, V>) {
        let result = equal(lhs, rhs)
        if let result = result {
            print(result)
            print("hashmap size: \(lhs.count), map size: \(rhs.count)")
        }
        XCTAssert(result == nil)
    }
    
    private func equal<K, V: Equatable>(_ lhs: PersistentHashMap<K, V>, _ rhs: [K: V]) -> String? {
        if (lhs.count != rhs.count) {
            return "lhs.count: \(lhs.count), rhs.count: \(rhs.count)"
        }
        
        let size = lhs.count
        
        print("Checking equality of \(size) entries...")
        
        defer {
            print("...finished.")
        }
        
        for entry in lhs {
            let value = rhs[entry.0]
            
            if value == nil {
                return "No value for key \(entry.0) found in rhs"
            }
            
            if value != entry.1 {
                return "Value \(value.debugDescription) from rhs is not equal to value \(entry.1) from lhs"
            }
        }
        
        return nil
    }
    
    private func checkEqual<K, V: Equatable>(_ lhs: PersistentHashMap<K, V>, _ rhs: [K: V]) {
        let result = equal(lhs, rhs)
        if let result = result {
            print(result)
            print("map size: \(lhs.count), hashmap size: \(rhs.count)")
        }
        XCTAssert(result == nil)
    }
    
    private func checkEqualityOperator<K, V>(_ map: PersistentHashMap<K, V>, _ hashmap: Dictionary<K, V>) where V: Equatable {
        let mapFromHashmap = PersistentHashMap<K, V>(hashmap)
        
        print("Checking mapFromHashmap == map...")
        
        XCTAssert(mapFromHashmap == map)
        
        print("Checking map == mapFromHashmap...")
        
        XCTAssert(map == mapFromHashmap)
        
        print("done.")
    }
    
    private func checkInequalityOperator<K, V>(_ map: PersistentHashMap<K, V>, _ hashmap: Dictionary<K, V>) where V: Equatable {
        let mapFromHashmap = PersistentHashMap<K, V>(hashmap)
        
        print("Checking mapFromHashmap != map...")
        
        XCTAssert(mapFromHashmap != map)
        
        print("Checking map != mapFromHashmap...")
        
        XCTAssert(map != mapFromHashmap)
        
        print("done.")
    }
    
    // TODO fix - broken for small maps!!!
    private func _checkInequality<K, V>(_ map: PersistentHashMap<K, V>, _ hashmap: Dictionary<K, V>, _ keySource: () -> K, _ valueSource: () -> V) where V: Equatable {
        var mapCopy = map
        var hashmap = hashmap
        
        var removedKey: K? = nil
        
        while true {
            let key = keySource()
            
            if mapCopy.containsKey(key) {
                mapCopy.remove(key)
                checkInequalityOperator(mapCopy, hashmap)
                removedKey = key
                break
            }
        }
        
        while true {
            let key = keySource()
            let value = valueSource()
            
            if key != removedKey && map.containsKey(key) == false {
                mapCopy.put(key, value: value)
                XCTAssert(mapCopy.count == hashmap.count)
                checkInequalityOperator(mapCopy, hashmap)
                break
            }
        }
        
        while true {
            let key = keySource()
            
            if hashmap[key] != nil {
                hashmap.removeValue(forKey: key)
                checkInequalityOperator(map, hashmap)
                removedKey = key
                break
            }
        }
        
        while true {
            let key = keySource()
            let value = valueSource()
            
            if key != removedKey && hashmap[key] == nil {
                hashmap[key] = value
                XCTAssert(map.count == hashmap.count)
                checkInequalityOperator(map, hashmap)
                break
            }
        }
    }
}

func drain<K, V>(_ map: PersistentHashMap<K, V>) {
    if randomBool() {
        drainPersistently(map)
        drainInPlace(map)
    } else {
        drainInPlace(map)
        drainPersistently(map)
    }
}

func drainPersistently<K, V>(_ map: PersistentHashMap<K, V>) {
    var map = map
    
    if map.count == 0 {
        return
    }
    
    print("draining persistently map of size \(map.count)")
    
    let sizeBefore = map.count
    var size = sizeBefore
    
    var firstEntry: (K, V)?
    var lastEntry: (K, V)?
    
    for entry in map {
        map = map.without(entry.0)
        
        size -= 1
        
        XCTAssertEqual(map.count, size)
        
        if firstEntry == nil {
            firstEntry = entry
        }
        
        lastEntry = entry
    }
    
    XCTAssertEqual(map.count, 0)
    
    map = map.with(firstEntry!.0, value: firstEntry!.1)
    
    XCTAssertEqual(map.count, 1)
    
    if (sizeBefore > 1) {
        print("shuffling first, last")
        
        map = map.with(lastEntry!.0, value: lastEntry!.1)
        
        XCTAssertEqual(map.count, 2)
        
        map = map.without(firstEntry!.0)
        
        XCTAssertEqual(map.count, 1)
        
        map = map.without(lastEntry!.0)
    } else {
        map = map.without(firstEntry!.0)
    }
    
    XCTAssertEqual(map.count, 0)
}

func drainInPlace<K, V>(_ map: PersistentHashMap<K, V>) {
    var map = map
    
    if map.count == 0 {
        return
    }
    
    print("draining in place map of size \(map.count)")
    
    let sizeBefore = map.count
    var size = sizeBefore
    
    var firstEntry: (K, V)?
    var lastEntry: (K, V)?
    
    for entry in map {
        map.remove(entry.0)
        
        size -= 1
        
        XCTAssertEqual(map.count, size)
        
        if firstEntry == nil {
            firstEntry = entry
        }
        
        lastEntry = entry
    }
    
    XCTAssertEqual(map.count, 0)
    
    map.put(firstEntry!.0, value: firstEntry!.1)
    
    XCTAssertEqual(map.count, 1)
    
    if (sizeBefore > 1) {
        print("shuffling first, last")
        
        map.put(lastEntry!.0, value: lastEntry!.1)
        
        XCTAssertEqual(map.count, 2)
        
        map.remove(firstEntry!.0)
        
        XCTAssertEqual(map.count, 1)
        
        map.remove(lastEntry!.0)
    } else {
        map.remove(firstEntry!.0)
    }
    
    XCTAssertEqual(map.count, 0)
}
