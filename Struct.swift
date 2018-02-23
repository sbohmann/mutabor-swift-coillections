
import Foundation

public protocol Struct : Hashable, CustomStringConvertible//, CustomDebugStringConvertible
{
    func writeToStream(_ outputStream: OutputStream) throws
}
