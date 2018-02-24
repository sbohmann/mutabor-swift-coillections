// does not store the hash because all calls are guaranteed
// to pass the same hash in any case. Comparing would not save time.
// EntryNodes can sit anywhere in the tree above just partial hash absed
// branching, but only the full hash leads to the tree location of
// a MultiNode.
final class PHSMultiNode<E: Hashable> : PHSNode<E> {
    var data: [E]
    
    init(shift: Int, data: [E]) {
        self.data = data
        super.init(shift: shift, size: data.count)
    }
    
    override func get(key: E, hash: Int) -> E? {
        return get(key: key)
    }
    
    override func get(key: E) -> E? {
        for entry in data {
            if key == entry {
                return entry
            }
        }
        
        return nil
    }
    
    override func put(entry newEntry: E, hash: Int) -> (Bool, PHSNode<E>?) {
        for idx in 0 ..< data.count {
            let entry = data[idx]
            
            if newEntry == entry {
                data[idx] = newEntry
                
                return (false, nil)
            }
        }
        
        data.append(newEntry)
        size += 1
        
        return (false, nil)
    }
    
    override func with(entry newEntry: E, hash: Int) -> PHSNode<E> {
        let size = data.count
        
        for idx in 0 ..< size {
            let entry = data[idx]
            
            if newEntry == entry {
                var newData = data
                newData[idx] = newEntry
                
                return PHSMultiNode(shift: shift, data: newData)
            }
        }
        
        var newData = data
        newData.append(newEntry)
        return PHSMultiNode(shift: shift, data: newData)
    }
    
    override func remove(key: E, hash: Int) -> Bool {
        for idx in 0 ..< data.count {
            let entry = data[idx]
            
            if key == entry {
                data.remove(at: idx)
                size -= 1
                
                return size == 0
            }
        }
        
        return false
    }
    
    override func without(key: E, hash: Int) -> PHSNode<E>? {
        let size = data.count
        
        for idx in 0 ..< size {
            let entry = data[idx]
            
            if key == entry {
                if data.count == 1 {
                    return nil
                } else if data.count == 2 {
                    let retainedIndex = (idx + 1) % 2
                    
                    return PHSEntryNode(shift: shift, entry: data[retainedIndex], hash: hash)
                } else {
                    var newData = data
                    newData.remove(at: idx)
                    
                    return PHSMultiNode(shift: shift, data: newData)
                }
            }
        }
        
        return self
    }
    
    override func foreach(function: (E) -> Void) {
        for entry in data {
            function(entry)
        }
    }
}
