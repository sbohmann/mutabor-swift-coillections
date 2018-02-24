final class PHMTreeNode<K: Hashable, V> : PHMNode<K, V> {
    var nodes: [PHMNode<K, V>?]
    var mask: Int
    
    init(shift: Int, size: Int, nodes: [PHMNode<K, V>?]) {
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
    
    override func put(entry: (K, V), hash: Int) -> (Bool, PHMNode<K, V>?) {
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
            nodes[idx] = PHMEntryNode(shift: shift + SHIFT_PER_LEVEL, entry: entry, hash: hash)
            
            size += 1
        }
        
        return (false, nil)
    }
    
    override func with(entry: (K, V), hash: Int) -> PHMTreeNode {
        let idx = (hash >> shift) & mask
        
        var newChildren: [PHMNode<K, V>?]
        
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
            
            newChildren[idx] = PHMEntryNode(shift: shift + SHIFT_PER_LEVEL, entry: entry, hash: hash)
            
            newSize = size + 1
        }
        
        return PHMTreeNode(shift: shift, size: newSize, nodes: newChildren)
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
    override func without(key: K, hash: Int) -> PHMNode<K, V>? {
        let idx = (hash >> shift) & mask
        
        var newChildren: [PHMNode<K, V>?]
        
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
        
        return PHMTreeNode(shift: shift, size: newSize, nodes: newChildren)
    }
    
    override func foreach(function: (K, V) -> Void) {
        for idx in 0 ..< MAX_NODE_CHILDREN {
            if let childNode = nodes[idx] {
                childNode.foreach(function: function)
            }
        }
    }
}

func createPHMTreeNode<K: Hashable, V>(shift: Int, firstEntry: (K, V), firstHash: Int, secondEntry: (K, V), secondHash: Int) -> PHMTreeNode<K, V> {
    let mask = maskForShift(shift)
    
    var nodes = [PHMNode<K, V>?](repeating: nil, count: sizeForShift(shift))
    
    let firstIdx = (firstHash >> shift) & mask
    let firstEntryNode = PHMEntryNode(shift: shift + SHIFT_PER_LEVEL, entry: firstEntry, hash: firstHash)
    nodes[firstIdx] = firstEntryNode
    
    let size: Int
    
    let secondIdx = (secondHash >> shift) & mask
    if secondIdx == firstIdx {
        let combinedNode = firstEntryNode.with(entry: secondEntry, hash: secondHash)
        nodes[secondIdx] = combinedNode
        
        size = combinedNode.size
    } else {
        let secondEntryNode = PHMEntryNode(shift: shift + SHIFT_PER_LEVEL, entry: secondEntry, hash: secondHash)
        nodes[secondIdx] = secondEntryNode
        
        size = 2
    }
    
    return PHMTreeNode(shift: shift, size: size, nodes: nodes)
}

