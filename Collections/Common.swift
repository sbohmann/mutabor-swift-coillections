import Foundation

let reasonablePrime = 92821

let shiftPerLevel = 5
let maximumSubNodes = 1 << shiftPerLevel
let hashBits = MemoryLayout<Int>.size * 8

// maximum TreeNode chain length
let maximumDepth = (hashBits + shiftPerLevel - 1) / shiftPerLevel

func sizeForShift(_ shift: Int) -> Int {
    if shift + shiftPerLevel <= hashBits {
        return maximumSubNodes
    } else {
        return 1 << (hashBits - shift)
    }
}

func maskForShift(_ shift: Int) -> Int {
    var numBits = hashBits - shift
    
    if shiftPerLevel < numBits {
        numBits = shiftPerLevel
    }
    
    var result = 0
    for _ in 0 ..< numBits {
        result <<= 1
        result |= 1
    }
    return result
}
