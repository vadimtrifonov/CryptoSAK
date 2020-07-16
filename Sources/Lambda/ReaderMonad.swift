import Foundation

public struct Reader<Environment, Output> {
    private let apply: (Environment) -> Output

    public init(_ apply: @escaping (Environment) -> Output) {
        self.apply = apply
    }

    public func apply(_ environment: Environment) -> Output {
        apply(environment)
    }

    public func map<T>(_ transform: @escaping (Output) -> T) -> Reader<Environment, T> {
        Reader<Environment, T>({ transform(self.apply($0)) })
    }

    public func flatMap<T>(_ transform: @escaping (Output) -> Reader<Environment, T>) -> Reader<Environment, T> {
        Reader<Environment, T>({ transform(self.apply($0)).apply($0) })
    }
}
