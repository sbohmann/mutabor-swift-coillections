import Foundation

public final class Int64TypeManager: TypeManager<Int64> {
    public override func hashValue(value: Int64) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: Int64, rhs: Int64) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: Int64, outputStream: OutputStream) throws {
        try Serializer.writeInt64(value: value, outputStream: outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> Int64 {
        return try Serializer.readInt64(inputStream: inputStream)
    }
    
    private init() {
        super.init(TypeId.int64)
    }
    
    public static let instance = Int64TypeManager()
}
