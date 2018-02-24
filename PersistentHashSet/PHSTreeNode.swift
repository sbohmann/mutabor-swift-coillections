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
        if shift >= hashBits {
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
            nodes[idx] = PHSEntryNode(shift: shift + shiftPerLevel, entry: entry, hash: hash)
            
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
            
            newChildren[idx] = PHSEntryNode(shift: shift + shiftPerLevel, entry: entry, hash: hash)
            
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
        for idx in 0 ..< maximumSubNodes {
            if let childNode = nodes[idx] {
                childNode.foreach(function: function)
            }
        }
    }
}

func createTreeNode<E: Hashable>(shift: Int, firstEntry: E, firstHash: Int, secondEntry: E, secondHash: Int) -> PHSTreeNode<E> {
    let mask = maskForShift(shift)
    
    var nodes = [PHSNode<E>?](repeating: nil, count: sizeForShift(shift))
    
    let firstIdx = (firstHash >> shift) & mask
    let firstEntryNode = PHSEntryNode(shift: shift + shiftPerLevel, entry: firstEntry, hash: firstHash)
    nodes[firstIdx] = firstEntryNode
    
    let size: Int
    
    let secondIdx = (secondHash >> shift) & mask
    if secondIdx == firstIdx {
        let combinedNode = firstEntryNode.with(entry: secondEntry, hash: secondHash)
        nodes[secondIdx] = combinedNode
        
        size = combinedNode.size
    } else {
        let secondEntryNode = PHSEntryNode(shift: shift + shiftPerLevel, entry: secondEntry, hash: secondHash)
        nodes[secondIdx] = secondEntryNode
        
        size = 2
    }
    
    return PHSTreeNode(shift: shift, size: size, nodes: nodes)
}
