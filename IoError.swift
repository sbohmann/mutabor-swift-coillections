public struct IoError: Error {
    public let message: String
    
    public init(_ message: String) {
        self.message = message
    }
    
    public init(_ underlying: Error) {
        message = underlying.localizedDescription
    }
}
