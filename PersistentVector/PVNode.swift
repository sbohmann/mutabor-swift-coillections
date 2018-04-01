class PVNode<E> {
    let level: Int
    
    init(level: Int) {
        self.level = level
    }
    
    func get(idx: Int) -> E { fatalError() }
    
    func with(idx: Int, value: E) -> PVNode { fatalError() }
    
    func set(idx: Int, value: E) { fatalError() }
    
    func getSize() -> Int { fatalError() }
    
    func isFull() -> Bool { fatalError() }
    
    func plus(value: E) -> PVNode? { fatalError() }
    
    func add(value: E) -> Bool { fatalError() }
    
    func plus(valueNode: PVValueNode<E>) -> PVNode? { fatalError() }
    
    func withoutLast() -> PVNode? { fatalError() }
    
    func removeLast() -> Bool { fatalError() }
}

extension PVNode where E : Equatable {
    static func == (lhs: PVNode<E>, rhs: PVNode<E>) -> Bool {
        if let lhsTreeNode = lhs as? PVTreeNode, let rhsTreeNode = rhs as? PVTreeNode
        {
            return lhsTreeNode == rhsTreeNode
        }
        else if let lhsValueNode = lhs as? PVValueNode, let rhsValueNode = rhs as? PVValueNode
        {
            return lhsValueNode == rhsValueNode
        }
        else
        {
            return false
        }
    }
    
    static func != (lhs: PVNode<E>, rhs: PVNode<E>) -> Bool {
        return !(lhs == rhs)
    }
}

func createNodeForValue<E>(level: Int, value: E) -> PVNode<E> {
    if level > 0 {
        return PVTreeNode(level: level, subNode: createNodeForValue(level: level - 1, value: value))
    } else if level == 0 {
        return PVValueNode(value: value)
    } else {
        fatalError("Logical error in createNodeForValue")
    }
}

func createNodeForValueNode<E>(level: Int, valueNode: PVValueNode<E>) -> PVNode<E> {
    if level > 1 {
        return PVTreeNode(level: level, subNode: createNodeForValueNode(level: level - 1, valueNode: valueNode))
    } else if level == 1 {
        return PVTreeNode(level: level, subNode: valueNode)
    } else if level == 0 {
        return valueNode
    } else {
        fatalError("Logical error in createNodeForValue")
    }
}
