import Foundation

// MARK: - RingUndoManager

/// Simple stack-based undo/redo for ring items.
final class RingUndoManager {
    private var undoStack: [[RingItemV2]] = []
    private var redoStack: [[RingItemV2]] = []
    private let maxDepth = 20

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    /// Save current state before a mutation.
    func push(_ items: [RingItemV2]) {
        undoStack.append(items)
        if undoStack.count > maxDepth {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    /// Undo: returns previous state, or nil if nothing to undo.
    func undo(current: [RingItemV2]) -> [RingItemV2]? {
        guard let previous = undoStack.popLast() else { return nil }
        redoStack.append(current)
        return previous
    }

    /// Redo: returns next state, or nil if nothing to redo.
    func redo(current: [RingItemV2]) -> [RingItemV2]? {
        guard let next = redoStack.popLast() else { return nil }
        undoStack.append(current)
        return next
    }

    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
