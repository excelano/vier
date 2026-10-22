# Vier

Vier is four in a row for Apple Watch: drop red discs into a seven-by-six board against the watch's yellow, and line up four across, down or diagonally before it does. It runs on the watch alone, with no iPhone app, no account, no network, no ads and no analytics. It opens straight into a game, picks up where it left off after a dropped wrist, and has an Easy level built for beginners.

## Playing

Turn the Digital Crown or slide a finger sideways on the board to move the disc above the columns, then swipe down to drop it. The watch thinks for a moment, slides its own disc over and drops it. Who moves first alternates from game to game. When someone lines up four, those discs are ringed and pulse, and the game offers Play again or Home.

Easy, Medium and Hard set how far ahead the watch looks and how often it plays a random move instead. Every level takes a winning move when it has one; Medium and Hard also always block yours.

The Players setting on the home screen switches to two players, where two people take turns on one watch with no Difficulty setting.

## Building

Open `Vier.xcodeproj` in Xcode. The `Vier Watch App` scheme builds the watch app for a watch or the simulator and runs the tests. The App Store accepts a watch-only app inside an iOS stub with no code, so the `Vier` scheme archives that stub with the watch app embedded.

The identity a fork changes, meaning the team id, the bundle ids and the display name, lives in `Config/Vier.xcconfig`, and the version in `Config/Version.xcconfig`. The project has no dependencies beyond Apple's frameworks.

The computer opponent is a negamax search with alpha-beta pruning in `Vier Watch App/Engine/`, which imports nothing, so it has no tie to the interface and is tested directly on board positions.

## Privacy

Vier makes no network connection. It keeps the chosen difficulty, the game in progress and who moves first next on the watch, and nothing else. The full statement is at [excelano.com/legal/#vier](https://excelano.com/legal/#vier).

## License

MIT. See [LICENSE](LICENSE).
