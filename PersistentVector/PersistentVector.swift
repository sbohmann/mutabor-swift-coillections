import Foundation

private let DEBUG = false

//, Indexable
public struct PersistentVector<E>: Sequence, CustomStringConvertible {
    typealias ElementType = E
    
    fileprivate var root: PVNode<E>?
    
    private init(root: PVNode<E>?) {
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
                let valueNode = PVValueNode<E>(data: buffer)
                
                if let root = self.root {
                    var newRoot = root.plus(valueNode: valueNode)
                    
                    if newRoot == nil {
                        newRoot = PVTreeNode(lhs: root, rhs: valueNode)
                    }
                    
                    self.root = newRoot
                } else {
                    self.root = valueNode
                }
                
                buffer = [ value ]
            }
        }
        
        if buffer.count > 0 {
            let valueNode = PVValueNode<E>(data: buffer)
            
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
                return PersistentVector(root: PVTreeNode(lhs: root, rhs: value))
            }
        } else {
            return PersistentVector(root: PVValueNode(data: [ value ]))
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
                    self.root = PVTreeNode(lhs: root, rhs: value)
                }
            } else {
                let newRoot = root.plus(value: value)
                
                if let newRoot = newRoot {
                    self.root = newRoot
                } else {
                    self.root = PVTreeNode(lhs: root, rhs: value)
                }
            }
        } else {
            root = PVValueNode(data: [ value ])
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
