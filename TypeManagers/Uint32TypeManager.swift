import Foundation

public final class Uint32TypeManager: TypeManager<UInt32> {
    public override func hashValue(value: UInt32) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: UInt32, rhs: UInt32) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: UInt32, outputStream: OutputStream) throws {
        try Serializer.writeUint32(value: value, outputStream: outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> UInt32 {
        return try Serializer.readUint32(inputStream: inputStream)
    }
    
    private init() {
        super.init(TypeId.uint32)
    }
    
    public static let instance = Uint32TypeManager()
}
