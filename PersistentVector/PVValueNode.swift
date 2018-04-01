final class PVValueNode<E> : PVNode<E> {
    var data: [E]
    
    init(data: [E]) {
        if data.count > maximumSubNodes {
            fatalError("data.length > MAX_NODE_CHILDREN")
        }
        
        self.data = data
        
        super.init(level: 0)
    }
    
    init(value: E) {
        self.data = [value]
        
        super.init(level: 0)
    }
    
    override func get(idx: Int) -> E {
        if idx < data.count {
            return data[idx]
        } else {
            fatalError("Logical error in ValueNode")
        }
    }
    
    override func with(idx: Int, value: E) -> PVValueNode {
        if idx < data.count {
            var newData = data
            newData[idx] = value
            return PVValueNode(data: newData)
        } else {
            fatalError("Logical error in ValueNode")
        }
    }
    
    override func set(idx: Int, value: E) {
        if idx < data.count {
            data[idx] = value
        } else {
            fatalError("Logical error in ValueNode")
        }
    }
    
    override func getSize() -> Int {
        return data.count
    }
    
    override func isFull() -> Bool {
        return data.count == maximumSubNodes
    }
    
    override func plus(value: E) -> PVNode<E>? {
        // attempt to add a new value
        if data.count <  maximumSubNodes {
            var newData = data
            newData.append(value)
            
            return PVValueNode(data: newData)
        }
        
        // this node is full
        return nil
    }
    
    override func add(value: E) -> Bool {
        // attempt to add a new value
        if data.count <  maximumSubNodes {
            data.append(value)
            
            return true
        }
        
        // this node is full
        return false
    }
    
    override func plus(valueNode: PVValueNode) -> PVNode<E>? {
        if data.count == 0 {
            return valueNode
        } else if data.count == maximumSubNodes {
            return nil
        } else {
            fatalError("Logical error in ValueNode")
        }
    }
    
    override func withoutLast() -> PVNode<E>? {
        if data.count == 1 {
            return nil
        } else {
            var newData = data
            newData.removeLast()
            
            return PVValueNode(data: newData)
        }
    }
    
    override func removeLast() -> Bool {
        if data.count == 1 {
            return false
        } else {
            data.removeLast()
            
            return true
        }
    }
}

extension PVValueNode where E : Equatable {
    static func == <E: Equatable>(lhs: PVValueNode<E>, rhs: PVValueNode<E>) -> Bool {
        return lhs.data == rhs.data
    }
    
    static func != <E: Equatable>(lhs: PVValueNode<E>, rhs: PVValueNode<E>) -> Bool {
        return lhs.data != rhs.data
    }
}
