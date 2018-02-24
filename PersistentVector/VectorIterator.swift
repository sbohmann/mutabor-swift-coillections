public struct VectorIterator<E> : IteratorProtocol {
    private var path = [PVTreeNode<E>?](repeating: nil, count: 7)
    private var pathIdx = [Int8](repeating: 0, count: 7)
    private var pathSize = 0
    
    private var finished = false
    
    private var valueNode: PVValueNode<E>?
    
    private var valueIdx = 0
    
    init() {
        finished = true
    }
    
    init(root: PVNode<E>) {
        var node = root
        
        while node.size() != 0 {
            if let treeNode = node as? PVTreeNode {
                path[pathSize] = treeNode
                pathIdx[pathSize] = 0
                pathSize += 1
                
                node = treeNode.nodes[0]
            } else if let valueNode = node as? PVValueNode {
                self.valueNode = valueNode
                valueIdx = 0
                break
            } else {
                fatalError("Unknown node type: \(type(of: node))")
            }
        }
        
        if valueNode == nil || valueNode?.size() == 0 {
            if pathSize != 0 {
                fatalError("Logical error: depth > 1 but empty")
            }
            
            finished = true
        }
    }
    
    public mutating func next() -> E? {
        if finished {
            return nil
        }
        
        let result = valueNode!.data[valueIdx]
        
        valueIdx += 1
        
        if valueIdx == valueNode!.data.count {
            if pathSize > 0 {
                var idx = pathSize - 1
                
                while true {
                    if path[idx] == nil {
                        fatalError("path[\(idx)] is nil for pathSize \(pathSize) - path: \(path)")
                    }
                    
                    if Int(pathIdx[idx]) < path[idx]!.nodes.count - 1 {
                        pathIdx[idx] += 1
                        
                        var newSubnode = path[idx]!.nodes[Int(pathIdx[idx])]
                        
                        while let treeNode = newSubnode as? PVTreeNode {
                            idx += 1
                            path[idx] = treeNode
                            pathIdx[idx] = 0
                            
                            newSubnode = treeNode.nodes[0]
                        }
                        
                        if  let newSubnode = newSubnode as? PVValueNode {
                            valueNode = newSubnode
                        } else {
                            fatalError("Logical error detected")
                        }
                        
                        valueIdx = 0
                        break
                    } else {
                        if idx > 0 {
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
