//
// reference: https://github.com/raywenderlich/swift-algorithm-club/blob/master/Trie/Trie/Trie/Trie.swift
//
// However, the above implementation has the following problems.
//
// - Supports Generics, but actually assumes String / Character
// - `lowercase` is automatically done internally
// - Difficult to perform index-based `contain` processing
//
// Therefore, I have implemented it here.
//

let BITS = 8
let WIDTH = 1 << BITS
let MASK: UInt16 = UInt16(WIDTH) - 1

public final class Trie<O>: CustomStringConvertible {
    var original: O?
    lazy var children: ContiguousArray<Trie?> = ContiguousArray(repeating: nil, count: WIDTH)
    var isLeaf: Bool = false
    public var description: String {
        "Trie(isLeaf = \(isLeaf), original = \(String(describing: original)), chirdren = \(Array(children))"
    }

    init(_ elementPairs: [([UInt8], O)]) {
        let pairs: [([UInt8], O)] = elementPairs.filter { !$0.0.isEmpty }
        let dict: [UInt8: [([UInt8], O)]] =
            Dictionary(grouping: pairs) { elements, _ in elements.first! }
        let childrenDict: [UInt8: Trie] = dict.mapValues { sameHeadPairs in
            let tails = sameHeadPairs.map { pair in (Array(pair.0[1 ..< pair.0.count]), pair.1) }
            return Trie(tails)
        }
        guard !childrenDict.isEmpty else {
            original = elementPairs.first?.1 // if `childrenDict.isEmpty`, elementPairs.count is 1
            isLeaf = true
            return
        }
        childrenDict.forEach { key, child in children[Int(key)] = child }
    }
}

extension Trie {
    convenience init(_ elementPairs: [(String.UTF16View, O)]) {
        self.init(elementPairs.map { pair in (Array(pair.0), pair.1) })
    }

    convenience init(_ elementPairs: [([String.UTF16View.Element], O)]) {
        let separatedElementPairs: [([UInt8], O)] = elementPairs.map { pair in
            let uint8s: [UInt8] = pair.0.flatMap { utf16Elem in [UInt8(utf16Elem >> BITS), UInt8(utf16Elem & MASK)] }
            return (uint8s, pair.1)
        }
        self.init(separatedElementPairs)
    }

//    convenience init(_ elementPairs: [(String.UTF8View, O)]) {
    /// /        let separatedElementPairs: [([UInt8], O)] = elementPairs.map{ pair in
    /// /            let uint8s: [UInt8] = pair.0.map{UInt8($0)}
    /// /            return (uint8s, pair.1)
    /// /        }
//        self.init(elementPairs)
//    }

    public func contains(_ source: String.UTF16View, _ index: String.UTF16View.Index) -> (O, String.UTF16View.Index)? {
        var i: String.UTF16View.Index = index
        var currentNode = self
        loop: while i < source.endIndex {
            let elem = source[i]
            i = source.index(after: i)

            let e1 = Int(elem >> BITS)
            let e2 = Int(elem & MASK)
            if let childNode1 = currentNode.children[e1], let childNode2 = childNode1.children[e2] {
                currentNode = childNode2
                if currentNode.isLeaf {
                    return (currentNode.original!, i)
                }
            } else {
                return nil
            }
        }
        return nil
    }

    public func contains(_ source: String.UTF8View, _ index: String.UTF8View.Index) -> (O, String.UTF8View.Index)? {
        var i: String.UTF8View.Index = index
        var currentNode = self
        loop: while i < source.endIndex {
            let elem = source[i]
            i = source.index(after: i)

            if let childNode = currentNode.children[Int(elem)] {
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

//    public func contains(_ source: ContiguousArray<CChar>, _ index: Int) -> (O, Int)? {
//        var i: Int = index
//        var currentNode = self
//        loop: while i < source.endIndex {
//            let elem = source[i]
//            i += 1
//            if let childNode = currentNode.children[elem] {
//                currentNode = childNode
//                if currentNode.isTerminating {
//                    return (currentNode.original!, i)
//                }
//            } else {
//                return nil
//            }
//        }
//        return nil
//    }
}

// extension Trie where T == Character {
//    public func contains(_ source: String, _ index: String.Index) -> (O, String.Index)? {
//        var i: String.Index = index
//        var currentNode = root
//        loop: while i < source.endIndex {
//            let elem = source[i]
//            i = source.index(after: i)
//            if let childNode = currentNode.children[elem] {
//                currentNode = childNode
//                if currentNode.isTerminating {
//                    return (currentNode.original!, i)
//                }
//            } else {
//                return nil
//            }
//        }
//        return nil
//    }
// }
