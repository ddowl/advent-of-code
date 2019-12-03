import fileinput

# define up, down, left, right directions
U, D, L, R = (0, -1), (0, 1), (-1, 0), (1, 0)

# map input characters to directions
directions = {'^': U, 'v': D, '<': L, '>': R}

# map directions to new directions for various scenarios
straight = {U: U, D: D, L: L, R: R}
left_turn = {U: L, D: R, L: D, R: U}
right_turn = {U: R, D: L, L: U, R: D}
forward_slash_turn = {U: R, D: L, L: D, R: U}
back_slash_turn = {U: L, D: R, L: U, R: D}

class Cart:
    def __init__(self, p, d):
        self.p = p # position
        self.d = d # direction
        self.i = 0 # turn index
        self.ok = True # ok is set to False after a collision
    def step(self, grid):
        # make one step in the current direction
        self.p = (self.p[0] + self.d[0], self.p[1] + self.d[1])
        # lookup the grid character at the new position
        c = grid[self.p]
        if c == '+':
            # intersection; make a turn based on the current index
            turn = [left_turn, straight, right_turn][self.i % 3]
            self.d = turn[self.d]
            self.i += 1
        elif c == '/':
            self.d = forward_slash_turn[self.d]
        elif c == '\\':
            self.d = back_slash_turn[self.d]
    def hits(self, other):
        # return True if this cart hits the other
        return self != other and self.ok and other.ok and self.p == other.p

grid = {}  # grid maps (x, y) positions to characters from the input
carts = [] # carts is a list of Cart instances
for y, line in enumerate(fileinput.input()):
    for x, c in enumerate(line):
        grid[(x, y)] = c
        if c in directions:
            carts.append(Cart((x, y), directions[c]))

part1 = part2 = None
for i in range(10):
    # for each new tick, sort the carts by Y and then X
    carts = sorted(carts, key=lambda x: (x.p[1], x.p[0]))
    for cart in carts:
        # update this cart
        cart.step(grid)
        # check for collisions
        for other in carts:
            if cart.hits(other):
                cart.ok = other.ok = False
                # first collision is our part 1 result
                part1 = part1 or cart.p
    # remove carts that crashed
    carts = [x for x in carts if x.ok]
    print([x.p for x in carts])
    # if only one cart is left, part 2 is done
    if len(carts) == 1:
        part2 = carts[0].p
        break

print(part1)
print(part2)