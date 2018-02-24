import Foundation

public final class DoubleTypeManager: TypeManager<Double> {
    public override func hashValue(value: Double) -> Int {
        return value.hashValue
    }
    
    public override func equal(lhs: Double, rhs: Double) -> Bool {
        return lhs == rhs
    }
    
    public override func writeToStream(value: Double, outputStream: OutputStream) throws {
        try Serializer.writeDouble(value: value, outputStream: outputStream)
    }
    
    public override func createFromStream(inputStream: InputStream) throws -> Double {
        return try Serializer.readDouble(inputStream: inputStream)
    }
    
    private init() {
        super.init(TypeId.double)
    }
    
    public static let instance = DoubleTypeManager()
}
