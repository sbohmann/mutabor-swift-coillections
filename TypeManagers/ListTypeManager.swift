import Foundation

public final class ListTypeManager<E>: TypeManager<PersistentVector<E>> where E: Hashable, E: CustomStringConvertible {
    public typealias ListType = PersistentVector<E>
    
    private let elementTypeManager: TypeManager<E>
    
    public init(_ elementTypeManager: TypeManager<E>) {
        self.elementTypeManager = elementTypeManager
        
        super.init(TypeId.list)
    }
    
    public override func hashValue(value: ListType) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: ListType, rhs: ListType) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: ListType, outputStream: OutputStream) throws {
        try Serializer.writeTypeId(value: TypeId.list, outputStream: outputStream)
        
        try Serializer.writeTypeId(value: elementTypeManager.typeId, outputStream: outputStream)
        
        try Serializer.writeSize(size: value.count, outputStream: outputStream)
        
        for element in value {
            try elementTypeManager.writeToStream(value: element, outputStream: outputStream)
        }
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> ListType {
        try Serializer.checkTypeId(expectedTypeId: TypeId.list, inputStream: inputStream)
        
        try Serializer.checkTypeId(expectedTypeId: elementTypeManager.typeId, inputStream: inputStream)
        
        let size = try Serializer.readSize(inputStream: inputStream)
        
        var buffer = [E]()
        buffer.reserveCapacity(Int(size))
        
        for _ in 0 ..< size {
            buffer.append(try elementTypeManager.createFromStream(inputStream: inputStream))
        }
        
        return PersistentVector<E>(seq: buffer)
    }
}
