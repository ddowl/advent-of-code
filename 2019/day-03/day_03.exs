# Strategy: Store lines as a list of line segment points: [{x1, y1}, {x2, y2}, {x3, y3}, ...].
# Determine line intersection if horizontal and vertical ranges are non-disjoint among both lines.
# Intersection point is x coord for vertical line, and y coord for horizontal line
# Determine manhattan distance for each, extract min
