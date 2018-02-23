
import Foundation

let ReasonablePrime = 92821

let SHIFT_PER_LEVEL = 5
let MAX_NODE_CHILDREN = 1 << SHIFT_PER_LEVEL
let HASH_BITS = MemoryLayout<Int>.size * 8

// maximum TreeNode chain length
let MAX_DEPTH = (HASH_BITS + SHIFT_PER_LEVEL - 1) / SHIFT_PER_LEVEL

func sizeForShift(_ shift: Int) -> Int {
    if shift + SHIFT_PER_LEVEL <= HASH_BITS {
        return MAX_NODE_CHILDREN
    } else {
        return 1 << (HASH_BITS - shift)
    }
}

func maskForShift(_ shift: Int) -> Int {
    var numBits = HASH_BITS - shift
    
    if SHIFT_PER_LEVEL < numBits {
        numBits = SHIFT_PER_LEVEL
    }
    
    var result = 0
    for _ in 0 ..< numBits {
        result <<= 1
        result |= 1
    }
    return result
}
