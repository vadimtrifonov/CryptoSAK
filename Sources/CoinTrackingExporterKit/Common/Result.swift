public enum Result<Value> {
    case success(Value)
    case failure(Error)
    
    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
    
    public init(_ capture: () throws -> Value) {
        do {
            self = .success(try capture())
        }
        catch {
            self = .failure(error)
        }
    }
    
    public func unwrap() throws -> Value {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    public func map<NewValue>(_ transform: (Value) -> NewValue) -> Result<NewValue> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func flatMap<NewValue>(_ transform: (Value) throws -> NewValue) -> Result<NewValue> {
        switch self {
        case .success(let value):
            return Result<NewValue>({ try transform(value) })
        case .failure(let error):
            return .failure(error)
        }
    }
}
