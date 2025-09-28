const std = @import("std");
const Card = @import("card.zig").Card;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

const PlayerType = enum { HUMAN, AI };

const Player = struct {
    name: []const u8,
    hand: ArrayList(Card),
    playerType: PlayerType,

    pub fn init(allocator: Allocator, name: []const u8, playerType: PlayerType) !Player {
        return .{
            .name = name,
            .playerType = playerType,
            .hand = try ArrayList(Card).initCapacity(allocator, 20),
        };
    }

    pub fn deinit(self: *Player, allocator: Allocator) void {
        self.hand.deinit(allocator);
    }
};

test "Allacotor free memory" {
    const gpa = std.testing.allocator;
    var player1 = try Player.init(gpa, "Ash", .HUMAN);
    defer player1.deinit(gpa);
}

test "fields all assigned" {
    const gpa = std.testing.allocator;
    var player1 = try Player.init(gpa, "Ash", .HUMAN);
    defer player1.deinit(gpa);

    try expect(player1.playerType == .HUMAN);
    try expect(std.mem.eql(u8, player1.name, "Ash"));
}
