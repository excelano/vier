// Clamped.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
