public struct SetIterator<E: Hashable> : IteratorProtocol {
    private var path = [PHSTreeNode<E>?](repeating: nil, count: maximumDepth)
    private var pathIdx = [Int?](repeating: nil, count: maximumDepth)
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
