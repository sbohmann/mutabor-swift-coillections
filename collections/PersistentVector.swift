
import Foundation

private let DEBUG = false

private class Node<E> {
    let level: Int
    
    init(level: Int) {
        self.level = level
    }
    
    func get(idx: Int) -> E { fatalError() }
    
    func with(idx: Int, value: E) -> Node { fatalError() }
    
    func set(idx: Int, value: E) { fatalError() }
    
    func size() -> Int { fatalError() }
    
    func isFull() -> Bool { fatalError() }
    
    func plus(value: E) -> Node? { fatalError() }
    
    func add(value: E) -> Bool { fatalError() }
    
    func plus(valueNode: ValueNode<E>) -> Node? { fatalError() }
    
    func withoutLast() -> Node? { fatalError() }
    
    func removeLast() -> Bool { fatalError() }
}

private func == <E: Equatable>(lhs: Node<E>, rhs: Node<E>) -> Bool {
    return false
}

private final class TreeNode<E> : Node<E> {
    var nodes: [Node<E>]
    var size_: Int
    
    private init(level: Int, nodes: [Node<E>], size: Int) {
        self.nodes = nodes
        
        if nodes.count == 0 {
            fatalError("Attempt to create an empty TreeNode")
        }
        
        self.size_ = size
        
        super.init(level: level)
    }
    
    init(level: Int, subNode: Node<E>) {
        let nodes = [subNode]
        
        self.nodes = nodes
        self.size_ = subNode.size()
        
        if self.size_ == 0 {
            fatalError("Attempt to create an empty TreeNode")
        }
        
        super.init(level: level)
    }
    
    init(lhs: Node<E>, rhs: E) {
        if lhs.isFull() == false {
            fatalError("lhs node is not full")
        }
        
        let nodes = [lhs, createNodeForValue(level: lhs.level, value: rhs)]
        
        self.nodes = nodes
        self.size_ = lhs.size() + 1
        
        if self.size_ == 0 {
            fatalError("Attempt to create an empty TreeNode")
        }
        
        super.init(level: lhs.level + 1)
    }
    
    init(lhs: Node<E>, rhs: ValueNode<E>) {
        if lhs.isFull() == false {
            fatalError("lhs node is not full")
        }
        
        let nodes = [lhs, createNodeForValueNode(level: lhs.level, valueNode: rhs)]
        
        self.nodes = nodes
        self.size_ = lhs.size() + rhs.size()
        
        if self.size_ == 0 {
            fatalError("Attempt to create an empty TreeNode")
        }
        
        super.init(level: lhs.level + 1)
    }
    
    override func get(idx: Int) -> E {
        var idx = idx
        
        if idx >= 0 && idx < size_ {
            for node in nodes {
                if idx < node.size() {
                    return node.get(idx: idx)
                } else {
                    idx -= node.size()
                }
            }
        }
        
        fatalError("Logical error in TreeNode")
    }
    
    override func with(idx: Int, value: E) -> TreeNode {
        var idx = idx
        
        if idx >= 0 && idx < size_ {
            for nodeIdx in 0 ..< nodes.count {
                let node = nodes[nodeIdx]
                
                if idx < node.size() {
                    let newNode = node.with(idx: idx, value: value)
                    
                    if newNode !== node {
                        var newNodes = nodes
                        newNodes[nodeIdx] = newNode
                        return TreeNode(level: level, nodes: newNodes, size: size_)
                    } else {
                        return self
                    }
                } else {
                    idx -= node.size()
                }
            }
        }
        
        fatalError("Logical error in TreeNode")
    }
    
    override func set(idx: Int, value: E) {
        var idx = idx
        
        if idx >= 0 && idx < size_ {
            for nodeIdx in 0 ..< nodes.count {
                let unshared = isKnownUniquelyReferenced(&nodes[nodeIdx])
                
                let node = nodes[nodeIdx]
                
                if idx < node.size() {
                    if unshared {
                        node.set(idx: idx, value: value)
                    } else {
                        let newNode = node.with(idx: idx, value: value)
                        
                        if newNode !== node {
                            nodes[nodeIdx] = newNode
                        }
                    }
                    
                    return
                } else {
                    idx -= node.size()
                }
            }
        }
        
        fatalError("Logical error in TreeNode")
    }
    
    override func size() -> Int {
        return size_
    }
    
    override func isFull() -> Bool {
        return nodes.count == MAX_NODE_CHILDREN && nodes[nodes.count - 1].isFull()
    }
    
    override func plus(value: E) -> Node<E>? {
        // attempt to replace the last sub-node
        if nodes.count > 0 {
            let lastSubnode = nodes[nodes.count - 1]
            
            let lastSubnodeReplacement = lastSubnode.plus(value: value)
            
            if let lastSubnodeReplacement = lastSubnodeReplacement {
                var newNodes = nodes
                newNodes[nodes.count - 1] = lastSubnodeReplacement
                
                return TreeNode(level: level, nodes: newNodes, size: size_ + 1)
            }
        }
        
        // attempt to add a new sub-node
        if nodes.count < MAX_NODE_CHILDREN {
            var newNodes = nodes
            newNodes.append(createNodeForValue(level: level - 1, value: value))
            
            return TreeNode(level: level, nodes: newNodes, size: size_ + 1)
        }
        
        // this node is full
        return nil
    }
    
    override func add(value: E) -> Bool {
        // attempt to replace the last sub-node
        if nodes.count > 0 {
            let unshared = isKnownUniquelyReferenced(&nodes[nodes.count - 1])
            
            let lastSubnode = nodes[nodes.count - 1]
            
            if unshared {
                if lastSubnode.add(value: value) {
                    size_ += 1
                    
                    return true
                }
            } else {
                let lastSubnodeReplacement = lastSubnode.plus(value: value)
                
                if let lastSubnodeReplacement = lastSubnodeReplacement {
                    nodes[nodes.count - 1] = lastSubnodeReplacement
                    
                    return true
                }
            }
        }
        
        // attempt to add a new sub-node
        if nodes.count < MAX_NODE_CHILDREN {
            nodes.append(createNodeForValue(level: level - 1, value: value))
            
            size_ += 1
            
            return true
        }
        
        // this node is full
        return false
    }
    
    override func plus(valueNode: ValueNode<E>) -> TreeNode? {
        // attempt to replace the last sub-node
        if nodes.count > 0 {
            let lastSubnode = nodes[nodes.count - 1]
            
            let lastSubnodeReplacement = lastSubnode.plus(valueNode: valueNode)
            
            // if the last sub-node is not full and thus could create a replacement node...
            if let lastSubnodeReplacement = lastSubnodeReplacement {
                var newNodes = nodes
                newNodes[nodes.count - 1] = lastSubnodeReplacement
                
                return TreeNode(level: level, nodes: newNodes, size: size_ + valueNode.size())
            }
        }
        
        // attempt to add a new sub-node
        if nodes.count < MAX_NODE_CHILDREN {
            var newNodes = nodes
            newNodes.append(createNodeForValueNode(level: level - 1, valueNode: valueNode))
            
            return TreeNode(level: level, nodes: newNodes, size: size_ + valueNode.size())
        }
        
        // this node is full
        return nil
    }
    
    override func withoutLast() -> TreeNode? {
        let lastSubnode = nodes[nodes.count - 1]
        
        let lastSubnodeReplacement = lastSubnode.withoutLast()
        
        if let lastSubnodeReplacement = lastSubnodeReplacement {
            var newNodes = nodes
            newNodes[nodes.count - 1] = lastSubnodeReplacement
            
            if lastSubnodeReplacement.size() != lastSubnode.size() - 1 {
                fatalError("Logical error - subnode of size \(lastSubnode.size()) returned null on withoutLast")
            }
            
            return TreeNode(level: level, nodes: newNodes, size: size_ - 1)
        } else {
            if nodes.count == 1 {
                return nil
            } else {
                var newNodes = nodes
                newNodes.removeLast()
                
                if lastSubnode.size() != 1 {
                    fatalError("Logical error - subnode of size \(lastSubnode.size()) returned null on withoutLast")
                }
                
                return TreeNode(level: level, nodes: newNodes, size: size_ - 1)
            }
        }
    }
    
    override func removeLast() -> Bool {
        let unshared = isKnownUniquelyReferenced(&nodes[nodes.count - 1])
        
        let lastSubnode = nodes[nodes.count - 1]
        
        if unshared {
            if lastSubnode.removeLast() == false {
                nodes.removeLast()
            }
            
            size_ -= 1
            
            return size_ > 0
        } else {
            let lastSubnodeReplacement = lastSubnode.withoutLast()
            
            if let lastSubnodeReplacement = lastSubnodeReplacement {
                nodes[nodes.count - 1] = lastSubnodeReplacement
                
                if lastSubnodeReplacement.size() != lastSubnode.size() - 1 {
                    fatalError("Logical error - subnode of size \(lastSubnode.size()) returned null on withoutLast")
                }
                
                size_ -= 1
                
                return true
            } else {
                if nodes.count == 1 {
                    return false
                } else {
                    nodes.removeLast()
                    
                    if lastSubnode.size() != 1 {
                        fatalError("Logical error - subnode of size \(lastSubnode.size()) returned null on withoutLast")
                    }
                    
                    size_ -= 1
                    
                    return true
                }
            }
        }
    }
}

private final class ValueNode<E> : Node<E> {
    var data: [E]
    
    init(data: [E]) {
        if data.count > MAX_NODE_CHILDREN {
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
    
    override func with(idx: Int, value: E) -> ValueNode {
        if idx < data.count {
            var newData = data
            newData[idx] = value
            return ValueNode(data: newData)
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
    
    override func size() -> Int {
        return data.count
    }
    
    override func isFull() -> Bool {
        return data.count == MAX_NODE_CHILDREN
    }
    
    override func plus(value: E) -> Node<E>? {
        // attempt to add a new value
        if data.count <  MAX_NODE_CHILDREN {
            var newData = data
            newData.append(value)
            
            return ValueNode(data: newData)
        }
        
        // this node is full
        return nil
    }
    
    override func add(value: E) -> Bool {
        // attempt to add a new value
        if data.count <  MAX_NODE_CHILDREN {
            data.append(value)
            
            return true
        }
        
        // this node is full
        return false
    }
    
    override func plus(valueNode: ValueNode) -> Node<E>? {
        if data.count == 0 {
            return valueNode
        } else if data.count == MAX_NODE_CHILDREN {
            return nil
        } else {
            fatalError("Logical error in ValueNode")
        }
    }
    
    override func withoutLast() -> Node<E>? {
        if data.count == 1 {
            return nil
        } else {
            var newData = data
            newData.removeLast()
            
            return ValueNode(data: newData)
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

private func createNodeForValue<E>(level: Int, value: E) -> Node<E> {
    if level > 0 {
        return TreeNode(level: level, subNode: createNodeForValue(level: level - 1, value: value))
    } else if level == 0 {
        return ValueNode(value: value)
    } else {
        fatalError("Logical error in createNodeForValue")
    }
}

private func createNodeForValueNode<E>(level: Int, valueNode: ValueNode<E>) -> Node<E> {
    if level > 1 {
        return TreeNode(level: level, subNode: createNodeForValueNode(level: level - 1, valueNode: valueNode))
    } else if level == 1 {
        return TreeNode(level: level, subNode: valueNode)
    } else if level == 0 {
        return valueNode
    } else {
        fatalError("Logical error in createNodeForValue")
    }
}

public struct VectorIterator<E> : IteratorProtocol {
    private var path = [TreeNode<E>?](repeating: nil, count: 7)
    private var pathIdx = [Int8](repeating: 0, count: 7)
    private var pathSize = 0
    
    private var finished = false
    
    private var valueNode: ValueNode<E>?
    
    private var valueIdx = 0
    
    fileprivate init() {
        finished = true
    }
    
    fileprivate init(root: Node<E>) {
        var node = root
        
        while node.size() != 0 {
            if let treeNode = node as? TreeNode {
                path[pathSize] = treeNode
                pathIdx[pathSize] = 0
                pathSize += 1
                
                node = treeNode.nodes[0]
            } else if let valueNode = node as? ValueNode {
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
                        
                        while let treeNode = newSubnode as? TreeNode {
                            idx += 1
                            path[idx] = treeNode
                            pathIdx[idx] = 0
                            
                            newSubnode = treeNode.nodes[0]
                        }
                        
                        valueNode = (newSubnode as! ValueNode)
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

//, Indexable
public struct PersistentVector<E>: Sequence, CustomStringConvertible {
    typealias ElementType = E
    
    fileprivate var root: Node<E>?
    
    private init(root: Node<E>?) {
        self.root = root
    }
    
    public init() {
        root = nil
    }
    
    // TODO fix once possible
    // TODO replace == E with ": E" if possible
    public init<S: Sequence>(seq: S) where S.Iterator.Element == E {
        root = nil
        
        var buffer = [E]()
        
        for value in seq {
            if buffer.count < MAX_NODE_CHILDREN {
                buffer.append(value)
            } else {
                let valueNode = ValueNode<E>(data: buffer)
                
                if let root = self.root {
                    var newRoot = root.plus(valueNode: valueNode)
                    
                    if newRoot == nil {
                        newRoot = TreeNode(lhs: root, rhs: valueNode)
                    }
                    
                    self.root = newRoot
                } else {
                    self.root = valueNode
                }
                
                buffer = [ value ]
            }
        }
        
        if buffer.count > 0 {
            let valueNode = ValueNode<E>(data: buffer)
            
            if let root = root {
                self.root = root.plus(valueNode: valueNode)
            } else {
                self.root = valueNode
            }
        }
    }
    
    public func get(_ idx: Int) -> E {
        if let root = root {
            if idx >= 0 && idx < root.size() {
                return root.get(idx: idx)
            }
        }
        
        fatalError("Vector access out of range - index: \(idx), size: \(count)")
    }
    
    public func with(_ idx: Int, value: E) -> PersistentVector {
        if let root = root {
            if idx >= 0 && idx < root.size() {
                return PersistentVector(root: root.with(idx: idx, value: value))
            }
        }
        
        fatalError("Vector access out of range - index: \(idx), size: \(count)")
    }
    
    public mutating func set(_ idx: Int, value: E) {
        let unshared = isKnownUniquelyReferenced(&root)
        
        if let root = root {
            if idx >= 0 && idx < root.size() {
                if unshared {
                    root.set(idx: idx, value: value)
                } else {
                    self.root = root.with(idx: idx, value: value)
                }
                
                return
            }
        }
        
        fatalError("Vector access out of range - index: \(idx), size: \(count)")
    }
    
    public func plus(_ value: E) -> PersistentVector {
        if let root = root {
            if root.size() == Int.max {
                fatalError("Size already at Int.max")
            }
            
            let newRoot = root.plus(value: value)
            
            if let newRoot = newRoot {
                return PersistentVector(root: newRoot)
            } else {
                return PersistentVector(root: TreeNode(lhs: root, rhs: value))
            }
        } else {
            return PersistentVector(root: ValueNode(data: [ value ]))
        }
    }
    
    public mutating func add(_ value: E) {
        let unshared = isKnownUniquelyReferenced(&root)
        
        if let root = root {
            if root.size() == Int.max {
                fatalError("Size already at Int.max")
            }
            
            if unshared {
                if root.add(value: value) == false {
                    self.root = TreeNode(lhs: root, rhs: value)
                }
            } else {
                let newRoot = root.plus(value: value)
                
                if let newRoot = newRoot {
                    self.root = newRoot
                } else {
                    self.root = TreeNode(lhs: root, rhs: value)
                }
            }
        } else {
            root = ValueNode(data: [ value ])
        }
    }
    
    public func withoutLast() -> PersistentVector {
        if let root = root {
            return PersistentVector(root: root.withoutLast())
        } else {
            fatalError("Vector is empty")
        }
    }
	
	public mutating func removeLast() {
        let unshared = isKnownUniquelyReferenced(&root)
        
        if let root = root {
            if unshared {
                if root.removeLast() == false {
                    self.root = nil
                    
                    return
                }
            } else {
                self.root = root.withoutLast()
            }
        } else {
            fatalError("Vector is empty")
        }
	}
	
    public var count: Int {
        get {
            if let root = root {
                return root.size()
            } else {
                return 0
            }
        }
    }
    
    public var description : String {
        get {
            var result: String = "List ["
            var first = true
            for element in self {
                result += (first ? " " : ", ")
                result += "\(element)"
                first = false
            }
            result += " ]"
            
            return result
        }
    }
    
    public func makeIterator() -> VectorIterator<E> {
        if let root = root {
            return VectorIterator<E>(root: root)
        } else {
            return VectorIterator<E>()
        }
    }
    
    public var depth: Int {
        get {
            if let root = root {
                return root.level + 1
            } else {
                return 0
            }
        }
    }
}

extension PersistentVector where E: Hashable {
	public var hashValue: Int {
		get {
            NSLog("Fetching hashvalue from vector of size \(count)")
            
            var result = count
            
            for element in self {
                result = result &* ReasonablePrime
                result = result &+ element.hashValue
            }
            
            return result
		}
	}
}

extension PersistentVector where E : Equatable {
    
    public static func == (lhs: PersistentVector, rhs: PersistentVector) -> Bool {
        if lhs.count != rhs.count {
            return false
        }
        
        // TODO simplify to
        // return lhs.root == rhs.root
        // once constrained extensions with protocol conformance are possible,
        // i.e. when PersistentVector can conform to Equatable where E: Equatable
        
        if let lhsRoot = lhs.root, let rhsRoot = rhs.root {
            return lhsRoot == rhsRoot
        } else {
            return lhs.root == nil && rhs.root == nil
        }
    }
    
    public static func != (lhs: PersistentVector, rhs: PersistentVector) -> Bool {
        return (lhs == rhs) == false
    }
}
