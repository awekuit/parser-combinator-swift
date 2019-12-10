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

class TrieNode<T: Hashable, O> {
    var original: O?
    var value: T?
    weak var parentNode: TrieNode?
    var children: [T: TrieNode] = [:]
    var isTerminating = false
    var isLeaf: Bool {
        return children.count == 0
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

class Trie<T: Hashable, O> {
    typealias Node = TrieNode<T, O>
    public let root: Node
    fileprivate var wordCount: Int

    /// The number of words in the trie
    public var count: Int {
        return wordCount
    }

    /// Is the trie empty?
    public var isEmpty: Bool {
        return wordCount == 0
    }

    /// Creates an empty trie.
    init() {
        root = Node()
        wordCount = 0
    }

    func insert(_ elements: [T], _ original: O) {
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
