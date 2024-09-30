const std = @import("std");

var Card = struct{
    color:u32,
    hidden:bool=true,
};
var Game = struct {
    l:i32,
    c:i32,
    cards: []const Card,
};
fn setRequired()void{
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    return prng.random();
}
const rand = setRequired();


fn initCards(nb:i32) []Card{
    //var avail_colors = nb;
    var nb_colors=[nb/2]i32;
    //init to empty
    var i: i32 = 0;
    while (i<nb) : (i+=1){
        nb_colors[i]=0;
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    const allocator = &gpa.allocator;
    var avail_colors:[]i32=try allocator.alloc(i32, nb_colors);
    while (i<nb_colors) : (i +=1){
            avail_colors[i]=2;
        }
    i = 0;
    const cards = [nb] Card;
    var d : i32 = 0;
    while (i<nb) : (i+=1){
        while (avail_colors[d]==0){
            d = rand.intRangeAtMost(u8, 0, nb_colors);
        }
        cards[i]=Card{
            .color = avail_colors[d],
        };
    }
    defer allocator.free(avail_colors);
    return cards;
}
fn arrayTo2d (i:i32, c:i32) struct {x:32, y:i32}{
    return .{.x=i/c,.y=@mod(i, c)};
}
fn init() Game{
    const g = Game{
        .l = 0,
        .c = 100,
        .cards = initCards(50),
    };
    return g;
}

fn playGame() void{
    const g = init();
    while(gameEnd(g)){

    }
}

fn gameEnd(g: Game) bool
{
    for (g.cards) |card| {
        if(card.hidden){
            return false;
        }
    }
    return true;
}
