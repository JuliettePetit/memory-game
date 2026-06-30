const std = @import("std");

const Game = struct {
    cards: []u32,
    first_pick: ?usize = null, // index of first flipped card this turn
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
    var i: usize = 0;
    while (i < nb_colors) : (i += 1) {
        avail_colors[i] = 2;
    }

    var cards: []u32 = try allocator.alloc(u32, nb);
    i = 0;
    while (i < nb) : (i += 1) {
        var d: usize = prng.random().intRangeLessThan(usize, 0, nb_colors);
        while (avail_colors[d] == 0) {
            d = prng.random().intRangeLessThan(usize, 0, nb_colors);
        }
        cards[i] = @intCast(d);
        avail_colors[d] -= 1;
    }
    defer allocator.free(avail_colors);
    return cards;
}

export fn getCards(g: *Game) [*]u32 {
    return g.cards.ptr;
}

export fn init(nb: usize) ?*Game {
    const g = allocator.create(Game) catch return null;
    g.* = Game{
        .cards = initCards(nb) catch {
            allocator.destroy(g);
            return null;
        },
    };
    return g;
}

fn playRound(c1: u32, c2: (u32)) void {
    if (c1.color == c2.color) {
        c1.hidden = false;
        c2.hidden = false;
    }
}

//export fn selectCard(g: *Game, index: usize) bool {}

//fn flipCard(g: *Game, index: usize) void {}

//export fn resetUnmatched(g: *Game) void {}

fn gameEnd(g: *Game) bool {
    for (g.cards) |card| {
        if (card.hidden) {
            return false;
        }
    }
    return true;
}

fn getCardsNumber(g: *Game) usize {
    return g.cards.len;
}

fn getCardColor(card: u32) i32 {
    return card.color;
}

fn isCardHidden(card: u32) bool {
    return card.hidden;
}

export fn delete(g: *Game) void {
    defer allocator.free(g.cards);
}
