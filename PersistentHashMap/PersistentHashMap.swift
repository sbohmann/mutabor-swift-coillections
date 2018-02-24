import Foundation

// : CollectionType, Indexable, SequenceType, DictionaryLiteralConvertible
public struct PersistentHashMap<K: Hashable, V> : Sequence, CustomStringConvertible, ExpressibleByDictionaryLiteral {
    public func makeIterator() -> MapIterator<K, V> {
        return MapIterator<K, V>(map: self)
    }
    
    public func foreach(_ function: ((K, V) -> Void)) {
        if let root = root {
            root.foreach(function: function)
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
                root = PHMEntryNode(shift: 0, entry: entry, hash: entry.0.hashValue)
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
                root = PHMEntryNode(shift: 0, entry: entry, hash: entry.0.hashValue)
            }
        }
    }
    
    private init(root: PHMNode<K, V>?) {
        self.root = root
    }
    
    public var count: Int {
        if let root = root {
            return root.size
        } else {
            return 0
        }
    }
    
    public var description: String {
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
            root = PHMEntryNode(shift: 0, entry: entry, hash: entry.0.hashValue)
        }
    }

    public func with(_ key: K, value: V) -> PersistentHashMap {
        return with((key, value))
    }
    
    public func with(_ entry: (K, V)) -> PersistentHashMap {
        if let root = root {
            return PersistentHashMap(root: root.with(entry: entry, hash: entry.0.hashValue))
        } else {
            return PersistentHashMap(root: PHMEntryNode(shift: 0, entry: entry, hash: entry.0.hashValue))
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
    
    var root: PHMNode<K, V>?
}

private func eqo<K, V: Equatable>(lhs: PHMNode<K, V>?, rhs: PHMNode<K, V>?) -> Bool {
    if let lhsNode = lhs, let rhsNode = rhs {
        return eq(lhs: lhsNode, rhs: rhsNode)
    } else {
        return lhs == nil && rhs == nil
    }
}

private func eq<K, V: Equatable>(lhs: PHMNode<K, V>, rhs: PHMNode<K, V>) -> Bool {
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
    
    if let lhsTreeNode = lhs as? PHMTreeNode<K, V>, let rhsTreeNode = rhs as? PHMTreeNode<K, V> {
        if lhsTreeNode.nodes.count != rhsTreeNode.nodes.count {
            return false
        }
        
        for idx in 0 ..< lhsTreeNode.nodes.count {
            if eqo(lhs: lhsTreeNode.nodes[idx], rhs: rhsTreeNode.nodes[idx]) == false {
                return false
            }
        }
        
        return true
    } else if lhs is PHMTreeNode || rhs is PHMTreeNode {
        if size != 1 {
            return false
        } else {
            return singleEntry(node: lhs) == singleEntry(node: rhs)
        }
    } else if let lhsMultiNode = lhs as? PHMMultiNode, let rhsMultiNode = rhs as? PHMMultiNode {
        if lhsMultiNode.data.count != rhsMultiNode.data.count {
            return false
        }
        
        for idx in 0 ..< lhsMultiNode.data.count {
            if arrayContains(array: rhsMultiNode.data, value: lhsMultiNode.data[idx]) == false {
                return false
            }
        }
        
        return true
    } else if lhs is PHMMultiNode || rhs is PHMMultiNode {
        fatalError("Logical error: one of two nodes is a MultiNode - " +
            "sizes \(lhs.size), \(rhs.size), lhs is \(type(of: lhs)), rhs is \(type(of: rhs))")
    } else if let lhsEntryNode = lhs as? PHMEntryNode, let rhsEntryNode = rhs as? PHMEntryNode {
        return lhsEntryNode.entry == rhsEntryNode.entry
    } else {
        fatalError("Logical error: unexpected combination of node types - " +
            "sizes \(lhs.size), \(rhs.size), lhs is \(type(of: lhs)), rhs is \(type(of: rhs))")
    }
}

private func singleEntry<K, V>(node: PHMNode<K, V>) -> (K, V) {
    if node.size != 1 {
        fatalError("node size != 1")
    }
    
    if let treeNode = node as? PHMTreeNode {
        var subnode: PHMNode<K, V>? = nil
        
        for candidate in treeNode.nodes where candidate != nil {
            subnode = candidate
            break
        }
        
        return singleEntry(node: subnode!)
    } else if let multiNode = node as? PHMMultiNode {
        var entry: (K, V)? = nil
        
        for candidate in multiNode.data {
            entry = candidate
            
            break
        }
        
        return entry!
    } else if let entryNode = node as? PHMEntryNode {
        return entryNode.entry
    } else {
        fatalError("Unknown node type: \(type(of: node))")
    }
}

private func arrayContains<K: Equatable, V: Equatable>(array: [(K, V)], value: (K, V)) -> Bool {
    for element in array where element == value {
        return true
    }
    
    return false
}

public func == <K, V: Equatable>(lhs: PersistentHashMap<K, V>, rhs: PersistentHashMap<K, V>) -> Bool {
    return eqo(lhs: lhs.root, rhs: rhs.root)
}

public func != <K, V: Equatable>(lhs: PersistentHashMap<K, V>, rhs: PersistentHashMap<K, V>) -> Bool {
    return eqo(lhs: lhs.root, rhs: rhs.root) == false
}
