import Foundation

extension Sequence where Element: Equatable {
    public var distinct: [Element] {
        return reduce(into: []) { distinct, element in
            if !distinct.contains(element) {
                distinct.append(element)
            }
        }
    }
}
