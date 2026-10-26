# Vier

Vier is four in a row for iPhone and Apple Watch: drop red discs into a seven-by-six board against yellow, and line up four across, down or diagonally first. The opponent is the device itself, and the watch app runs on its own, without the iPhone nearby. Vier has no account, no network, no ads and no analytics. It opens straight into a game, picks up where it left off, and has an Easy level built for beginners.

## Playing

Slide a finger sideways on the board to move the red disc over a column, then swipe down to drop it; on the watch the Digital Crown moves it too. A tap does nothing, so a stray touch can't play a move. The opponent thinks for a moment, slides its own disc over and drops it. Who moves first alternates from game to game. When someone lines up four, those discs are ringed and pulse, and the game offers Play again or Home.

Easy, Medium and Hard set how far ahead the opponent looks and how often it plays a random move instead. Every level takes a winning move when it has one; Medium and Hard also always block yours.

The Players setting on the home screen switches to two players, where two people take turns on one device with no Difficulty setting.

The iPhone and the watch each keep their own settings and their own game; nothing passes between them.

## Building

Open `Vier.xcodeproj` in Xcode. The `Vier` scheme builds the iPhone app with the watch app embedded, and is the one a release archives. The `Vier Watch App` scheme builds the watch app alone for a watch or the simulator and runs the tests.

Nearly all the code lives in `Shared/`, which both apps compile; `#if os(watchOS)` marks what only the watch does, chiefly the Digital Crown. `Vier/` and `Vier Watch App/` hold each app's icon and the code that plays its haptics. The identity a fork changes, meaning the team id, the bundle ids and the display name, lives in `Config/Vier.xcconfig`, and the version in `Config/Version.xcconfig`. The project has no dependencies beyond Apple's frameworks.

The computer opponent is a negamax search with alpha-beta pruning in `Shared/Engine/`, which imports nothing, so it has no tie to the interface and is tested directly on board positions.

## Privacy

Vier makes no network connection. On each device it keeps the chosen difficulty, whether one or two players are at the board, the game in progress and who moves first next, and nothing else. The full statement is at [excelano.com/legal/#vier](https://excelano.com/legal/#vier).

## License

MIT. See [LICENSE](LICENSE).
