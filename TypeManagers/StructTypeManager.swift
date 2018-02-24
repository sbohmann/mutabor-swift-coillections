import Foundation

public final class StructTypeManager<T: Struct>: TypeManager<T> {
    private let deserializer: (InputStream) throws -> T
    
    public init(_ deserializer: @escaping (InputStream) throws -> T) {
        self.deserializer = deserializer
        
        super.init(TypeId.structType)
    }
    
    public override func hashValue(value: T) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: T, rhs: T) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: T, outputStream: OutputStream) throws {
        try value.writeToStream(outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> T {
        return try deserializer(inputStream)
    }
}
