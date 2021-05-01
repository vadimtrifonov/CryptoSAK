import Foundation

public struct SecondsSince1970: CustomCoding {
    
    public static func decode(from decoder: Decoder) throws -> Date {
        try Date(timeIntervalSince1970: TimeInterval(from: decoder))
    }

    public static func encode(value: Date, to encoder: Encoder) throws {
        try value.timeIntervalSince1970.encode(to: encoder)
    }
}

public struct RFC3339LocalTime: CustomCoding {

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter
    }()

    public static func decode(from decoder: Decoder) throws -> Date {
        try dateFormatter.date(from: String(from: decoder))
    }

    public static func encode(value: Date, to encoder: Encoder) throws {
        try dateFormatter.string(from: value).encode(to: encoder)
    }
}

public struct ISO8601: CustomDecoding {
    private static let dateFormatter = ISO8601DateFormatter()

    public static func decode(from decoder: Decoder) throws -> Date {
        try dateFormatter.date(from: String(from: decoder))
    }
}

public struct OptionalType<Value: Codable>: CustomDecoding {

    public static func decode(from decoder: Decoder) throws -> Value? {
        try? Value(from: decoder)
    }
}
