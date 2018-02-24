import Foundation

public final class Uint8TypeManager: TypeManager<UInt8> {
    public override func hashValue(value: UInt8) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: UInt8, rhs: UInt8) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: UInt8, outputStream: OutputStream) throws {
        try Serializer.writeUint8(value: value, outputStream: outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> UInt8 {
        return try Serializer.readUint8(inputStream: inputStream)
    }
    
    private init() {
        super.init(TypeId.uint8)
    }
    
    public static let instance = Uint8TypeManager()
}
