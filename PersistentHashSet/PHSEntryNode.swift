final class PHSEntryNode<E: Hashable> : PHSNode<E> {
    var entry: E
    var hash: Int
    
    init(shift: Int, entry: E, hash: Int) {
        self.entry = entry
        self.hash = hash
        super.init(shift: shift, size: 1)
    }
    
    override func get(key: E, hash: Int) -> E? {
        return get(key: key)
    }
    
    override func get(key: E) -> E? {
        if key == entry {
            return entry
        } else {
            return nil
        }
    }
    
    override func put(entry: E, hash: Int) -> (Bool, PHSNode<E>?) {
        if hash == self.hash && entry == self.entry {
            self.entry = entry
            self.hash = hash
        } else if shift < hashBits {
            return (true, createTreeNode(
                shift: shift,
                firstEntry: self.entry,
                firstHash: self.hash,
                secondEntry: entry,
                secondHash: hash))
        } else {
            let data = [self.entry, entry]
            
            return (true, PHSMultiNode(shift: shift, data: data))
        }
        
        return (false, nil)
    }
    
    override func with(entry: E, hash: Int) -> PHSNode<E> {
        if hash == self.hash && entry == self.entry {
            return PHSEntryNode(shift: shift, entry: entry, hash: hash)
        } else if shift < hashBits {
            return createTreeNode(
                shift: shift,
                firstEntry: self.entry,
                firstHash: self.hash,
                secondEntry: entry,
                secondHash: hash)
        } else {
            let data = [self.entry, entry]
            
            return PHSMultiNode(shift: shift, data: data)
        }
    }
    
    override func remove(key: E, hash: Int) -> Bool {
        return hash == self.hash && key == self.entry
    }
    
    override func without(key: E, hash: Int) -> PHSNode<E>? {
        if hash != self.hash || key != entry {
            return self
        } else {
            return nil
        }
    }
    
    override func foreach(function: (E) -> Void) {
        function(entry)
    }
}
