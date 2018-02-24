import Foundation

class PHSNode<E: Hashable> {
    var shift: Int
    var size: Int
    
    init(shift: Int, size: Int) {
        if shift >= HASH_BITS + SHIFT_PER_LEVEL {
            fatalError("Creating node with shift \(shift)")
        }
        
        self.shift = shift
        self.size = size
    }
    
    func get(key: E, hash: Int) -> E? { fatalError() }
    
    func get(key: E) -> E? { fatalError() }
    
    func put(entry: E, hash: Int) -> (Bool, PHSNode?) { fatalError() }
    
    func with(entry: E, hash: Int) -> PHSNode { fatalError() }
    
    func remove(key: E, hash: Int) -> Bool { fatalError() }
    
    func without(key: E, hash: Int) -> PHSNode? { fatalError() }
    
    func foreach(function: (E) -> Void) { fatalError() }
}

final class PHSTreeNode<E: Hashable> : PHSNode<E> {
    var nodes: [PHSNode<E>?]
    var mask: Int
    
    init(shift: Int, size: Int, nodes: [PHSNode<E>?]) {
        self.nodes = nodes
        mask = maskForShift(shift)
        super.init(shift: shift, size: size)
        check()
    }
    
    func check() {
        if shift >= HASH_BITS {
            fatalError("Logical error in TreeNode")
        }
    }
    
    override func get(key: E, hash: Int) -> E? {
        let idx = (hash >> shift) & mask
        
        if let node = nodes[idx] {
            return node.get(key: key, hash: hash)
        } else {
            return nil
        }
    }
    
    override func get(key: E) -> E? {
        return get(key: key, hash: key.hashValue)
    }
    
    override func put(entry: E, hash: Int) -> (Bool, PHSNode<E>?) {
        let idx = (hash >> shift) & mask
        
        let unshared = isKnownUniquelyReferenced(&nodes[idx])
        
        if let subnode = nodes[idx] {
            let oldSize = subnode.size
            
            if unshared {
                let (replace, replacement) = subnode.put(entry: entry, hash: hash)
                
                if replace {
                    nodes[idx] = replacement
                }
            } else {
                nodes[idx] = subnode.with(entry: entry, hash: hash)
            }
            
            size += nodes[idx]!.size - oldSize
        } else {
            nodes[idx] = PHSEntryNode(shift: shift + SHIFT_PER_LEVEL, entry: entry, hash: hash)
            
            size += 1
        }
        
        return (false, nil)
    }
    
    override func with(entry: E, hash: Int) -> PHSTreeNode {
        let idx = (hash >> shift) & mask
        
        var newChildren: [PHSNode<E>?]
        
        let newSize: Int
        
        if let subnode = nodes[idx] {
            let newSubnode = subnode.with(entry: entry, hash: hash)
            
            if newSubnode === subnode {
                return self
            }
            
            newChildren = nodes
            
            newChildren[idx] = newSubnode
            
            newSize = size + (newSubnode.size - subnode.size)
        } else {
            newChildren = nodes
            
            newChildren[idx] = PHSEntryNode(shift: shift + SHIFT_PER_LEVEL, entry: entry, hash: hash)
            
            newSize = size + 1
        }
        
        return PHSTreeNode(shift: shift, size: newSize, nodes: newChildren)
    }
    
    override func remove(key: E, hash: Int) -> Bool {
        let idx = (hash >> shift) & mask
        
        let unshared = isKnownUniquelyReferenced(&nodes[idx])
        
        if let subnode = nodes[idx] {
            let oldSize = subnode.size
            let newSize: Int
            
            if unshared {
                if subnode.remove(key: key, hash: hash) {
                    nodes[idx] = nil
                    
                    newSize = 0
                } else {
                    newSize = subnode.size
                }
            } else {
                let newSubnode = subnode.without(key: key, hash: hash)
                
                if newSubnode === subnode {
                    return false
                }
                
                if let newSubnode = newSubnode {
                    nodes[idx] = newSubnode
                    
                    newSize = newSubnode.size
                } else {
                    nodes[idx] = nil
                    
                    newSize = 0
                }
            }
            
            size += newSize - oldSize
            
            if size < 0 {
                fatalError("remove: size < 0: \(size)")
            }
            
            return size == 0
        }
        
        return false
    }
    
    // does not compress a tree when a MultiNode becomes an EntryNode,
    // so a chain of size one treeNodes with one EntryNode at the end
    // can be left. Only compresses the tree when the node size goes to 0.
    override func without(key: E, hash: Int) -> PHSNode<E>? {
        let idx = (hash >> shift) & mask
        
        var newChildren: [PHSNode<E>?]
        
        let newSize: Int
        
        if let subnode = nodes[idx] {
            let newSubnode = subnode.without(key: key, hash: hash)
            
            if newSubnode === subnode {
                return self
            }
            
            if let newSubnode = newSubnode {
                newChildren = nodes
                
                newChildren[idx] = newSubnode
                
                newSize = size + (newSubnode.size - subnode.size)
            } else {
                if size == 1 {
                    return nil
                }
                
                if subnode.size != 1 {
                    fatalError("Logical error: subnode of size \(subnode.size) returned null on without")
                }
                
                newChildren = nodes
                
                newChildren[idx] = nil
                
                newSize = size - 1
            }
        } else {
            return self
        }
        
        return PHSTreeNode(shift: shift, size: newSize, nodes: newChildren)
    }
    
    override func foreach(function: (E) -> Void) {
        for idx in 0 ..< MAX_NODE_CHILDREN {
            if let childNode = nodes[idx] {
                childNode.foreach(function: function)
            }
        }
    }
}

final class PHSEntryNode<E: Hashable> : PHSNode<E> {
    var entry: E
    var hash: Int
    
    init(shift: Int, entry: E, hash: Int) {
        self.entry = entry
        self.hash = hash
        super.init(shift: shift, size: 1)
    }
    
    override func get(key: E, hash: Int) -> E? {
        return get(key: key)
    }
    
    override func get(key: E) -> E? {
        if key == entry {
            return entry
        } else {
            return nil
        }
    }
    
    override func put(entry: E, hash: Int) -> (Bool, PHSNode<E>?) {
        if hash == self.hash && entry == self.entry {
            self.entry = entry
            self.hash = hash
        } else if shift < HASH_BITS {
            return (true, createTreeNode(shift: shift, firstEntry: self.entry, firstHash: self.hash, secondEntry: entry, secondHash: hash))
        } else {
            let data = [self.entry, entry]
            
            return (true, PHSMultiNode(shift: shift, data: data))
        }
        
        return (false, nil)
    }
    
    override func with(entry: E, hash: Int) -> PHSNode<E> {
        if hash == self.hash && entry == self.entry {
            return PHSEntryNode(shift: shift, entry: entry, hash: hash)
        } else if shift < HASH_BITS {
            return createTreeNode(shift: shift, firstEntry: self.entry, firstHash: self.hash, secondEntry: entry, secondHash: hash)
        } else {
            let data = [self.entry, entry]
            
            return PHSMultiNode(shift: shift, data: data)
        }
    }
    
    override func remove(key: E, hash: Int) -> Bool {
        return hash == self.hash && key == self.entry
    }
    
    override func without(key: E, hash: Int) -> PHSNode<E>? {
        if hash != self.hash || key != entry {
            return self
        } else {
            return nil
        }
    }
    
    override func foreach(function: (E) -> Void) {
        function(entry)
    }
}

// does not store the hash because all calls are guaranteed
// to pass the same hash in any case. Comparing would not save time.
// EntryNodes can sit anywhere in the tree above just partial hash absed
// branching, but only the full hash leads to the tree location of
// a MultiNode.
final class PHSMultiNode<E: Hashable> : PHSNode<E> {
    var data: [E]
    
    init(shift: Int, data: [E]) {
        self.data = data
        super.init(shift: shift, size: data.count)
    }
    
    override func get(key: E, hash: Int) -> E? {
        return get(key: key)
    }
    
    override func get(key: E) -> E? {
        for entry in data {
            if key == entry {
                return entry
            }
        }
        
        return nil
    }
    
    override func put(entry newEntry: E, hash: Int) -> (Bool, PHSNode<E>?) {
        for idx in 0 ..< data.count {
            let entry = data[idx]
            
            if newEntry == entry {
                data[idx] = newEntry
                
                return (false, nil)
            }
        }
        
        data.append(newEntry)
        size += 1
        
        return (false, nil)
    }
    
    override func with(entry newEntry: E, hash: Int) -> PHSNode<E> {
        let size = data.count
        
        for idx in 0 ..< size {
            let entry = data[idx]
            
            if newEntry == entry {
                var newData = data
                newData[idx] = newEntry
                
                return PHSMultiNode(shift: shift, data: newData)
            }
        }
        
        var newData = data
        newData.append(newEntry)
        return PHSMultiNode(shift: shift, data: newData)
    }
    
    override func remove(key: E, hash: Int) -> Bool {
        for idx in 0 ..< data.count {
            let entry = data[idx]
            
            if key == entry {
                data.remove(at: idx)
                size -= 1
                
                return size == 0
            }
        }
        
        return false
    }
    
    override func without(key: E, hash: Int) -> PHSNode<E>? {
        let size = data.count
        
        for idx in 0 ..< size {
            let entry = data[idx]
            
            if key == entry {
                if data.count == 1 {
                    return nil
                } else if data.count == 2 {
                    let retainedIndex = (idx + 1) % 2
                    
                    return PHSEntryNode(shift: shift, entry: data[retainedIndex], hash: hash)
                } else {
                    var newData = data
                    newData.remove(at: idx)
                    
                    return PHSMultiNode(shift: shift, data: newData)
                }
            }
        }
        
        return self
    }
    
    override func foreach(function: (E) -> Void) {
        for entry in data {
            function(entry)
        }
    }
}

func createTreeNode<E: Hashable>(shift: Int, firstEntry: E, firstHash: Int, secondEntry: E, secondHash: Int) -> PHSTreeNode<E> {
    let mask = maskForShift(shift)
    
    var nodes = [PHSNode<E>?](repeating: nil, count: sizeForShift(shift))
    
    let firstIdx = (firstHash >> shift) & mask
    let firstEntryNode = PHSEntryNode(shift: shift + SHIFT_PER_LEVEL, entry: firstEntry, hash: firstHash)
    nodes[firstIdx] = firstEntryNode
    
    let size: Int
    
    let secondIdx = (secondHash >> shift) & mask
    if secondIdx == firstIdx {
        let combinedNode = firstEntryNode.with(entry: secondEntry, hash: secondHash)
        nodes[secondIdx] = combinedNode
        
        size = combinedNode.size
    } else {
        let secondEntryNode = PHSEntryNode(shift: shift + SHIFT_PER_LEVEL, entry: secondEntry, hash: secondHash)
        nodes[secondIdx] = secondEntryNode
        
        size = 2
    }
    
    return PHSTreeNode(shift: shift, size: size, nodes: nodes)
}

public struct SetIterator<E: Hashable> : IteratorProtocol {
    private var path = [PHSTreeNode<E>?](repeating: nil, count: MAX_DEPTH)
    private var pathIdx = [Int?](repeating: nil, count: MAX_DEPTH)
    private var pathSize = 0
    
    private var finished = false
    
    private var valueNode: PHSNode<E>?
    private var valueIdx = 0
    
    init(set: PersistentHashSet<E>) {
        if set.root == nil {
            finished = true
            return
        }
        
        var node = set.root
        
        while true {
            if let treeNode = node as? PHSTreeNode {
                var idx = 0
                
                while treeNode.nodes[idx] == nil {
                    idx += 1
                }
                
                path[pathSize] = treeNode
                pathIdx[pathSize] = idx
                pathSize += 1
                
                node = treeNode.nodes[idx]
            } else {
                valueNode = node
                valueIdx = 0
                break
            }
        }
        
        if valueNode == nil || valueNode!.size == 0 {
            if pathSize != 0 {
                fatalError("Logical error: depth > 1 but empty")
            }
            
            finished = true
        }
    }
    
    public mutating func next() -> E? {
        if finished {
            return nil
        } else {
            var result: E
            var valueNodeLength: Int
            
            if let entryNode = valueNode as? PHSEntryNode {
                result = entryNode.entry
                valueNodeLength = 1
            } else {
                let multiNode = valueNode as! PHSMultiNode
                result = multiNode.data[valueIdx]
                valueNodeLength = multiNode.data.count
            }
            
            valueIdx += 1
            
            if valueIdx == valueNodeLength {
                if pathSize > 0 {
                    var idx = pathSize - 1
                    
                    while true {
                        let currentTreeNode = path[idx]!
                        
                        var nextPathIdx = pathIdx[idx]! + 1
                        
                        while nextPathIdx < currentTreeNode.nodes.count && currentTreeNode.nodes[nextPathIdx] == nil {
                            nextPathIdx += 1
                        }
                        
                        if nextPathIdx < currentTreeNode.nodes.count {
                            pathIdx[idx] = nextPathIdx
                            
                            var newSubnode = currentTreeNode.nodes[nextPathIdx]
                            
                            while newSubnode is PHSTreeNode {
                                let treeNode = newSubnode as! PHSTreeNode
                                
                                var nextSubPathIdx = 0
                                
                                while treeNode.nodes[nextSubPathIdx] == nil {
                                    nextSubPathIdx += 1
                                }
                                
                                idx += 1
                                path[idx] = treeNode
                                pathIdx[idx] = nextSubPathIdx
                                pathSize += 1
                                
                                newSubnode = treeNode.nodes[nextSubPathIdx]!
                            }
                            
                            valueNode = newSubnode
                            valueIdx = 0
                            break
                        } else {
                            if idx > 0 {
                                pathSize -= 1
                                path[idx] = nil
                                pathIdx[idx] = 0
                                idx -= 1
                            } else {
                                finished = true
                                path.removeAll()
                                pathIdx.removeAll()
                                break
                            }
                        }
                    }
                } else {
                    finished = true
                    path.removeAll()
                    pathIdx.removeAll()
                }
            }
            
            return result
        }
    }
}

public struct PersistentHashSet<E: Hashable> : Sequence, CustomStringConvertible {
    public func makeIterator() -> SetIterator<E> {
        return SetIterator<E>(set: self)
    }
    
    public func foreach(_ function: ((E) -> Void)) {
        if let root = root {
            root.foreach(function: function)
        } else {
            return
        }
    }
    
    public init() {
        root = nil
    }
    
    public init(arrayLiteral entries: E...) {
        initImpl(entries: entries)
    }
    
    public init<S : Sequence>(_ entries: S) where S.Iterator.Element == E {
        initImpl(entries: entries)
    }
    
    private mutating func initImpl<S : Sequence>(entries: S) where S.Iterator.Element == E {
        root = nil
        
        for entry in entries {
            if let root = root {
                self.root = root.with(entry: entry, hash: entry.hashValue)
            } else {
                root = PHSEntryNode(shift: 0, entry: entry, hash: entry.hashValue)
            }
        }
    }
    
    private init(root: PHSNode<E>?) {
        self.root = root
    }
    
    public var count: Int {
        get {
            if let root = root {
                return root.size
            } else {
                return 0
            }
        }
    }
    
    public var description : String {
        get {
            var result: String = "Set ["
            var first = true
            for element in self {
                result += (first ? " " : ", ")
                result += "\(element)"
                first = false
            }
            result += " ]"
            
            return result
        }
    }
    
    public func contains(_ key: E) -> Bool {
        guard let root = root
        else {
            return false
        }
        
        let entry = root.get(key: key)
        
        return entry != nil
    }
    
    public mutating func add(_ entry: E) {
        let unshared = isKnownUniquelyReferenced(&root)
        
        if let root = root {
            if unshared {
                let (replace, replacement) = root.put(entry: entry, hash: entry.hashValue)
                
                if replace {
                    self.root = replacement
                }
            } else {
                self.root = root.with(entry: entry, hash: entry.hashValue)
            }
        } else {
            root = PHSEntryNode(shift: 0, entry: entry, hash: entry.hashValue)
        }
    }
    
    public func plus(_ entry: E) -> PersistentHashSet {
        if let root = root {
            return PersistentHashSet(root: root.with(entry: entry, hash: entry.hashValue))
        } else {
            return PersistentHashSet(root: PHSEntryNode(shift: 0, entry: entry, hash: entry.hashValue))
        }
    }
    
    public mutating func remove(_ key: E) {
        let unshared = isKnownUniquelyReferenced(&root)
        
        if let root = root {
            if unshared {
                if root.remove(key: key, hash: key.hashValue) {
                    self.root = nil
                }
            } else {
                self.root = root.without(key: key, hash: key.hashValue)
            }
        } else {
            return
        }
    }
    
    public func minus(_ key: E) -> PersistentHashSet {
        if let root = root {
            return PersistentHashSet(root: root.without(key: key, hash: key.hashValue))
        } else {
            return self
        }
    }
    
    fileprivate var root : PHSNode<E>?
}

private func eqo<E>(lhs: PHSNode<E>?, rhs: PHSNode<E>?) -> Bool {
    if let lhsNode = lhs, let rhsNode = rhs {
        return eq(lhs: lhsNode, rhs: rhsNode)
    } else {
        return lhs == nil && rhs == nil
    }
}

private func eq<E>(lhs: PHSNode<E>, rhs: PHSNode<E>) -> Bool {
    if lhs === rhs {
        return true
    }
    
    if lhs.size != rhs.size {
        return false
    }
    
    let size = lhs.size
    
    if lhs.shift != rhs.shift {
        fatalError("shift mismatch: \(lhs.shift) / \(rhs.shift)")
    }
    
    if let lhsTreeNode = lhs as? PHSTreeNode, let rhsTreeNode = rhs as? PHSTreeNode {
        if lhsTreeNode.nodes.count != rhsTreeNode.nodes.count {
            return false
        }
        
        for idx in 0 ..< lhsTreeNode.nodes.count {
            if eqo(lhs: lhsTreeNode.nodes[idx], rhs: rhsTreeNode.nodes[idx]) == false {
                return false
            }
        }
        
        return true
    } else if lhs is PHSTreeNode || rhs is PHSTreeNode {
        if size != 1 {
            return false
        } else {
            return singleEntry(node: lhs) == singleEntry(node: rhs)
        }
    } else if let lhsMultiNode = lhs as? PHSMultiNode, let rhsMultiNode = rhs as? PHSMultiNode {
        if lhsMultiNode.data.count != rhsMultiNode.data.count {
            return false
        }
        
        for idx in 0 ..< lhsMultiNode.data.count {
            if rhsMultiNode.data.contains(lhsMultiNode.data[idx]) == false {
                return false
            }
        }
        
        return true
    } else if lhs is PHSMultiNode || rhs is PHSMultiNode {
        fatalError("Logical error: one of two nodes is a MultiNode - sizes \(size), lhs is \(type(of: lhs)), rhs is \(type(of: rhs))")
    } else if let lhsEntryNode = lhs as? PHSEntryNode, let rhsEntryNode = rhs as? PHSEntryNode {
        return lhsEntryNode.entry == rhsEntryNode.entry
    } else {
        fatalError("Logical error: unexpected combination of node types - size \(size), lhs is \(type(of: lhs)), rhs is \(type(of: rhs))")
    }
}

private func singleEntry<E>(node: PHSNode<E>) -> E {
    if node.size != 1 {
        fatalError("node size != 1")
    }
    
    if let treeNode = node as? PHSTreeNode {
        var subnode: PHSNode<E>? = nil
        
        for candidate in treeNode.nodes {
            if candidate != nil {
                subnode = candidate
                
                break
            }
        }
        
        return singleEntry(node: subnode!)
    } else if let multiNode = node as? PHSMultiNode {
        var entry: E? = nil
        
        for candidate in multiNode.data {
            entry = candidate
            
            break
        }
        
        return entry!
    } else if let entryNode = node as? PHSEntryNode {
        return entryNode.entry
    } else {
        fatalError("Unknown node type: \(type(of: node))")
    }
}

public func == <E>(lhs: PersistentHashSet<E>, rhs: PersistentHashSet<E>) -> Bool {
    return eqo(lhs: lhs.root, rhs: rhs.root)
}

public func != <E>(lhs: PersistentHashSet<E>, rhs: PersistentHashSet<E>) -> Bool {
    return eqo(lhs: lhs.root, rhs: rhs.root) == false
}
