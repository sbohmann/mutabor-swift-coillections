class PHMNode<K: Hashable, V> {
    var shift: Int
    var size: Int
    
    init(shift: Int, size: Int) {
        if shift >= hashBits + shiftPerLevel {
            fatalError("Creating node with shift \(shift)")
        }
        
        self.shift = shift
        self.size = size
    }
    
    func get(key: K, hash: Int) -> (K, V)? { fatalError() }
    
    func get(key: K) -> (K, V)? { fatalError() }
    
    func put(entry: (K, V), hash: Int) -> (Bool, PHMNode?) { fatalError() }
    
    func with(entry: (K, V), hash: Int) -> PHMNode { fatalError() }
    
    func remove(key: K, hash: Int) -> Bool { fatalError() }
    
    func without(key: K, hash: Int) -> PHMNode? { fatalError() }
    
    func foreach(function: ((K, V)) -> Void) { fatalError() }
}
