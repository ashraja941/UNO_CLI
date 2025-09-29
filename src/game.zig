const std = @import("std");
const ui = @import("ui.zig");
const Player = @import("player.zig").Player;
const Card = @import("card.zig").Card;
const CardType = @import("card.zig").CardType;
const CardColor = @import("card.zig").CardColor;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const expect = std.testing.expect;

const GameDirection = enum { FORWARD, BACKWARD };

const aiNames = [_][]const u8{
    "Alice",
    "Alex",
    "Ashwin",
    "Andrea",
    "Andrew",
    "Augustine",
    "Aarya",
    "Amy",
    "Sway",
    "Asahino",
};

const CardWeight = struct {
    kind: CardType,
    weight: u4,
};

const weights = [_]CardWeight{
    .{ .kind = .{ .NUMBER = 0 }, .weight = 10 },
    .{ .kind = .SKIP, .weight = 1 },
    .{ .kind = .REVERSE, .weight = 1 },
    .{ .kind = .DRAW2, .weight = 1 },
    .{ .kind = .WILD, .weight = 1 },
    .{ .kind = .WILD4, .weight = 1 },
};

fn weightedChoice(rand: std.Random, table: []const CardWeight) CardType {
    var total: u8 = 0;
    for (table) |entry| {
        total += entry.weight;
    }

    const roll = rand.uintLessThan(u8, total);

    var cumilative: usize = 0;
    for (table) |entry| {
        cumilative += entry.weight;
        if (roll < cumilative) return entry.kind;
    }
    unreachable;
}

fn randomCard(rand: std.Random) !Card {
    const kind = weightedChoice(rand, &weights);

    const color: CardColor = switch (kind) {
        .WILD, .WILD4 => .WILDCOLOR,
        else => col: {
            while (true) {
                const currentColor = rand.enumValue(CardColor);
                if (currentColor != .WILDCOLOR)
                    break :col currentColor;
            }
        }
    };

    return switch (kind) {
        .NUMBER => try Card.init(color, .{ .NUMBER = rand.intRangeLessThan(u4, 0, 10) }),
        else => try Card.init(color, kind)
    };
}

fn validPlay(card1: Card, card2: Card) bool {
    if ((card1.color == card2.color) or (card1.color == .WILDCOLOR) or (card2.color == .WILDCOLOR)) return true;
    if (@intFromEnum(card1.value) != @intFromEnum(card2.value)) return false;

    return switch (card1.value) {
        .NUMBER => |an| card2.value.NUMBER == an,
        else => true
    };
}

pub const GameState = struct {
    players: ArrayList(Player),
    gameDirection: GameDirection,
    turn: usize,
    topCard: Card,

    pub fn init(allocator: Allocator, rand: std.Random) !GameState {
        return .{
            .players = try ArrayList(Player).initCapacity(allocator, 4),
            .gameDirection = .FORWARD,
            .turn = 0,
            .topCard = try randomCard(rand),
        };
    }

    pub fn deinit(self: *GameState, allocator: Allocator) void {
        for (self.players.items) |*p| {
            p.deinit(allocator);
        }
        self.players.deinit(allocator);
    }

    pub fn initPlayers(self: *GameState, allocator: Allocator, rand: std.Random, reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
        try writer.print("Enter the number of Human Players : ", .{});
        try writer.flush();
        const humanLine = try reader.takeDelimiterExclusive('\n');
        const trimmedHuman = std.mem.trimRight(u8, humanLine, "\r"); // remove the stupid windows \r
        const numHumans = try std.fmt.parseInt(u8, trimmedHuman, 10);

        try writer.print("Enter the number of AI Players    : ", .{});
        try writer.flush();
        const aiLine = try reader.takeDelimiterExclusive('\n');
        const trimmedAi = std.mem.trimRight(u8, aiLine, "\r"); // remove the stupid windows \r
        const numAi = try std.fmt.parseInt(u8, trimmedAi, 10);

        var names = try ArrayList([]u8).initCapacity(allocator, 2);
        defer {
            for (names.items) |n| allocator.free(n);
            names.deinit(allocator);
        }

        for (0..(numHumans)) |i| {
            try writer.print("Enter name of player {d} : ", .{i + 1});
            try writer.flush();
            const nameLine = try reader.takeDelimiterExclusive('\n');
            const owned = try allocator.alloc(u8, nameLine.len);
            std.mem.copyForwards(u8, owned, nameLine);
            try names.append(allocator, owned);
        }

        for (0..(numAi)) |i| {
            // TODO: Choose random names from a list
            const nameLine = aiNames[i];
            const owned = try allocator.alloc(u8, nameLine.len);
            std.mem.copyForwards(u8, owned, nameLine);
            try names.append(allocator, owned);
        }

        for (names.items) |n| {
            var player = try Player.init(allocator, n, .HUMAN);
            for (0..7) |_| {
                const card = try randomCard(rand);
                try player.hand.append(allocator, card);
            }
            try self.players.append(allocator, player);
        }

        // Print all the values for debugging reasons
        // for (self.players.items) |p| {
        //     try writer.print("player info : {s}\t{any}\n", .{ p.name, p.hand });
        // }
    }

    pub fn printGameStates(self: GameState) void {
        std.debug.print("Current state: \ndirection : {any}\nTop Card : {any}, Turn : {any}, \n", .{ self.gameDirection, self.topCard, self.turn });
        for (self.players.items) |p| {
            std.debug.print("{any}\n", .{p.hand});
        }
    }

    pub fn changeTopCard(self: *GameState, card: Card) void {
        self.topCard = card;
    }

    pub fn addCardToPlayer(self: *GameState, allocator: Allocator, playerIndex: usize, card: Card) !void {
        try self.players.items[playerIndex].hand.append(allocator, card);
    }

    pub fn removeCardFromPlayer(self: *GameState, playerIndex: usize, cardIndex: usize) !void {
        const removed = self.players.items[playerIndex].hand.orderedRemove(cardIndex);
        _ = removed;
    }

    pub fn playCard(self: *GameState, playerIndex: usize, cardIndex: usize) bool {
        const card = self.players.items[playerIndex].hand.items[cardIndex];

        if (validPlay(self.topCard, card)) {
            self.topCard = card;
            try self.removeCardFromPlayer(playerIndex, cardIndex);
            return true;
        }
        return false;
    }

    pub fn drawCard(self: GameState, rand: std.Random, playerIndex: usize, num: usize) !void {
        for (0..num) |_| {
            const card = try randomCard(rand);
            try self.addCardToPlayer(Allocator, playerIndex, card);
        }
    }
};

test "memory leak" {
    const time: i128 = std.time.nanoTimestamp();
    const bitTime: u128 = @bitCast(time);
    const seed: u64 = @truncate(bitTime);
    var rng = std.Random.DefaultPrng.init(seed);
    const rand = rng.random();

    const allocator = std.testing.allocator;
    var game = try GameState.init(allocator, rand);
    defer game.deinit(allocator);

    try game.players.append(allocator, try Player.init(allocator, "Ash", .HUMAN));
}

test "random choice" {
    var rng = std.Random.DefaultPrng.init(2);
    const rand = rng.random();
    std.debug.print("random choice: {any}\n", .{weightedChoice(rand, &weights)});
}

test "random Card" {
    const time: i128 = std.time.nanoTimestamp();
    const bitTime: u128 = @bitCast(time);
    const seed: u64 = @truncate(bitTime);
    var rng = std.Random.DefaultPrng.init(seed);
    const rand = rng.random();

    const card = try randomCard(rand);

    std.debug.print("random card: {any}\n", .{card});
}

test "test 1000 times" {
    for (0..100000) |_| {
        const time: i128 = std.time.nanoTimestamp();
        const bitTime: u128 = @bitCast(time);
        const seed: u64 = @truncate(bitTime);
        var rng = std.Random.DefaultPrng.init(seed);

        const rand = rng.random();
        const card = try randomCard(rand);
        _ = card;
    }
    // std.debug.print("Passed 100000 times", .{});
}

test "print" {
    const time: i128 = std.time.nanoTimestamp();
    const bitTime: u128 = @bitCast(time);
    const seed: u64 = @truncate(bitTime);
    var rng = std.Random.DefaultPrng.init(seed);
    const rand = rng.random();

    const allocator = std.testing.allocator;
    var game = try GameState.init(allocator, rand);
    defer game.deinit(allocator);

    try game.players.append(allocator, try Player.init(allocator, "Ash", .HUMAN));
    game.printGameStates();
}

test "changed top card" {
    const time: i128 = std.time.nanoTimestamp();
    const bitTime: u128 = @bitCast(time);
    const seed: u64 = @truncate(bitTime);
    var rng = std.Random.DefaultPrng.init(seed);
    const rand = rng.random();

    const allocator = std.testing.allocator;
    var game = try GameState.init(allocator, rand);
    defer game.deinit(allocator);

    const card = try Card.init(.GREEN, .SKIP);
    game.changeTopCard(card);
    const topCard = game.topCard;

    try expect(switch (card.value) {
        .NUMBER => |an| switch (topCard.value) {
            .NUMBER => |bn| an == bn,
            else => unreachable,
        },
        else => true,
    });
    try expect(card.color == topCard.color);
}

test "addCardToPlayer adds a card to the player's hand" {
    const time: i128 = std.time.nanoTimestamp();
    const bitTime: u128 = @bitCast(time);
    const seed: u64 = @truncate(bitTime);
    var rng = std.Random.DefaultPrng.init(seed);
    const rand = rng.random();

    const allocator = std.testing.allocator;
    var game = try GameState.init(allocator, rand);
    defer game.deinit(allocator);

    try game.players.append(allocator, try Player.init(allocator, "Ash", .HUMAN));

    const card = try Card.init(.RED, .{ .NUMBER = 5 });
    try game.addCardToPlayer(allocator, 0, card);

    try expect(game.players.items[0].hand.items.len == 1);
    try expect(game.players.items[0].hand.items[0].color == .RED);
    try expect(switch (game.players.items[0].hand.items[0].value) {
        .NUMBER => |n| n == 5,
        else => false,
    });
}

test "removeCardFromPlayer removes the correct card" {
    const time: i128 = std.time.nanoTimestamp();
    const bitTime: u128 = @bitCast(time);
    const seed: u64 = @truncate(bitTime);
    var rng = std.Random.DefaultPrng.init(seed);
    const rand = rng.random();

    const allocator = std.testing.allocator;
    var game = try GameState.init(allocator, rand);
    defer game.deinit(allocator);

    try game.players.append(allocator, try Player.init(allocator, "Ash", .HUMAN));

    const card1 = try Card.init(.GREEN, .{ .NUMBER = 7 });
    const card2 = try Card.init(.BLUE, .SKIP);
    try game.addCardToPlayer(allocator, 0, card1);
    try game.addCardToPlayer(allocator, 0, card2);

    try expect(game.players.items[0].hand.items.len == 2);

    // Remove index 0 → card1 should be gone, card2 should shift to index 0
    try game.removeCardFromPlayer(0, 0);

    try expect(game.players.items[0].hand.items.len == 1);
    try expect(game.players.items[0].hand.items[0].color == .BLUE);
    try expect(switch (game.players.items[0].hand.items[0].value) {
        .SKIP => true,
        else => false,
    });
}

test "validPlay same color different number" {
    const c1 = try Card.init(.RED, .{ .NUMBER = 5 });
    const c2 = try Card.init(.RED, .{ .NUMBER = 7 });
    try expect(validPlay(c1, c2));
}

test "validPlay same number different color" {
    const c1 = try Card.init(.RED, .{ .NUMBER = 5 });
    const c2 = try Card.init(.BLUE, .{ .NUMBER = 5 });
    try expect(validPlay(c1, c2));
}

test "validPlay different number and color but same action" {
    const c1 = try Card.init(.RED, .SKIP);
    const c2 = try Card.init(.BLUE, .SKIP);
    try expect(validPlay(c1, c2));
}

test "validPlay wild card is always valid" {
    const wild = try Card.init(.WILDCOLOR, .WILD);
    const c = try Card.init(.GREEN, .{ .NUMBER = 3 });
    try expect(validPlay(wild, c));
    try expect(validPlay(c, wild));
}

test "validPlay wild draw four is always valid" {
    const wild4 = try Card.init(.WILDCOLOR, .WILD4);
    const c = try Card.init(.YELLOW, .DRAW2);
    try expect(validPlay(wild4, c));
    try expect(validPlay(c, wild4));
}

test "validPlay fails on mismatch" {
    const c1 = try Card.init(.RED, .{ .NUMBER = 3 });
    const c2 = try Card.init(.BLUE, .{ .NUMBER = 7 });
    try expect(!validPlay(c1, c2));
}
