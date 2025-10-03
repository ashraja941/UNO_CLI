# UNO on the Command Line

A command-line card game built with Zig, inspired by the classic game UNO.

## Description

This project is a recreation of the popular card game UNO, implemented in the Zig programming language. It's a work in progress, but the basic framework for the game is in place. The game is played in the terminal and uses ANSI escape codes to render the cards with colors.

## Features

*   Play against AI or human opponents.
*   Colored card rendering in the terminal.
*   Basic game logic for card types and game flow.

## Getting Started

### Prerequisites

*   [Zig](https://ziglang.org/learn/getting-started/) (version 0.15.1 or higher)

### Building and Running

1.  **Clone the repository:**
    ```sh
    git clone <repository-url>
    cd recreate
    ```

2.  **Build the executable:**
    ```sh
    zig build
    ```
    This will create an executable in the `zig-out/bin` directory.

3.  **Run the application:**
    ```sh
    zig build run
    ```

4.  **Run the tests:**
    ```sh
    zig build test
    ```

## How to Play

The game follows the standard rules of UNO.

### Objective

The first player to get rid of all their cards wins the round. Points are scored based on the cards remaining in the opponents' hands. The first player to reach 500 points wins the game.

### Gameplay

1.  Each player is dealt 7 cards.
2.  The remaining cards are placed in a draw pile, and the top card is flipped to start the discard pile.
3.  Players take turns matching the top card of the discard pile by number, color, or action.
4.  If a player cannot play a card, they must draw a card from the draw pile.
5.  When a player has one card left, they must call "UNO!".
6.  The game continues until a player has no cards left.

### Special Cards

*   **Skip:** The next player's turn is skipped.
*   **Reverse:** The direction of play is reversed.
*   **Draw Two:** The next player must draw two cards and loses their turn.
*   **Wild:** The player who plays this card can choose the color of play.
*   **Wild Draw Four:** The player who plays this card can choose the color of play, and the next player must draw four cards and lose their turn.

## Future Scope / TODO

This project is still under development. Here are some of the features and improvements planned for the future:

*   [x] Implement the main game loop.
*   [x] Implement the complete game logic for all card types.
*   [ ] Implement AI for computer-controlled players.
*   [ ] Add a scoring system.
*   [ ] Improve the user interface and user experience.
*   [ ] Add more tests to ensure the game is working correctly.
