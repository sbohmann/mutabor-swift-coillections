import Foundation

public final class Uint64TypeManager: TypeManager<UInt64> {
    public override func hashValue(value: UInt64) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: UInt64, rhs: UInt64) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: UInt64, outputStream: OutputStream) throws {
        try Serializer.writeUint64(value: value, outputStream: outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> UInt64 {
        return try Serializer.readUint64(inputStream: inputStream)
    }
    
    private init() {
        super.init(TypeId.uint64)
    }
    
    public static let instance = Uint64TypeManager()
}
