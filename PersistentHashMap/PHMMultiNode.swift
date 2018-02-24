// does not store the hash because all calls are guaranteed
// to pass the same hash in any case. Comparing would not save time.
// EntryNodes can sit anywhere in the tree above just partial hash absed
// branching, but only the full hash leads to the tree location of
// a MultiNode.
final class PHMMultiNode<K: Hashable, V> : PHMNode<K, V> {
    var data: [(K, V)]
    
    init(shift: Int, data: [(K, V)]) {
        self.data = data
        super.init(shift: shift, size: data.count)
    }
    
    override func get(key: K, hash: Int) -> (K, V)? {
        return get(key: key)
    }
    
    override func get(key: K) -> (K, V)? {
        for entry in data where key == entry.0 {
            return entry
        }
        
        return nil
    }
    
    override func put(entry newEntry: (K, V), hash: Int) -> (Bool, PHMNode<K, V>?) {
        for idx in 0 ..< data.count {
            let entry = data[idx]
            
            if newEntry.0 == entry.0 {
                data[idx] = newEntry
                
                return (false, nil)
            }
        }
        
        data.append(newEntry)
        size += 1
        
        return (false, nil)
    }
    
    override func with(entry newEntry: (K, V), hash: Int) -> PHMNode<K, V> {
        let size = data.count
        
        for idx in 0 ..< size {
            let entry = data[idx]
            
            if newEntry.0 == entry.0 {
                var newData = data
                newData[idx] = newEntry
                
                return PHMMultiNode(shift: shift, data: newData)
            }
        }
        
        var newData = data
        newData.append(newEntry)
        return PHMMultiNode(shift: shift, data: newData)
    }
    
    override func remove(key: K, hash: Int) -> Bool {
        for idx in 0 ..< data.count {
            let entry = data[idx]
            
            if key == entry.0 {
                data.remove(at: idx)
                size -= 1
                
                return size == 0
            }
        }
        
        return false
    }
    
    override func without(key: K, hash: Int) -> PHMNode<K, V>? {
        let size = data.count
        
        for idx in 0 ..< size {
            let entry = data[idx]
            
            if key == entry.0 {
                if data.count == 1 {
                    return nil
                } else if data.count == 2 {
                    let retainedIndex = (idx + 1) % 2
                    
                    return PHMEntryNode(shift: shift, entry: data[retainedIndex], hash: hash)
                } else {
                    var newData = data
                    newData.remove(at: idx)
                    
                    return PHMMultiNode(shift: shift, data: newData)
                }
            }
        }
        
        return self
    }
    
    override func foreach(function: ((K, V)) -> Void) {
        for entry in data {
            function(entry)
        }
    }
}
