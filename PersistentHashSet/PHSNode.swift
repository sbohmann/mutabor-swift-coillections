class PHSNode<E: Hashable> {
    var shift: Int
    var size: Int
    
    init(shift: Int, size: Int) {
        if shift >= hashBits + shiftPerLevel {
            fatalError("Creating node with shift \(shift)")
        }
        
        self.shift = shift
        self.size = size
    }
    
    func get(key: E, hash: Int) -> E? { fatalError() }
    
    func get(key: E) -> E? { fatalError() }
    
    func put(entry: E, hash: Int) -> (Bool, PHSNode?) { fatalError() }
    
    func with(entry: E, hash: Int) -> PHSNode { fatalError() }
    
    func remove(key: E, hash: Int) -> Bool { fatalError() }
    
    func without(key: E, hash: Int) -> PHSNode? { fatalError() }
    
    func foreach(function: (E) -> Void) { fatalError() }
}
