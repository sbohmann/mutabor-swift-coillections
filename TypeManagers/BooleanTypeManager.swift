import Foundation

public final class BooleanTypeManager: TypeManager<Bool> {
    public override func hashValue(value: Bool) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: Bool, rhs: Bool) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: Bool, outputStream: OutputStream) throws {
        try Serializer.writeBoolean(value: value, outputStream: outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> Bool {
        return try Serializer.readBoolean(inputStream: inputStream)
    }
    
    private init() {
        super.init(TypeId.boolean)
    }
    
    public static let instance = BooleanTypeManager()
}
