import Foundation

public final class Uint16TypeManager: TypeManager<UInt16> {
    public override func hashValue(value: UInt16) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: UInt16, rhs: UInt16) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: UInt16, outputStream: OutputStream) throws {
        try Serializer.writeUint16(value: value, outputStream: outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> UInt16 {
        return try Serializer.readUint16(inputStream: inputStream)
    }
    
    private init() {
        super.init(TypeId.uint16)
    }
    
    public static let instance = Uint16TypeManager()
}
