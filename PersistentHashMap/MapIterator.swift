public struct MapIterator<K: Hashable, V> : IteratorProtocol {
    private var path = [PHMTreeNode<K, V>?](repeating: nil, count: maximumDepth)
    private var pathIdx = [Int?](repeating: nil, count: maximumDepth)
    private var pathSize = 0
    
    private var finished = false
    
    private var valueNode: PHMNode<K, V>?
    private var valueIdx = 0
    
    init(map: PersistentHashMap<K, V>) {
        if map.root == nil {
            finished = true
            return
        }
        
        var node = map.root
        
        while true {
            if let treeNode = node as? PHMTreeNode {
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
            
            if let entryNode = valueNode as? PHMEntryNode {
                result = entryNode.entry
                valueNodeLength = 1
            } else {
                let multiNode = valueNode as! PHMMultiNode
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
                            
                            while newSubnode is PHMTreeNode {
                                let treeNode = newSubnode as! PHMTreeNode
                                
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
