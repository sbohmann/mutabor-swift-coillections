
import Foundation

public class Serializer {
    public static func writeInt8(value: Int8, outputStream: OutputStream) throws {
        try writeInteger(value: Int64(value), size: 1, signed: true, outputStream: outputStream)
    }

    public static func readInt8(inputStream: InputStream) throws -> Int8 {
        return try Int8(readInteger(size: 1, signed: true, inputStream: inputStream))
    }

    public static func writeUint8(value: UInt8, outputStream: OutputStream) throws {
        try writeInteger(value: Int64(value), size: 1, signed: false, outputStream: outputStream)
    }

    public static func readUint8(inputStream: InputStream) throws -> UInt8 {
        return try UInt8(readInteger(size: 1, signed: false, inputStream: inputStream))
    }

    public static func writeInt16(value: Int16, outputStream: OutputStream) throws {
        try writeInteger(value: Int64(value), size: 2, signed: true, outputStream: outputStream)
    }

    public static func readInt16(inputStream: InputStream) throws -> Int16 {
        return try Int16(readInteger(size: 2, signed: true, inputStream: inputStream))
    }

    public static func writeUint16(value: UInt16, outputStream: OutputStream) throws {
        try writeInteger(value: Int64(value), size: 2, signed: false, outputStream: outputStream)
    }

    public static func readUint16(inputStream: InputStream) throws -> UInt16 {
        return try UInt16(readInteger(size: 2, signed: false, inputStream: inputStream))
    }

    public static func writeInt32(value: Int32, outputStream: OutputStream) throws {
        try writeInteger(value: Int64(value), size: 4, signed: true, outputStream: outputStream)
    }

    public static func readInt32(inputStream: InputStream) throws -> Int32 {
        return try Int32(readInteger(size: 4, signed: true, inputStream: inputStream))
    }

    public static func writeUint32(value: UInt32, outputStream: OutputStream) throws {
        try writeInteger(value: Int64(value), size: 4, signed: false, outputStream: outputStream)
    }

    public static func readUint32(inputStream: InputStream) throws -> UInt32 {
        return try UInt32(readInteger(size: 4, signed: false, inputStream: inputStream))
    }

    public static func writeInt64(value: Int64, outputStream: OutputStream) throws {
        try writeInteger(value: value, size: 8, signed: true, outputStream: outputStream)
    }

    public static func readInt64(inputStream: InputStream) throws -> Int64 {
        return try Int64(readInteger(size: 8, signed: true, inputStream: inputStream))
    }

    public static func writeUint64(value: UInt64, outputStream: OutputStream) throws {
        try writeInteger(value: Int64(value), size: 8, signed: false, outputStream: outputStream)
    }

    public static func readUint64(inputStream: InputStream) throws -> UInt64 {
        return try UInt64(readInteger(size: 8, signed: true, inputStream: inputStream))
    }

    private static func writeInteger(value: Int64, size: UInt8, signed: Bool, outputStream: OutputStream) throws {
        var shift = Int8((size - 1) * 8)
        
        for _ in 0 ..< size {
            try writeByte(UInt8((value >> Int64(shift)) & 0xFF), outputStream)
            
            shift -= 8
        }
    }

    private static func readInteger(size: UInt8, signed: Bool, inputStream: InputStream) throws -> Int64 {
        var result: Int64 = 0
        
        var shift = Int8((size - 1) * 8)
        
        for _ in 0 ..< size {
            let value: UInt8 = try readByte(inputStream)
            
            result |= (Int64(value) << Int64(shift))
            
            shift -= 8
        }
        
        return result
    }

    public static func writeCompressedInt8(value: Int8, outputStream: OutputStream) throws {
        try writeInteger(value: Int64(value), size: 1, signed: true, outputStream: outputStream)
    }

    public static func readCompressedInt8(inputStream: InputStream) throws -> Int8 {
        return try Int8(readInteger(size: 1, signed: true, inputStream: inputStream))
    }

    public static func writeCompressedUint8(value: UInt8, outputStream: OutputStream) throws {
        try writeInteger(value: Int64(value), size: 1, signed: false, outputStream: outputStream)
    }

    public static func readCompressedUint8(inputStream: InputStream) throws -> UInt8 {
        return try UInt8(readInteger(size: 1, signed: false, inputStream: inputStream))
    }

    public static func writeCompressedInt16(value: Int16, outputStream: OutputStream) throws {
        try writeCompressedSignedInteger(value: Int64(value), size: 2, outputStream: outputStream)
    }

    public static func readCompressedInt16(inputStream: InputStream) throws -> Int16 {
        return try Int16(readCompressedSignedInteger(size: 2, inputStream: inputStream))
    }

    public static func writeCompressedUint16(value: UInt16, outputStream: OutputStream) throws {
        try writeCompressedUnsignedInteger(value: UInt64(value), size: 2, outputStream: outputStream)
    }

    public static func readCompressedUint16(inputStream: InputStream) throws -> UInt16 {
        return try UInt16(readCompressedUnsignedInteger(size: 2, inputStream: inputStream))
    }

    public static func writeCompressedInt32(value: Int32, outputStream: OutputStream) throws {
        try writeCompressedSignedInteger(value: Int64(value), size: 4, outputStream: outputStream)
    }

    public static func readCompressedInt32(inputStream: InputStream) throws -> Int32 {
        return try Int32(readCompressedSignedInteger(size: 4, inputStream: inputStream))
    }

    public static func writeCompressedUint32(value: UInt32, outputStream: OutputStream) throws {
        try writeCompressedUnsignedInteger(value: UInt64(value), size: 4, outputStream: outputStream)
    }

    public static func readCompressedUint32(inputStream: InputStream) throws -> UInt32 {
        return try UInt32(readCompressedUnsignedInteger(size: 4, inputStream: inputStream))
    }

    public static func writeCompressedInt64(value: Int64, outputStream: OutputStream) throws {
        try writeCompressedSignedInteger(value: value, size: 8, outputStream: outputStream)
    }

    public static func readCompressedInt64(inputStream: InputStream) throws -> Int64 {
        return try readCompressedSignedInteger(size: 8, inputStream: inputStream)
    }

    public static func writeCompressedUint64(value: UInt64, outputStream: OutputStream) throws {
        try writeCompressedUnsignedInteger(value: value, size: 8, outputStream: outputStream)
    }

    public static func readCompressedUint64(inputStream: InputStream) throws -> UInt64 {
        return try readCompressedUnsignedInteger(size: 8, inputStream: inputStream)
    }

    private static func writeCompressedSignedInteger(value valueInput: Int64, size: UInt8, outputStream: OutputStream) throws {
        var value = valueInput
        
        let negative = (value < 0)
        
        if (negative) {
            value = -(value + 1) // e.g. long min value -> long max value, -128
            // -> 127, -1 -> 0
        }
        
        var shift: Int8 = 62
        
        while (value >> Int64(shift) == 0) {
            shift -= 7
            
            if (shift < 0) {
                break
            }
        }
        
        shift += 1
        
        if (shift < 0) {
            throw IoError("shift < 0 after reduction: \(shift)")
        }
        
        var bytesWritten = 0
        
        var first = true
        while (shift >= 0) {
            let last = (shift == 0)
            
            let lastMarker = UInt8(last ? 0 : 0x80)
            
            let negativeMarker = UInt8(negative ? 0x40 : 0x00)
            
            if (first) {
                try writeByte(lastMarker | negativeMarker | UInt8(((value >> Int64(shift)) & 0x3F)), outputStream)
            } else {
                try writeByte(lastMarker | UInt8((value >> Int64(shift)) & 0x7F), outputStream)
            }
            
            bytesWritten += 1
            
            shift -= 7
            
            first = false
        }
        
        if (shift != -7) {
            throw IoError("shift != -7 after output: \(shift)")
        }
        
        if (bytesWritten > 10) {
            throw IoError("Logical error: \(bytesWritten) bytes written")
        }
    }

    private static func writeCompressedUnsignedInteger(value: UInt64, size: UInt8, outputStream: OutputStream) throws {
        var shift: Int8 = 63
        
        while (value >> UInt64(shift) == 0) {
            shift -= 7
            
            if (shift == 0) {
                break
            }
        }
        
        if (shift < 0) {
            throw IoError("shift < 0 after reduction: \(shift)")
        }
        
        var bytesWritten = 0
        
        while (shift >= 0) {
            let last = (shift == 0)
            
            let lastMarker = UInt8(last ? 0 : 0x80)
            
            try writeByte(lastMarker | UInt8((value >> UInt64(shift)) & 0x7F), outputStream)
            
            bytesWritten += 1
            
            shift -= 7
        }
        
        if (shift != -7) {
            throw IoError("shift != -7 after output: \(shift)")
        }
        
        if (bytesWritten > 10) {
            throw IoError("Logical error: \(bytesWritten) bytes written")
        }
    }

    private static func readCompressedSignedInteger(size: UInt8, inputStream: InputStream) throws -> Int64 {
        var result: Int64 = 0
        
        var negative = false
        
        var bytesRead = 0
        
        var first = true
        while (true) {
            let b = try readByte(inputStream)
            
            bytesRead += 1
            
            let last = ((b & 0x80) == 0)
            
            if (first) {
                negative = ((b & 0x40) != 0)
                result = (Int64(b) & Int64(0x3F))
            } else {
                result <<= 7
                
                result |= (Int64(b) & Int64(0x7F))
            }
            
            if (last) {
                break
            }
            
            first = false
        }
        
        if (bytesRead > 10) {
            throw IoError("Illegal compressed integer - more than 10 bytes read: \(bytesRead)")
        }
        
        if (negative) {
            result = -result - 1
        }
        
        // TODO check value range for signed, size, &c!!!
        
        return result
    }

    private static func readCompressedUnsignedInteger(size: UInt8, inputStream: InputStream) throws -> UInt64 {
        var result: UInt64 = 0
        
        var bytesRead = 0
        
        while (true) {
            let b = try readByte(inputStream)
            
            bytesRead += 1
            
            let last = ((b & 0x80) == 0)
            
            result <<= 7
            
            result |= (UInt64(b) & UInt64(0x7F))
            
            if (last) {
                break
            }
        }
        
        if (bytesRead > 10) {
            throw IoError("Illegal compressed integer - more than 10 bytes read: \(bytesRead)")
        }
        
        // TODO check value range for signed, size, &c!!!
        
        return result
    }

    public static func writeTypeId(value: TypeId, outputStream: OutputStream) throws {
        try writeInt8(value: value.rawValue, outputStream: outputStream)
    }

    public static func readTypeId(inputStream: InputStream) throws -> TypeId {
        let ordinal = try readInt8(inputStream: inputStream)
        
        return try TypeId.forOrdinal(ordinal)
    }

    public static func checkTypeId(expectedTypeId: TypeId, inputStream: InputStream) throws {
        let typeIdFromStream = try readTypeId(inputStream: inputStream)
        
        if (typeIdFromStream != expectedTypeId) {
            throw IoError("Wrong type ID [\(typeIdFromStream)] - expected: \(expectedTypeId)")
        }
    }

    public static func writeSubtypeId(value: Int32, outputStream: OutputStream) throws {
        if (value < 0) {
            throw IoError("subtype ID < 0: \(value)")
        }
        
        try writeCompressedInt32(value: value, outputStream: outputStream)
    }

    public static func readSubtypeId(inputStream: InputStream) throws -> Int32 {
        let result = try readCompressedInt32(inputStream: inputStream)
        
        if (result < 0) {
            throw IoError("subtype ID < 0: \(result)")
        }
        
        return result
    }

    public static func checkSubtypeId(expectedSubtypeId: Int32, inputStream: InputStream) throws {
        let subtypeIdFromStream = try readSubtypeId(inputStream: inputStream)
        
        if (subtypeIdFromStream != expectedSubtypeId) {
            throw IoError("Wrong subtype ID [\(subtypeIdFromStream)] - expected: \(expectedSubtypeId)")
        }
    }

    public static func writeBoolean(value: Bool, outputStream: OutputStream) throws {
        try writeInt8(value: value ? 1 : 2, outputStream: outputStream)
    }

    public static func readBoolean(inputStream: InputStream) throws -> Bool {
        let value = try readInt8(inputStream: inputStream)
        
        switch (value) {
        case 0:
            return false
        case 1:
            return true
        default:
            throw IoError("Illegal boolean value: \(value)")
        }
    }
    
    public static func writeString(value: String, outputStream: OutputStream) throws {
        guard let data = value.data(using:String.Encoding.utf8) else {
            throw IoError("Unable to encode string as UTF-8")
        }
        
        try writeSize(size: data.count, outputStream:outputStream)
        
        try writeData(data:data, outputStream:outputStream)
    }
    
    public static func readString(inputStream: InputStream) throws -> String {
        let size = try readSize(inputStream:inputStream)
        
        let data = try readData(inputStream:inputStream, size:size)
        
        guard let result = String(data:data, encoding:String.Encoding.utf8) else {
            throw IoError("Unable to create string from data")
        }
        
        return result
    }
    
    public static func writeData(data: Data, outputStream: OutputStream) throws {
        let size = data.count
        
        if size > Int(Int32.max) {
            throw IoError("bufferData length out of range: \(size)")
        }
        
        try data.withUnsafeBytes( {
            (bytes: UnsafePointer<UInt8>) in
            
            var bytesWritten = 0
            
            while bytesWritten < size {
                let n = outputStream.write(bytes.advanced(by:bytesWritten), maxLength:size - bytesWritten)
                
                if (n == 0) {
                    throw IoError("Reached EOF while writing")
                } else if (n < 0) {
                    throw IoError("Error writing data to outputStream: \(outputStream.streamError?.localizedDescription ?? "unknown error")")
                }
                
                bytesWritten += n
            }
        })
    }
    
    public static func readData(inputStream: InputStream, size: Int32) throws -> Data {
        if (size < 0) {
            throw IoError("Illegal size: \(size)")
        }
        
        var data = Data(count: Int(size))
        
        try data.withUnsafeMutableBytes( {
            (buffer: UnsafeMutablePointer<UInt8>) in
            
            var bytesRead: Int = 0
            
            while bytesRead < Int(size) {
                let n = inputStream.read(buffer.advanced(by: bytesRead), maxLength:Int(size) - bytesRead)
                
                if n == 0 {
                    throw IoError("Reached EOF after \(bytesRead) while reading \(size) bytes of data")
                } else if n < 0 {
                    if let error = inputStream.streamError {
                        throw IoError(error)
                    } else {
                        throw IoError("Unknown stream error")
                    }
                }
                
                bytesRead += n
            }
        })
        
        return data
    }

    public static func writeSize(size: Int, outputStream: OutputStream) throws {
        if (size < 0 || size > Int(Int32.max)) {
            throw IoError("Illegal size: \(size)")
        }
        
        try writeCompressedInt32(value: Int32(size), outputStream: outputStream)
    }

    public static func readSize(inputStream: InputStream) throws -> Int32 {
        let size = try readCompressedInt32(inputStream: inputStream)
        
        if (size < 0) {
            throw IoError("Illegal size: \(size)")
        }
        
        return size
    }

    public static func writeFloat(value: Float, outputStream: OutputStream) throws {
        if MemoryLayout<Float>.size != MemoryLayout<UInt32>.size {
            throw IoError("Internal error")
        }
        
        var f = value
        var i: UInt32 = 0
        
        memcpy(&i, &f, MemoryLayout<UInt32>.size)
        
        try writeUint32(value: i, outputStream: outputStream)
    }

    public static func readFloat(inputStream: InputStream) throws -> Float {
        if MemoryLayout<Float>.size != MemoryLayout<UInt32>.size {
            throw IoError("Internal error")
        }
        
        var i = try readUint32(inputStream: inputStream)
        var f: Float = 0.0
        
        memcpy(&f, &i, MemoryLayout<Float>.size)
        
        return f
    }

    public static func writeDouble(value: Double, outputStream: OutputStream) throws {
        if MemoryLayout<Double>.size != MemoryLayout<UInt64>.size {
            throw IoError("Internal error")
        }
        
        var f = value
        var i: UInt64 = 0
        
        memcpy(&i, &f, MemoryLayout<Int64>.size)
        
        try writeUint64(value: i, outputStream: outputStream)
    }

    public static func readDouble(inputStream: InputStream) throws -> Double {
        if MemoryLayout<Double>.size != MemoryLayout<UInt64>.size {
            throw IoError("Internal error")
        }
        
        var i = try readUint64(inputStream: inputStream)
        var f: Double = 0.0
        
        memcpy(&f, &i, MemoryLayout<Double>.size)
        
        return f
    }

    public static func writeExtended(value: Float80, outputStream: OutputStream) throws {
        // TODO implement with correct layout on all platforms
        try writeDouble(value: Double(value), outputStream: outputStream)
    }
    
    public static func readExtended(inputStream: InputStream) throws -> Float80 {
        // TODO implement with correct layout on all platforms
        return Float80(try readDouble(inputStream: inputStream))
    }

    private static func readByte(_ inputStream: InputStream) throws -> UInt8 {
        var byte: UInt8 = 0
        
        let n = inputStream.read(&byte, maxLength: 1)
        
        if (n == 0) {
            throw IoError("Reached EOF whlie reading")
        } else if (n < 0) {
            if let error = inputStream.streamError {
                throw error
            } else {
                throw IoError("Unknown stream error while reading")
            }
        }
        
        return byte
    }

    private static func writeByte(_ value: UInt8, _ outputStream: OutputStream) throws {
        var byte = value
        
        let n = outputStream.write(&byte, maxLength: 1)
        
        if (n == 0) {
            throw IoError("Reached EOF whlie writing")
        } else if (n < 0) {
            if let error = outputStream.streamError {
                throw error
            } else {
                throw IoError("Unknown stream error while writing")
            }
        }
    }
}
