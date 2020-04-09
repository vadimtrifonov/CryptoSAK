import Foundation

public struct Reader<E, A> {
    private let reader: (E) -> A

    public init(_ reader: @escaping (E) -> A) {
        self.reader = reader
    }

    public func run(_ e: E) -> A {
        reader(e)
    }

    public func map<B>(_ f: @escaping (A) -> B) -> Reader<E, B> {
        Reader<E, B>({ f(self.run($0)) })
    }

    public func flatMap<B>(_ f: @escaping (A) -> Reader<E, B>) -> Reader<E, B> {
        Reader<E, B>({ f(self.run($0)).run($0) })
    }
}
