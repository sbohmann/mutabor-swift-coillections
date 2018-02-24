import Foundation

public final class ExtendedTypeManager: TypeManager<Float80> {
    public override func hashValue(value: Float80) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: Float80, rhs: Float80) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: Float80, outputStream: OutputStream) throws {
        try Serializer.writeExtended(value: value, outputStream: outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> Float80 {
        return try Serializer.readExtended(inputStream: inputStream)
    }
    
    private init() {
        super.init(TypeId.extended)
    }
    
    public static let instance = ExtendedTypeManager()
}
