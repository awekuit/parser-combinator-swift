import Foundation

public final class Trie<T: BinaryInteger, O>: CustomStringConvertible {
    var original: O?
    var children: ContiguousArray<Trie?> = ContiguousArray()
    private var min: Int = 0
    private var max: Int = 0
    var isLeaf: Bool {
        children.isEmpty
    }

    public var description: String {
        "Trie(min = \(min), max = \(max), isLeaf = \(isLeaf), original = \(String(describing: original)), chirdren = \(Array(children))"
    }

    init(_ elementPairs: [([T], O)]) {
        let pairs: [([T], O)] = elementPairs.filter { !$0.0.isEmpty }
        let dict: [T: [([T], O)]] = Dictionary(grouping: pairs) { elements, _ in elements.first! }
        let childrenDict: [T: Trie] = dict.mapValues { sameHeadPairs in
            let tails = sameHeadPairs.map { pair in (Array(pair.0[1 ..< pair.0.count]), pair.1) }
            return Trie(tails)
        }
        guard !childrenDict.isEmpty else {
            original = elementPairs.first?.1 // if `childrenDict.isEmpty`, elementPairs.count is 1
            return
        }
        min = Int(childrenDict.keys.min()!)
        max = Int(childrenDict.keys.max()!)
        children = ContiguousArray(repeating: nil, count: max - min + 1)
        childrenDict.forEach { key, child in
            children[Int(key) - min] = child
        }
    }

    public final func query(_ elem: T) -> Trie? {
        let index = Int(elem)
        if index > max || index < min {
            return nil
        } else {
            return children[index - min]
        }
    }
}

extension Trie where T == String.UTF16View.Element {
    public final func contains(_ source: String.UTF16View, _ index: String.UTF16View.Index) -> (O, String.UTF16View.Index)? {
        var i: String.UTF16View.Index = index
        var currentNode: Trie = self
        loop: while i < source.endIndex {
            let elem = source[i]
            i = source.index(after: i)

            if let childNode = currentNode.query(elem) {
                currentNode = childNode
                if currentNode.isLeaf {
                    return (currentNode.original!, i)
                }
            } else {
                return nil
            }
        }
        return nil
    }
}

extension Trie where T == String.UTF8View.Element {
    public final func contains(_ source: String.UTF8View, _ index: String.UTF8View.Index) -> (O, String.UTF8View.Index)? {
        var i: String.UTF8View.Index = index
        var currentNode: Trie = self
        loop: while i < source.endIndex {
            let elem = source[i]
            i = source.index(after: i)

            if let childNode = currentNode.query(elem) {
                currentNode = childNode
                if currentNode.isLeaf {
                    return (currentNode.original!, i)
                }
            } else {
                return nil
            }
        }
        return nil
    }
}

extension Trie where T == CChar {
    public func contains(_ source: ContiguousArray<CChar>, _ index: Int) -> (O, Int)? {
        var i: Int = index
        var currentNode = self
        loop: while i < source.endIndex {
            let elem = source[i]
            i += 1
            if let childNode = currentNode.query(elem) {
                currentNode = childNode
                if currentNode.isLeaf {
                    return (currentNode.original!, i)
                }
            } else {
                return nil
            }
        }
        return nil
    }
}
