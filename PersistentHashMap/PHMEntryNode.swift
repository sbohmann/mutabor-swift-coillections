final class PHMEntryNode<K: Hashable, V> : PHMNode<K, V> {
    var entry: (K, V)
    var hash: Int
    
    init(shift: Int, entry: (K, V), hash: Int) {
        self.entry = entry
        self.hash = hash
        super.init(shift: shift, size: 1)
    }
    
    override func get(key: K, hash: Int) -> (K, V)? {
        return get(key: key)
    }
    
    override func get(key: K) -> (K, V)? {
        if key == entry.0 {
            return entry
        } else {
            return nil
        }
    }
    
    override func put(entry: (K, V), hash: Int) -> (Bool, PHMNode<K, V>?) {
        if hash == self.hash && entry.0 == self.entry.0 {
            self.entry = entry
            self.hash = hash
        } else if shift < hashBits {
            return (true, createPHMTreeNode(
                shift: shift,
                firstEntry: self.entry,
                firstHash: self.hash,
                secondEntry: entry,
                secondHash: hash))
        } else {
            let data = [self.entry, entry]
            
            return (true, PHMMultiNode(shift: shift, data: data))
        }
        
        return (false, nil)
    }
    
    override func with(entry: (K, V), hash: Int) -> PHMNode<K, V> {
        if hash == self.hash && entry.0 == self.entry.0 {
            return PHMEntryNode(shift: shift, entry: entry, hash: hash)
        } else if shift < hashBits {
            return createPHMTreeNode(
                shift: shift,
                firstEntry: self.entry,
                firstHash: self.hash,
                secondEntry: entry,
                secondHash: hash)
        } else {
            let data = [self.entry, entry]
            
            return PHMMultiNode(shift: shift, data: data)
        }
    }
    
    override func remove(key: K, hash: Int) -> Bool {
        return hash == self.hash && key == self.entry.0
    }
    
    override func without(key: K, hash: Int) -> PHMNode<K, V>? {
        if hash != self.hash || key != entry.0 {
            return self
        } else {
            return nil
        }
    }
    
    override func foreach(function: ((K, V)) -> Void) {
        function(entry)
    }
}
