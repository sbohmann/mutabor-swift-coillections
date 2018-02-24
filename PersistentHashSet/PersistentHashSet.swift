import Foundation

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
    
    public init<S: Sequence>(_ entries: S) where S.Iterator.Element == E {
        initImpl(entries: entries)
    }
    
    private mutating func initImpl<S: Sequence>(entries: S) where S.Iterator.Element == E {
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
        if let root = root {
            return root.size
        } else {
            return 0
        }
    }
    
    public var description: String {
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
    
    var root: PHSNode<E>?
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
        fatalError("Logical error: one of two nodes is a MultiNode - " +
            "sizes \(size), lhs is \(type(of: lhs)), rhs is \(type(of: rhs))")
    } else if let lhsEntryNode = lhs as? PHSEntryNode, let rhsEntryNode = rhs as? PHSEntryNode {
        return lhsEntryNode.entry == rhsEntryNode.entry
    } else {
        fatalError("Logical error: unexpected combination of node types - " +
            "size \(size), lhs is \(type(of: lhs)), rhs is \(type(of: rhs))")
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
