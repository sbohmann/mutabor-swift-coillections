import Foundation

public final class Int16TypeManager: TypeManager<Int16> {
    public override func hashValue(value: Int16) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: Int16, rhs: Int16) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: Int16, outputStream: OutputStream) throws {
        try Serializer.writeInt16(value: value, outputStream: outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> Int16 {
        return try Serializer.readInt16(inputStream: inputStream)
    }
    
    private init() {
        super.init(TypeId.int16)
    }
    
    public static let instance = Int16TypeManager()
}
