// BoardView.swift
// Author: David M. Anderson
// Built with AI assistance (Claude, Anthropic)

import SwiftUI

/// The playing field: a selector row above a 7 × 6 board, laid out on a grid of square cells
/// sized to fit. Discs sit behind the frame, so a falling disc shows through the holes.
///
/// On the watch, sliding sideways moves the hovering disc one column per cell of travel from where
/// it started, and swiping down drops it. On iPhone, the disc follows the finger and drops when it
/// lifts. VoiceOver plays a column by activating it.
struct BoardView: View {
    let board: Board
    var hover: (player: Player, column: Int)?
    var lastDrop: Position?
    var winningCells: Set<Position> = []
    var onSelectColumn: (Int) -> Void = { _ in }
    var onDrop: () -> Void = {}
    var onPlayColumn: (Int) -> Void = { _ in }
    #if os(watchOS)
    @State private var slideStartColumn: Int?
    #endif

    private static let fieldRows = Board.rows + 1

    var body: some View {
        GeometryReader { geometry in
            let cell = min(geometry.size.width / CGFloat(Board.columns),
                           geometry.size.height / CGFloat(Self.fieldRows))
            let field = CGRect(x: (geometry.size.width - cell * CGFloat(Board.columns)) / 2,
                               y: (geometry.size.height - cell * CGFloat(Self.fieldRows)) / 2,
                               width: cell * CGFloat(Board.columns),
                               height: cell * CGFloat(Self.fieldRows))
            ZStack(alignment: .topLeading) {
                if let hover {
                    DiscView(player: hover.player, size: discSize(cell))
                        .position(center(column: hover.column, fieldRow: 0, cell: cell))
                        .animation(.easeOut(duration: 0.15), value: hover.column)
                }
                ForEach(discs, id: \.position) { disc in
                    PlacedDisc(player: disc.player,
                               size: discSize(cell),
                               fallDistance: disc.position == lastDrop ? fallDistance(to: disc.position, cell: cell) : 0,
                               isWinning: winningCells.contains(disc.position),
                               isDimmed: !winningCells.isEmpty && !winningCells.contains(disc.position))
                        .position(center(column: disc.position.column, fieldRow: fieldRow(disc.position.row), cell: cell))
                }
                BoardFrame(cell: cell)
                    .fill(Color.boardBlue, style: FillStyle(eoFill: true))
                    .frame(width: cell * CGFloat(Board.columns), height: cell * CGFloat(Board.rows))
                    .offset(y: cell)
                columnTargets(cell: cell)
            }
            .frame(width: field.width, height: field.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(dropGesture(in: field))
        }
    }

    #if os(watchOS)
    private func dropGesture(in field: CGRect) -> some Gesture {
        let cell = field.width / CGFloat(Board.columns)
        return DragGesture(minimumDistance: 6)
            .onChanged { value in
                let travel = value.translation
                guard let hover, abs(travel.width) > abs(travel.height) else { return }
                let start = slideStartColumn ?? hover.column
                slideStartColumn = start
                let column = start + Int((travel.width / cell).rounded())
                onSelectColumn(column.clamped(to: 0...(Board.columns - 1)))
            }
            .onEnded { value in
                slideStartColumn = nil
                let down = max(value.translation.height, value.predictedEndTranslation.height)
                if down > cell, down > abs(value.translation.width) {
                    onDrop()
                }
            }
    }
    #else
    /// Lifting the finger off the board drops; lifting it anywhere else cancels.
    private func dropGesture(in field: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                onSelectColumn(column(at: value.location, in: field))
            }
            .onEnded { value in
                guard field.contains(value.location) else { return }
                onSelectColumn(column(at: value.location, in: field))
                onDrop()
            }
    }

    private func column(at location: CGPoint, in field: CGRect) -> Int {
        Int((location.x - field.minX) / field.width * CGFloat(Board.columns)).clamped(to: 0...(Board.columns - 1))
    }
    #endif

    private var discs: [(position: Position, player: Player)] {
        (0..<Board.columns).flatMap { column in
            (0..<Board.rows).compactMap { row in
                let position = Position(column: column, row: row)
                return board[position].map { (position, $0) }
            }
        }
    }

    private func columnTargets(cell: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<Board.columns, id: \.self) { column in
                Color.clear
                    .accessibilityElement()
                    .accessibilityLabel("Column \(column + 1), \(board.emptyCount(in: column)) empty")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { onPlayColumn(column) }
            }
        }
        .frame(width: cell * CGFloat(Board.columns), height: cell * CGFloat(Self.fieldRows))
    }

    private func discSize(_ cell: CGFloat) -> CGFloat {
        cell * 0.84
    }

    private func fieldRow(_ boardRow: Int) -> Int {
        Board.rows - boardRow
    }

    private func center(column: Int, fieldRow: Int, cell: CGFloat) -> CGPoint {
        CGPoint(x: (CGFloat(column) + 0.5) * cell, y: (CGFloat(fieldRow) + 0.5) * cell)
    }

    private func fallDistance(to position: Position, cell: CGFloat) -> CGFloat {
        CGFloat(fieldRow(position.row)) * cell
    }
}

/// A disc on the board. A disc created with a fall distance starts that far up and springs down.
private struct PlacedDisc: View {
    let player: Player
    let size: CGFloat
    let isWinning: Bool
    let isDimmed: Bool
    private let fallDistance: CGFloat
    @State private var hasLanded: Bool
    @State private var isPulsing = false

    init(player: Player, size: CGFloat, fallDistance: CGFloat, isWinning: Bool, isDimmed: Bool) {
        self.player = player
        self.size = size
        self.fallDistance = fallDistance
        self.isWinning = isWinning
        self.isDimmed = isDimmed
        _hasLanded = State(initialValue: fallDistance == 0)
    }

    var body: some View {
        DiscView(player: player, size: size)
            .overlay {
                if isWinning {
                    Circle().strokeBorder(.white, lineWidth: max(1.5, size * 0.12))
                }
            }
            .scaleEffect(isPulsing ? 1.12 : 1)
            .opacity(isDimmed ? 0.4 : 1)
            .offset(y: hasLanded ? 0 : -fallDistance)
            .onAppear {
                if !hasLanded {
                    withAnimation(.spring(duration: 0.25, bounce: 0.2)) { hasLanded = true }
                }
            }
            .onChange(of: isWinning, initial: true) {
                guard isWinning else { return }
                withAnimation(.easeInOut(duration: 0.5).repeatForever()) { isPulsing = true }
            }
    }
}

/// The blue frame with one hole per cell.
struct BoardFrame: Shape {
    static let holeRatio: CGFloat = 0.8

    let cell: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: cell * 0.2)
        let inset = cell * (1 - Self.holeRatio) / 2
        for column in 0..<Board.columns {
            for row in 0..<Board.rows {
                let cellRect = CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: cell, height: cell)
                path.addEllipse(in: cellRect.insetBy(dx: inset, dy: inset))
            }
        }
        return path
    }
}
