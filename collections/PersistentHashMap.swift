import Foundation

private class Node<K: Hashable, V> {
    var shift: Int
    var size: Int
    
    init(shift: Int, size: Int) {
        if shift >= HASH_BITS + SHIFT_PER_LEVEL {
            fatalError("Creating node with shift \(shift)")
        }
        
        self.shift = shift
        self.size = size
    }
    
    func get(key: K, hash: Int) -> (K, V)? { fatalError() }
    
    func get(key: K) -> (K, V)? { fatalError() }
    
    func put(entry: (K, V), hash: Int) -> (Bool, Node?) { fatalError() }
    
    func with(entry: (K, V), hash: Int) -> Node { fatalError() }
    
    func remove(key: K, hash: Int) -> Bool { fatalError() }
    
    func without(key: K, hash: Int) -> Node? { fatalError() }
    
    func foreach(function: ((K, V)) -> Void) { fatalError() }
}

private final class TreeNode<K: Hashable, V> : Node<K, V> {
    var nodes: [Node<K, V>?]
    var mask: Int
    
    init(shift: Int, size: Int, nodes: [Node<K, V>?]) {
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
    
    override func get(key: K, hash: Int) -> (K, V)? {
        let idx = (hash >> shift) & mask
        
        if let node = nodes[idx] {
            return node.get(key: key, hash: hash)
        } else {
            return nil
        }
    }
    
    override func get(key: K) -> (K, V)? {
        return get(key: key, hash: key.hashValue)
    }
    
    override func put(entry: (K, V), hash: Int) -> (Bool, Node<K, V>?) {
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
            nodes[idx] = EntryNode(shift: shift + SHIFT_PER_LEVEL, entry: entry, hash: hash)
            
            size += 1
        }
        
        return (false, nil)
    }
    
    override func with(entry: (K, V), hash: Int) -> TreeNode {
        let idx = (hash >> shift) & mask
        
        var newChildren: [Node<K, V>?]
        
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
            
            newChildren[idx] = EntryNode(shift: shift + SHIFT_PER_LEVEL, entry: entry, hash: hash)
            
            newSize = size + 1
        }
        
        return TreeNode(shift: shift, size: newSize, nodes: newChildren)
    }
    
    override func remove(key: K, hash: Int) -> Bool {
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
    override func without(key: K, hash: Int) -> Node<K, V>? {
        let idx = (hash >> shift) & mask
        
        var newChildren: [Node<K, V>?]
        
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
        
        return TreeNode(shift: shift, size: newSize, nodes: newChildren)
    }
    
    override func foreach(function: (K, V) -> Void) {
        for idx in 0 ..< MAX_NODE_CHILDREN {
            if let childNode = nodes[idx] {
                childNode.foreach(function: function)
            }
        }
    }
}

private final class EntryNode<K: Hashable, V> : Node<K, V> {
    var entry: (K, V)
    var hash: Int
    
    init(shift: Int, entry: (K, V), hash: Int) {
        self.entry = entry
        self.hash = hash
        super.init(shift: shift, size: 1)
    }
    
    override func get(key: K, hash: Int) -> (K, V)? {
        return get(key: key)
    }
    
    override func get(key: K) -> (K, V)? {
        if key == entry.0 {
            return entry
        } else {
            return nil
        }
    }
    
    override func put(entry: (K, V), hash: Int) -> (Bool, Node<K, V>?) {
        if hash == self.hash && entry.0 == self.entry.0 {
            self.entry = entry
            self.hash = hash
        } else if shift < HASH_BITS {
            return (true, createTreeNode(shift: shift, firstEntry: self.entry, firstHash: self.hash, secondEntry: entry, secondHash: hash))
        } else {
            let data = [self.entry, entry]
            
            return (true, MultiNode(shift: shift, data: data))
        }
        
        return (false, nil)
    }
    
    override func with(entry: (K, V), hash: Int) -> Node<K, V> {
        if hash == self.hash && entry.0 == self.entry.0 {
            return EntryNode(shift: shift, entry: entry, hash: hash)
        } else if shift < HASH_BITS {
            return createTreeNode(shift: shift, firstEntry: self.entry, firstHash: self.hash, secondEntry: entry, secondHash: hash)
        } else {
            let data = [self.entry, entry]
            
            return MultiNode(shift: shift, data: data)
        }
    }
    
    override func remove(key: K, hash: Int) -> Bool {
        return hash == self.hash && key == self.entry.0
    }
    
    override func without(key: K, hash: Int) -> Node<K, V>? {
        if hash != self.hash || key != entry.0 {
            return self
        } else {
            return nil
        }
    }
    
    override func foreach(function: ((K, V)) -> Void) {
        function(entry)
    }
}

// does not store the hash because all calls are guaranteed
// to pass the same hash in any case. Comparing would not save time.
// EntryNodes can sit anywhere in the tree above just partial hash absed
// branching, but only the full hash leads to the tree location of
// a MultiNode.
private final class MultiNode<K: Hashable, V> : Node<K, V> {
    var data: [(K, V)]
    
    init(shift: Int, data: [(K, V)]) {
        self.data = data
        super.init(shift: shift, size: data.count)
    }
    
    override func get(key: K, hash: Int) -> (K, V)? {
        return get(key: key)
    }
    
    override func get(key: K) -> (K, V)? {
        for entry in data {
            if key == entry.0 {
                return entry
            }
        }
        
        return nil
    }
    
    override func put(entry newEntry: (K, V), hash: Int) -> (Bool, Node<K, V>?) {
        for idx in 0 ..< data.count {
            let entry = data[idx]
            
            if newEntry.0 == entry.0 {
                data[idx] = newEntry
                
                return (false, nil)
            }
        }
        
        data.append(newEntry)
        size += 1
        
        return (false, nil)
    }
    
    override func with(entry newEntry: (K, V), hash: Int) -> Node<K, V> {
        let size = data.count
        
        for idx in 0 ..< size {
            let entry = data[idx]
            
            if newEntry.0 == entry.0 {
                var newData = data
                newData[idx] = newEntry
                
                return MultiNode(shift: shift, data: newData)
            }
        }
        
        var newData = data
        newData.append(newEntry)
        return MultiNode(shift: shift, data: newData)
    }
    
    fileprivate override func remove(key: K, hash: Int) -> Bool {
        for idx in 0 ..< data.count {
            let entry = data[idx]
            
            if key == entry.0 {
                data.remove(at: idx)
                size -= 1
                
                return size == 0
            }
        }
        
        return false
    }
    
    override func without(key: K, hash: Int) -> Node<K, V>? {
        let size = data.count
        
        for idx in 0 ..< size {
            let entry = data[idx]
            
            if key == entry.0 {
                if data.count == 1 {
                    return nil
                } else if data.count == 2 {
                    let retainedIndex = (idx + 1) % 2
                    
                    return EntryNode(shift: shift, entry: data[retainedIndex], hash: hash)
                } else {
                    var newData = data
                    newData.remove(at: idx)
                    
                    return MultiNode(shift: shift, data: newData)
                }
            }
        }
        
        return self
    }
    
    override func foreach(function: ((K, V)) -> Void) {
        for entry in data {
            function(entry)
        }
    }
}

private func createTreeNode<K: Hashable, V>(shift: Int, firstEntry: (K, V), firstHash: Int, secondEntry: (K, V), secondHash: Int) -> TreeNode<K, V> {
    let mask = maskForShift(shift)
    
    var nodes = [Node<K, V>?](repeating: nil, count: sizeForShift(shift))
    
    let firstIdx = (firstHash >> shift) & mask
    let firstEntryNode = EntryNode(shift: shift + SHIFT_PER_LEVEL, entry: firstEntry, hash: firstHash)
    nodes[firstIdx] = firstEntryNode
    
    let size: Int
    
    let secondIdx = (secondHash >> shift) & mask
    if secondIdx == firstIdx {
        let combinedNode = firstEntryNode.with(entry: secondEntry, hash: secondHash)
        nodes[secondIdx] = combinedNode
        
        size = combinedNode.size
    } else {
        let secondEntryNode = EntryNode(shift: shift + SHIFT_PER_LEVEL, entry: secondEntry, hash: secondHash)
        nodes[secondIdx] = secondEntryNode
        
        size = 2
    }
    
    return TreeNode(shift: shift, size: size, nodes: nodes)
}

public struct MapIterator<K: Hashable, V> : IteratorProtocol {
    private var path = [TreeNode<K, V>?](repeating: nil, count: MAX_DEPTH)
    private var pathIdx = [Int?](repeating: nil, count: MAX_DEPTH)
    private var pathSize = 0
    
    private var finished = false
    
    private var valueNode: Node<K, V>?
    private var valueIdx = 0
    
    fileprivate init(map: PersistentHashMap<K, V>) {
        if map.root == nil {
            finished = true
            return
        }
        
        var node = map.root
        
        while true {
            if let treeNode = node as? TreeNode {
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
    
    public mutating func next() -> (K, V)? {
        if finished {
            return nil
        } else {
            var result: (K, V)
            var valueNodeLength: Int
            
            if let entryNode = valueNode as? EntryNode {
                result = entryNode.entry
                valueNodeLength = 1
            } else {
                let multiNode = valueNode as! MultiNode
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
                            
                            while newSubnode is TreeNode {
                                let treeNode = newSubnode as! TreeNode
                                
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

// : CollectionType, Indexable, SequenceType, DictionaryLiteralConvertible
public struct PersistentHashMap<K: Hashable, V> : Sequence, CustomStringConvertible, ExpressibleByDictionaryLiteral {
    public func makeIterator() -> MapIterator<K, V> {
        return MapIterator<K, V>(map: self)
    }
    
    public func foreach(_ f: ((K, V) -> Void)) {
        if let root = root {
            root.foreach(function: f)
        } else {
            return
        }
    }
    
    public init() {
        root = nil
    }
    
    public init(dictionaryLiteral entries: (K, V)...) {
        initImpl(entries: entries)
    }
    
    public init(_ entries: [K: V]) {
        root = nil
        
        for entry in entries {
            if let root = root {
                self.root = root.with(entry: entry, hash: entry.0.hashValue)
            } else {
                root = EntryNode(shift: 0, entry: entry, hash: entry.0.hashValue)
            }
        }
    }
    
    public init<S: Sequence>(_ entries: S) where S.Iterator.Element == (K, V) {
        initImpl(entries: entries)
    }
    
    private mutating func initImpl<S: Sequence>(entries: S) where S.Iterator.Element == (K, V) {
        root = nil
        
        for entry in entries {
            if let root = root {
                self.root = root.with(entry: entry, hash: entry.0.hashValue)
            } else {
                root = EntryNode(shift: 0, entry: entry, hash: entry.0.hashValue)
            }
        }
    }
    
    private init(root: Node<K, V>?) {
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
    
    public var description: String {
        get {
            var result: String = "Map ["
            var first = true
            for entry in self {
                result += (first ? " " : ", ")
                result += "\(entry.0) -> \(entry.1)"
                first = false
            }
            result += " ]"
            
            return result
        }
    }
    
    public func get(_ key: K) -> V? {
        guard let root = root
        else {
            return nil
        }
        
        if let entry = root.get(key: key) {
            return entry.1
        } else {
            return nil
        }
    }
    
    public func containsKey(_ key: K) -> Bool {
        guard let root = root
        else {
            return false
        }
        
        let entry = root.get(key: key)
        
        return entry != nil
    }
    
    public mutating func put(_ key: K, value: V) {
        put((key, value))
    }
    
    public mutating func put(_ entry: (K, V)) {
        let unshared = isKnownUniquelyReferenced(&root)
        
        if let root = root {
            if unshared {
                let (replace, replacement) = root.put(entry: entry, hash: entry.0.hashValue)
                
                if replace {
                    self.root = replacement
                }
            } else {
                self.root = root.with(entry: entry, hash: entry.0.hashValue)
            }
        } else {
            root = EntryNode(shift: 0, entry: entry, hash: entry.0.hashValue)
        }
    }

    public func with(_ key: K, value: V) -> PersistentHashMap {
        return with((key, value))
    }
    
    public func with(_ entry: (K, V)) -> PersistentHashMap {
        if let root = root {
            return PersistentHashMap(root: root.with(entry: entry, hash: entry.0.hashValue))
        } else {
            return PersistentHashMap(root: EntryNode(shift: 0, entry: entry, hash: entry.0.hashValue))
        }
    }
    
    public mutating func remove(_ key: K) {
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
    
    public func without(_ key: K) -> PersistentHashMap {
        if let root = root {
            return PersistentHashMap(root: root.without(key: key, hash: key.hashValue))
        } else {
            return self
        }
    }
    
    fileprivate var root: Node<K, V>?
}

private func eqo<K, V: Equatable>(lhs: Node<K, V>?, rhs: Node<K, V>?) -> Bool {
    if let lhsNode = lhs, let rhsNode = rhs {
        return eq(lhs: lhsNode, rhs: rhsNode)
    } else {
        return lhs == nil && rhs == nil
    }
}

private func eq<K, V: Equatable>(lhs: Node<K, V>, rhs: Node<K, V>) -> Bool {
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
    
    if let lhsTreeNode = lhs as? TreeNode<K, V>, let rhsTreeNode = rhs as? TreeNode<K, V> {
        if lhsTreeNode.nodes.count != rhsTreeNode.nodes.count {
            return false
        }
        
        for idx in 0 ..< lhsTreeNode.nodes.count {
            if eqo(lhs: lhsTreeNode.nodes[idx], rhs: rhsTreeNode.nodes[idx]) == false {
                return false
            }
        }
        
        return true
    } else if lhs is TreeNode || rhs is TreeNode {
        if size != 1 {
            return false
        } else {
            return singleEntry(node: lhs) == singleEntry(node: rhs)
        }
    } else if let lhsMultiNode = lhs as? MultiNode, let rhsMultiNode = rhs as? MultiNode {
        if lhsMultiNode.data.count != rhsMultiNode.data.count {
            return false
        }
        
        for idx in 0 ..< lhsMultiNode.data.count {
            if arrayContains(array: rhsMultiNode.data, value: lhsMultiNode.data[idx]) == false {
                return false
            }
        }
        
        return true
    } else if lhs is MultiNode || rhs is MultiNode {
        fatalError("Logical error: one of two nodes is a MultiNode - sizes \(lhs.size), \(rhs.size), lhs is \(type(of: lhs)), rhs is \(type(of: rhs))")
    } else if let lhsEntryNode = lhs as? EntryNode, let rhsEntryNode = rhs as? EntryNode {
        return lhsEntryNode.entry == rhsEntryNode.entry
    } else {
        fatalError("Logical error: unexpected combination of node types - sizes \(lhs.size), \(rhs.size), lhs is \(type(of: lhs)), rhs is \(type(of: rhs))")
    }
}

private func singleEntry<K, V>(node: Node<K, V>) -> (K, V) {
    if node.size != 1 {
        fatalError("node size != 1")
    }
    
    if let treeNode = node as? TreeNode {
        var subnode: Node<K, V>? = nil
        
        for candidate in treeNode.nodes {
            if candidate != nil {
                subnode = candidate
                
                break
            }
        }
        
        return singleEntry(node: subnode!)
    } else if let multiNode = node as? MultiNode {
        var entry: (K, V)? = nil
        
        for candidate in multiNode.data {
            entry = candidate
            
            break
        }
        
        return entry!
    } else if let entryNode = node as? EntryNode {
        return entryNode.entry
    } else {
        fatalError("Unknown node type: \(type(of: node))")
    }
}

private func arrayContains<K: Equatable, V: Equatable>(array: [(K, V)], value: (K, V)) -> Bool {
    for element in array {
        if element == value {
            return true
        }
    }
    
    return false
}

public func == <K, V: Equatable>(lhs: PersistentHashMap<K, V>, rhs: PersistentHashMap<K, V>) -> Bool {
    return eqo(lhs: lhs.root, rhs: rhs.root)
}

public func != <K, V: Equatable>(lhs: PersistentHashMap<K, V>, rhs: PersistentHashMap<K, V>) -> Bool {
    return eqo(lhs: lhs.root, rhs: rhs.root) == false
}
