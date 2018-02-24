import Foundation

public final class Int8TypeManager: TypeManager<Int8> {
    public override func hashValue(value: Int8) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: Int8, rhs: Int8) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: Int8, outputStream: OutputStream) throws {
        try Serializer.writeInt8(value: value, outputStream: outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> Int8 {
        return try Serializer.readInt8(inputStream: inputStream)
    }
    
    private init() {
        super.init(TypeId.int8)
    }
    
    public static let instance = Int8TypeManager()
}
