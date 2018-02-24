import Foundation

public final class FloatTypeManager: TypeManager<Float> {
    public override func hashValue(value: Float) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: Float, rhs: Float) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: Float, outputStream: OutputStream) throws {
        try Serializer.writeFloat(value: value, outputStream: outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> Float {
        return try Serializer.readFloat(inputStream: inputStream)
    }
    
    private init() {
        super.init(TypeId.float)
    }
    
    public static let instance = FloatTypeManager()
}
