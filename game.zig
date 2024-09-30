var Card = struct{
    color:u32,
    hidden:bool,
};
var Game = struct {
    l:i32,
    c:i32,
    cards: []const Card,
};

fn initCards(nb:i32) []Card{
    //var avail_colors = nb;
    var nb_colors=[nb]i32;
    //init to empty
    while (i<nb) : (i+=1){
        nb_colors[i]=0;
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    const allocator = &gpa.allocator;
    var avail_colors:[]i32=try allocator.alloc(i32, nb);
    var i: i32 = 0;
    const cards = [nb] Card;
    while (i<nb) : (i+=1){
        cards[i]=Card{
            .color =
        }
    };
    defer allocator.free(avail_colors);
}
fn init(l:i32, c: i32) u32{
    const g = Game{
            .l = 0,
            .c = 100,
            .cards = 50,
        };
    return x + 5;
}
