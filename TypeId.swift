public enum TypeId: Int8 {
    case basic = 0x00
    case boolean = 0x01
    
    case integer = 0x10
    case int8 = 0x11
    case uint8 = 0x12
    case int16 = 0x13
    case uint16 = 0x14
    case int32 = 0x15
    case uint32 = 0x16
    case int64 = 0x17
    case uint64 = 0x18
    
    case floatingPoint = 0x20
    case float = 0x21
    case double = 0x22
    case extended = 0x23
    
    case complexPrimitive = 0x30
    case string = 0x31
    case bytes = 0x32
    
    case collection = 0x40
    case option = 0x41
    case list = 0x42
    case set = 0x43
    case map = 0x44
    case pair = 0x45
    
    case userType = 0x50
    case structType = 0x51
    case enumType = 0x52
    
    static func forOrdinal(_ ordinal: Int8) throws -> TypeId {
        if let result = TypeId(rawValue: ordinal) {
            return result
        } else {
            // TODO find a more appropriate error
            throw IoError("Unknown orinal value for TypeId: \(ordinal)")
        }
    }
}
