const std = @import("std");
const ui = @import("ui.zig");
const card = @import("card.zig");
const builtin = @import("builtin");
const game = @import("game.zig");

pub const std_options = @import("logger.zig").options;
const WinKernel = std.os.windows.kernel32;

fn nextTurn(gamestate: *game.GameState) usize {
    switch (gamestate.gameDirection) {
        .FORWARD => {
            gamestate.turn += 1;
            if (gamestate.turn >= gamestate.numPlayers) gamestate.turn = 0;
        },
        .BACKWARD => {
            if (gamestate.turn == 0) gamestate.turn = gamestate.numPlayers;
            gamestate.turn -= 1;
        },
    }
    return gamestate.turn;
}

fn chooseColor(writer: *std.Io.Writer, reader: *std.Io.Reader, gamestate: *game.GameState) !void {
    const cardColorNumber = try ui.chooseColorScreen(writer, reader);
    const color: card.CardColor = switch (cardColorNumber) {
        1 => .YELLOW,
        2 => .RED,
        3 => .GREEN,
        else => .BLUE,
    };

    const currentTopCard = gamestate.topCard;
    const newTopCard = try card.Card.init(color, currentTopCard.value);
    gamestate.topCard = newTopCard;
}

pub fn main() !void {
    // set windows to use UTF-8 Characters
    if (builtin.os.tag == .windows) {
        _ = WinKernel.SetConsoleOutputCP(65001);
    }

    var stdoutBuffer: [1024]u8 = undefined;
    var getStdOut = std.fs.File.stdout().writer(&stdoutBuffer);
    const stdout = &getStdOut.interface;

    var stdinBuffer: [1024]u8 = undefined;
    var getStdIn = std.fs.File.stdin().reader(&stdinBuffer);
    const stdin = &getStdIn.interface;

    const time: i128 = std.time.nanoTimestamp();
    const bitTime: u128 = @bitCast(time);
    const seed: u64 = @truncate(bitTime);
    var rng = std.Random.DefaultPrng.init(seed);
    const rand = rng.random();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Start the Game
    // try ui.startScreen(stdout, stdin);
    try ui.clearScreen(stdout);

    var gamestate = try game.GameState.init(allocator, rand);
    try gamestate.initPlayers(allocator, rand, stdin, stdout);

    // Main Game Loop
    while (true) {
        try ui.clearScreen(stdout);
        try ui.gameFrame(stdout, stdin, gamestate);
        try ui.moveCursor(stdout, 50, 5);
        try stdout.flush();
        try ui.setColor(stdout, .WHITE, null);

        // read input
        while (true) {
            const waitInput = try stdin.takeDelimiterExclusive('\n');
            const trimmedInput = std.mem.trimRight(u8, waitInput, "\r"); // remove the stupid windows \r

            if (std.mem.eql(u8, trimmedInput, "d")) {
                try gamestate.drawCard(allocator, rand, gamestate.turn, 1);
                break;
            }

            const input = std.fmt.parseInt(u8, trimmedInput, 10) catch 0;
            const valid = gamestate.playCard(gamestate.turn, input);
            if (valid) break;
        }

        if (gamestate.players.items[gamestate.turn].hand.items.len == 0) {
            // TODO: Create win page
            break;
        }

        // special actions for cards
        switch (gamestate.topCard.value) {
            .NUMBER => {},
            .REVERSE => {
                gamestate.gameDirection = switch (gamestate.gameDirection) {
                    .BACKWARD => .FORWARD,
                    .FORWARD => .BACKWARD,
                };
            },
            .SKIP => {
                _ = nextTurn(&gamestate);
            },
            .DRAW2 => {
                const nextPlayer = nextTurn(&gamestate);
                try gamestate.drawCard(allocator, rand, nextPlayer, 2);
            },
            .WILD => {
                try chooseColor(stdout, stdin, &gamestate);
            },
            .WILD4 => {
                const nextPlayer = nextTurn(&gamestate);
                try gamestate.drawCard(allocator, rand, nextPlayer, 4);
                try chooseColor(stdout, stdin, &gamestate);
            },
        }

        _ = nextTurn(&gamestate);
    }

    try stdout.flush();
}
