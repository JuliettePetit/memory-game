const std = @import("std");

const Game = struct {
    cards: []u32,
    hidden: []bool,
    first_pick: ?usize = null,
    pairs_found: usize = 0,
};

var buf: [1024 * 1024]u8 = undefined; // 1MB
var fba = std.heap.FixedBufferAllocator.init(&buf);
const allocator = fba.allocator();

var prng = std.Random.DefaultPrng.init(0);
extern fn jsSeed() u64;

export fn seedRng() void {
    prng = std.Random.DefaultPrng.init(jsSeed());
}

fn initCards(nb: usize) ![]u32 {
    const nb_colors = nb / 2;

    var avail_colors: []usize = try allocator.alloc(usize, nb_colors);
    defer allocator.free(avail_colors);
    @memset(avail_colors, 2);

    var cards: []u32 = try allocator.alloc(u32, nb);
    var i: usize = 0;
    while (i < nb) : (i += 1) {
        var d: usize = prng.random().intRangeLessThan(usize, 0, nb_colors);
        while (avail_colors[d] == 0) {
            d = prng.random().intRangeLessThan(usize, 0, nb_colors);
        }
        cards[i] = @intCast(d);
        avail_colors[d] -= 1;
    }
    return cards;
}

export fn getCards(g: *Game) [*]u32 {
    return g.cards.ptr;
}

export fn getHiddenCards(g: *Game) [*]bool {
    return g.hidden.ptr;
}

export fn init(nb: usize) ?*Game {
    const g = allocator.create(Game) catch return null;
    g.* = Game{
        .cards = initCards(nb) catch {
            allocator.destroy(g);
            return null;
        },
        .hidden = allocator.alloc(bool, nb) catch {
            allocator.destroy(g);
            return null;
        },
    };
    @memset(g.hidden, true);
    return g;
}

/// 0 = no match
/// 1 = single
/// 2 = match
export fn selectCard(g: *Game, index: usize) i32 {
    if (g.first_pick != null) {
        if (g.first_pick == index)
            return 1;
        const matched = flipCardIfMatching(g, index);
        if (matched) g.pairs_found += 1;
        g.first_pick = null;
        return if (matched) 2 else 0;
    } else g.first_pick = index;
    return 1;
}

fn flipCardIfMatching(g: *Game, index: usize) bool {
    const first = g.first_pick.?;
    if (g.cards[index] == g.cards[first]) {
        g.hidden[index] = false;
        g.hidden[first] = false;
        return true;
    }
    return false;
}

export fn gameEnd(g: *Game) bool {
    var i: usize = 0;
    while (i < g.hidden.len) {
        if (g.hidden[i]) {
            return false;
        }
        i += 1;
    }
    return true;
}

fn getCardsNumber(g: *Game) usize {
    return g.cards.len;
}

export fn delete(g: *Game) void {
    defer allocator.free(g.cards);
}

////// clock/////////
const digit_patterns: [10][5]u8 = .{
    .{ 0b0110, 0b1001, 0b1001, 0b1001, 0b0110 }, // 0
    .{ 0b0010, 0b0110, 0b0010, 0b0010, 0b0010 }, // 1
    .{ 0b1110, 0b0001, 0b1111, 0b1000, 0b1111 }, // 2
    .{ 0b1110, 0b0001, 0b0110, 0b0001, 0b1110 }, // 3
    .{ 0b1001, 0b1001, 0b0111, 0b0001, 0b0001 }, // 4
    .{ 0b1111, 0b1000, 0b1111, 0b0001, 0b1110 }, // 5
    .{ 0b0110, 0b1000, 0b1110, 0b1001, 0b0110 }, // 6
    .{ 0b1111, 0b0001, 0b0010, 0b0100, 0b0100 }, // 7
    .{ 0b0110, 0b1001, 0b0110, 0b1001, 0b0110 }, // 8
    .{ 0b0110, 0b1001, 0b0111, 0b0001, 0b0110 }, // 9

};
const H = 5;
const W = 4 * 4 + 5;
var clock_buffer: [W * H]bool = undefined;

export fn getBufferPtr() [*]bool {
    return &clock_buffer;
}

export fn getBufferLen() usize {
    return W * H;
}

export fn updateClock(minutes: u8, seconds: u8) void {
    clearBuffer();
    const m1: u8 = minutes / 10;
    const m2: u8 = minutes % 10;
    const s1: u8 = seconds / 10;
    const s2: u8 = seconds % 10;

    writeDigit(m1, 0);
    writeDigit(m2, 5);
    writeDigit(s1, 12);
    writeDigit(s2, 17);
}
fn clearBuffer() void {
    @memset(&clock_buffer, false);
    clock_buffer[1 * W + 10] = true;
    clock_buffer[3 * W + 10] = true;
}

fn writeDigit(digit: u8, x_offset: usize) void {
    const pattern = digit_patterns[digit];
    for (pattern, 0..) |row, y| {
        for (0..4) |x| {
            const bit_set = (row >> @intCast(3 - x)) & 1 == 1;
            clock_buffer[y * W + x_offset + x] = bit_set;
        }
    }
}
