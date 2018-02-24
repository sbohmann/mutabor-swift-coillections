import Foundation

func readByte(_ inputStream: InputStream) throws -> UInt8 {
    var byte: UInt8 = 0
    
    let n = inputStream.read(&byte, maxLength: 1)
    
    if n == 0 {
        throw IoError("Reached EOF whlie reading")
    } else if n < 0 {
        if let error = inputStream.streamError {
            throw error
        } else {
            throw IoError("Unknown stream error while reading")
        }
    }
    
    return byte
}

func writeByte(_ value: UInt8, _ outputStream: OutputStream) throws {
    var byte = value
    
    let n = outputStream.write(&byte, maxLength: 1)
    
    if n == 0 {
        throw IoError("Reached EOF whlie writing")
    } else if n < 0 {
        if let error = outputStream.streamError {
            throw error
        } else {
            throw IoError("Unknown stream error while writing")
        }
    }
}

func writeInteger(value: Int64, size: UInt8, signed: Bool, outputStream: OutputStream) throws {
    var shift = Int8((size - 1) * 8)
    
    for _ in 0 ..< size {
        try writeByte(UInt8((value >> Int64(shift)) & 0xFF), outputStream)
        
        shift -= 8
    }
}

func readInteger(size: UInt8, signed: Bool, inputStream: InputStream) throws -> Int64 {
    var result: Int64 = 0
    
    var shift = Int8((size - 1) * 8)
    
    for _ in 0 ..< size {
        let value: UInt8 = try readByte(inputStream)
        
        result |= (Int64(value) << Int64(shift))
        
        shift -= 8
    }
    
    return result
}

func writeCompressedSignedInteger(
    value valueInput: Int64,
    size: UInt8,
    outputStream: OutputStream) throws {
    
    var value = valueInput
    
    let negative = (value < 0)
    
    if negative {
        value = -(value + 1) // e.g. long min value -> long max value, -128
        // -> 127, -1 -> 0
    }
    
    var shift: Int8 = 62
    
    while value >> Int64(shift) == 0 {
        shift -= 7
        
        if shift < 0 {
            break
        }
    }
    
    shift += 1
    
    if shift < 0 {
        throw IoError("shift < 0 after reduction: \(shift)")
    }
    
    var bytesWritten = 0
    
    var first = true
    while shift >= 0 {
        let last = (shift == 0)
        
        let lastMarker = UInt8(last ? 0 : 0x80)
        
        let negativeMarker = UInt8(negative ? 0x40 : 0x00)
        
        if first {
            try writeByte(lastMarker | negativeMarker | UInt8(((value >> Int64(shift)) & 0x3F)), outputStream)
        } else {
            try writeByte(lastMarker | UInt8((value >> Int64(shift)) & 0x7F), outputStream)
        }
        
        bytesWritten += 1
        
        shift -= 7
        
        first = false
    }
    
    if shift != -7 {
        throw IoError("shift != -7 after output: \(shift)")
    }
    
    if bytesWritten > 10 {
        throw IoError("Logical error: \(bytesWritten) bytes written")
    }
}

func writeCompressedUnsignedInteger(value: UInt64, size: UInt8, outputStream: OutputStream) throws {
    var shift: Int8 = 63
    
    while value >> UInt64(shift) == 0 {
        shift -= 7
        
        if shift == 0 {
            break
        }
    }
    
    if shift < 0 {
        throw IoError("shift < 0 after reduction: \(shift)")
    }
    
    var bytesWritten = 0
    
    while shift >= 0 {
        let last = (shift == 0)
        
        let lastMarker = UInt8(last ? 0 : 0x80)
        
        try writeByte(lastMarker | UInt8((value >> UInt64(shift)) & 0x7F), outputStream)
        
        bytesWritten += 1
        
        shift -= 7
    }
    
    if shift != -7 {
        throw IoError("shift != -7 after output: \(shift)")
    }
    
    if bytesWritten > 10 {
        throw IoError("Logical error: \(bytesWritten) bytes written")
    }
}

func readCompressedSignedInteger(size: UInt8, inputStream: InputStream) throws -> Int64 {
    var result: Int64 = 0
    
    var negative = false
    
    var bytesRead = 0
    
    var first = true
    while true {
        let b = try readByte(inputStream)
        
        bytesRead += 1
        
        let last = ((b & 0x80) == 0)
        
        if first {
            negative = ((b & 0x40) != 0)
            result = (Int64(b) & Int64(0x3F))
        } else {
            result <<= 7
            
            result |= (Int64(b) & Int64(0x7F))
        }
        
        if last {
            break
        }
        
        first = false
    }
    
    if bytesRead > 10 {
        throw IoError("Illegal compressed integer - more than 10 bytes read: \(bytesRead)")
    }
    
    if negative {
        result = -result - 1
    }
    
    // TODO check value range for signed, size, &c!!!
    
    return result
}

func readCompressedUnsignedInteger(size: UInt8, inputStream: InputStream) throws -> UInt64 {
    var result: UInt64 = 0
    
    var bytesRead = 0
    
    while true {
        let b = try readByte(inputStream)
        
        bytesRead += 1
        
        let last = ((b & 0x80) == 0)
        
        result <<= 7
        
        result |= (UInt64(b) & UInt64(0x7F))
        
        if last {
            break
        }
    }
    
    if bytesRead > 10 {
        throw IoError("Illegal compressed integer - more than 10 bytes read: \(bytesRead)")
    }
    
    // TODO check value range for signed, size, &c!!!
    
    return result
}
