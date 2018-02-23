public enum TypeId: Int8 {
    case Basic = 0x00
    case Boolean = 0x01
    
    case Integer = 0x10
    case Int8 = 0x11
    case Uint8 = 0x12
    case Int16 = 0x13
    case Uint16 = 0x14
    case Int32 = 0x15
    case Uint32 = 0x16
    case Int64 = 0x17
    case Uint64 = 0x18
    
    case FloatingPoint = 0x20
    case Float = 0x21
    case Double = 0x22
    case Extended = 0x23
    
    case ComplexPrimitive = 0x30
    case String = 0x31
    case Bytes = 0x32
    
    case Collection = 0x40
    case Option = 0x41
    case List = 0x42
    case Set = 0x43
    case Map = 0x44
    case Pair = 0x45
    
    case UserType = 0x50
    case Struct = 0x51
    case Enum = 0x52
    
    static func forOrdinal(_ ordinal: Int8) throws -> TypeId {
        if let result = TypeId(rawValue: ordinal) {
            return result
        } else {
            // TODO find a more appropriate error
            throw IoError("Unknown orinal value for TypeId: \(ordinal)")
        }
    }
}
