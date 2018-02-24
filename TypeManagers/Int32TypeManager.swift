import Foundation

public final class Int32TypeManager: TypeManager<Int32> {
    public override func hashValue(value: Int32) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: Int32, rhs: Int32) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: Int32, outputStream: OutputStream) throws {
        try Serializer.writeInt32(value: value, outputStream: outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> Int32 {
        return try Serializer.readInt32(inputStream: inputStream)
    }
    
    private init() {
        super.init(TypeId.int32)
    }
    
    public static let instance = Int32TypeManager()
}
