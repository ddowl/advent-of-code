# Puzzle input today represents a map (dungeon) we ("@") need to crawl in order to
# collect keys (lowercase letters) and open doors (corresponding uppercase letters)
# constrained by walls ("#"). The goal is to determine the shortest distance to
# collect all of the keys.
#
# A hint from the prompt:
#   Now, you have a choice between keys d and e. While key e is closer,
#   collecting it now would be slower in the long run than collecting key d
#   first, so that's the best choice...
#
# This seems to imply that there will be some path exploration/backtracking in order
# to explore valid paths and pick the shortest.
