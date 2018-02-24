import Foundation

public final class StringTypeManager: TypeManager<String> {
    public override func hashValue(value: String) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: String, rhs: String) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: String, outputStream: OutputStream) throws {
        try Serializer.writeString(value: value, outputStream: outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> String {
        return try Serializer.readString(inputStream: inputStream)
    }
    
    private init() {
        super.init(TypeId.string)
    }
    
    public static let instance = StringTypeManager()
}
