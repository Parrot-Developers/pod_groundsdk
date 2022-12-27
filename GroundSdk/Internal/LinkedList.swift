// Copyright (C) 2019 Parrot Drones SAS
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions
//    are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in
//      the documentation and/or other materials provided with the
//      distribution.
//    * Neither the name of the Parrot Company nor the names
//      of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written
//      permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//    PARROT COMPANY BE LIABLE FOR ANY DIRECT, INDIRECT,
//    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
//    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//    SUCH DAMAGE.

import Foundation

/// A Double linked list
/// T: List entry type
class LinkedList<T> {

    /// A node of a list
    /// T: node data
    class Node {
        /// Next node in the list
        fileprivate var next: Node?
        /// Previous node
        fileprivate weak var prev: Node?
        /// Node content
        var content: T?

        /// Constructor
        init() {
        }

        /// Constructor with an initial content
        ///
        /// - Parameter content: initial content
        init(content: T) {
            self.content = content
        }
    }

    /// Root node
    private let root = Node()

    /// Constructor
    init() {
        root.next = root
        root.prev = root
    }

    /// Push a node on the list head
    ///
    /// - Parameter node: note to push. It will become the first element of the list.
    func insert(_ node: LinkedList<T>.Node) {
        root.next?.prev = node
        node.next = root.next
        node.prev = root
        root.next = node
    }

    /// Pop the node on the list head
    ///
    /// - Returns: first node, nil if the list is empty
    func pop() -> LinkedList<T>.Node? {
        guard let node = head() else {
            return nil
        }
        remove(node)
        return node
    }

    /// Pop the node on the list head
    ///
    /// - Returns: first node, nil if the list is empty
    func head() -> LinkedList<T>.Node? {
        let node = root.next
        if node !== root {
            return node
        }
        return nil
    }

    /// Queue a node at the tail of the list
    ///
    /// - Parameter node: node to queue. It will become the last element of the list
    func enqueue(_ node: LinkedList<T>.Node) {
        root.prev!.next = node
        node.next = root
        node.prev = root.prev
        root.prev = node
    }

    /// Queue a node at the tail of the list
    ///
    /// - Parameter node: node to queue. It will become the last element of the list
    func tail() -> LinkedList<T>.Node? {
        let node = root.prev
        if node !== root {
            return node
        }
        return nil
    }

    /// Remove a node from the list
    ///
    /// - Parameter node: node to remove
    func remove(_ node: LinkedList<T>.Node) {
         if let next = node.next, let prev = node.prev {
            next.prev = prev
            prev.next = next
            node.prev = nil
            node.next = nil
        }
    }

    /// Walk through the list in forward order
    ///
    /// - Parameter until: closure called for each node, while it return true
    func walk(while: (LinkedList<T>.Node) -> Bool) {
        var node = root.next!
        // preload next to allow closure to remove current node
        var next = node.next!
        while node !== root && `while`(node) {
            node = next
            next = node.next!
        }
    }

    /// Walk through the list in reverse order
    ///
    /// - Parameter until: closure called for each node, while it return true
    func reverseWalk(while: (LinkedList<T>.Node) -> Bool) {
        var node = root.prev!
        // preload previous to allow closure to remove current node
        var prev = node.prev!
        while node !== root && `while`(node) {
            node = prev
            prev = node.prev!
        }
    }

    /// Remove all items from the list
    func reset() {
        root.next = root
        root.prev = root
    }
}
