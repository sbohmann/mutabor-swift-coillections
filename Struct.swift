import Foundation

public protocol Struct: Hashable, CustomStringConvertible {
    func writeToStream(_ outputStream: OutputStream) throws
}
