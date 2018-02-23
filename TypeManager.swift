import Foundation

public class TypeManager<T> {
    init(_ typeId: TypeId) {
        self.typeId = typeId
    }
    
    public func hashValue(value: T) -> Int {
        fatalError("Not implemented")
    }
    
    public func equal(lhs: T, rhs: T) -> Bool {
        fatalError("Not implemented")
    }
    
    public func writeToStream(value: T, outputStream: OutputStream) throws {
        fatalError("Not implemented")
    }
    
    public func createFromStream(inputStream: InputStream) throws -> T {
        fatalError("Not implemented")
    }
    
    public let typeId: TypeId
}
