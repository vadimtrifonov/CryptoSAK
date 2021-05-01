import Foundation

extension Array {

    public subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
