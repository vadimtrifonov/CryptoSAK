import Foundation

public extension Sequence where Element: Equatable {
    
    var distinct: [Element] {
        return self.reduce(into: []) { distinct, element in
            if !distinct.contains(element) {
                distinct.append(element)
            }
        }
    }
}
