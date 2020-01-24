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

import Foundation

public class TrieNode<T: Hashable, O> {
    var original: O?
    var value: T?
    weak var parentNode: TrieNode?
    var children: [T: TrieNode] = [:]
    var isTerminating = false
    var isLeaf: Bool {
        children.count == 0
    }

    /// Initializes a node.
    ///
    /// - Parameters:
    ///   - value: The value that goes into the node
    ///   - parentNode: A reference to this node's parent
    init(value: T? = nil, parentNode: TrieNode? = nil) {
        self.value = value
        self.parentNode = parentNode
    }

    /// Adds a child node to self.  If the child is already present,
    /// do nothing.
    ///
    /// - Parameter value: The item to be added to this node.
    func addNode(value: T) {
        guard children[value] == nil else {
            return
        }
        children[value] = TrieNode(value: value, parentNode: self)
    }
}

public class Trie<T: Hashable, O> {
    public typealias Node = TrieNode<T, O>
    public let root: Node
    fileprivate var wordCount: Int

    /// The number of words in the trie
    public var count: Int {
        wordCount
    }

    /// Is the trie empty?
    public var isEmpty: Bool {
        wordCount == 0
    }

    /// Creates an empty trie.
    public init() {
        root = Node()
        wordCount = 0
    }

    public func insert(_ elements: [T], _ original: O) {
        guard !elements.isEmpty else {
            return
        }
        var currentNode = root
        for elem in elements {
            if let childNode = currentNode.children[elem] {
                currentNode = childNode
            } else {
                currentNode.addNode(value: elem)
                currentNode = currentNode.children[elem]!
            }
        }
        // Word already present?
        guard !currentNode.isTerminating else {
            return
        }
        wordCount += 1
        currentNode.isTerminating = true
        currentNode.original = original
    }
}

extension Trie where T == Character {
    public func contains(_ source: String, _ index: String.Index) -> (O, String.Index)? {
        var i: String.Index = index
        var currentNode = root
        loop: while i < source.endIndex {
            let elem = source[i]
            i = source.index(after: i)
            if let childNode = currentNode.children[elem] {
                currentNode = childNode
                if currentNode.isTerminating {
                    return (currentNode.original!, i)
                }
            } else {
                return nil
            }
        }
        return nil
    }
}

extension Trie where T == String.UTF16View.Element {
    public func contains(_ source: String.UTF16View, _ index: String.UTF16View.Index) -> (O, String.UTF16View.Index)? {
        var i: String.UTF16View.Index = index
        var currentNode = root
        loop: while i < source.endIndex {
            let elem = source[i]
            i = source.index(after: i)
            if let childNode = currentNode.children[elem] {
                currentNode = childNode
                if currentNode.isTerminating {
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
    public func contains(_ source: String.UTF8View, _ index: String.UTF8View.Index) -> (O, String.UTF8View.Index)? {
        var i: String.UTF8View.Index = index
        var currentNode = root
        loop: while i < source.endIndex {
            let elem = source[i]
            i = source.index(after: i)
            if let childNode = currentNode.children[elem] {
                currentNode = childNode
                if currentNode.isTerminating {
                    return (currentNode.original!, i)
                }
            } else {
                return nil
            }
        }
        return nil
    }
}
