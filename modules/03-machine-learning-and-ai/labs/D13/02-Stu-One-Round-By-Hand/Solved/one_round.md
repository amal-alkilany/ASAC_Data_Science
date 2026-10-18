# One round of k-means, by hand · worked answer

Start: centre **A** = (15, 81), centre **B** = (17, 76). Distances rounded to one decimal.

## Round 1 · assign

| Shopper | Income, score | Distance to A | Distance to B | Joins |
|---:|---|---:|---:|:---:|
| 2 | 15, 81 | 0.0 | 5.4 | A |
| 4 | 16, 77 | 4.1 | 1.4 | B |
| 6 | 17, 76 | 5.4 | 0.0 | B |
| 124 | 69, 91 | 54.9 | 54.1 | B |
| 126 | 70, 77 | 55.1 | 53.0 | B |
| 128 | 71, 95 | 57.7 | 57.2 | B |

Shopper 4 to A: √((16 − 15)² + (77 − 81)²) = √(1 + 16) = 4.1.
Shopper 124 to B: √((69 − 17)² + (91 − 76)²) = √(2,704 + 225) = 54.1.

## Round 1 · update

| Centre | Shoppers | Average income | Average score | New centre |
|---|---|---:|---:|---|
| A | 2 | 15 | 81 | (15, 81) |
| B | 4, 6, 124, 126, 128 | (16 + 17 + 69 + 70 + 71) ÷ 5 = 48.6 | (77 + 76 + 91 + 77 + 95) ÷ 5 = 83.2 | (48.6, 83.2) |

One shopper against five: B sits in empty space between the two real groups.

## Bonus · round 2

| Shopper | Distance to A (15, 81) | Distance to B (48.6, 83.2) | Joins |
|---:|---:|---:|:---:|
| 2 | 0.0 | 33.7 | A |
| 4 | 4.1 | 33.2 | A |
| 6 | 5.4 | 32.4 | A |
| 124 | 54.9 | 21.8 | B |
| 126 | 55.1 | 22.3 | B |
| 128 | 57.7 | 25.3 | B |

New centres: A = (16, 78), B = (70, 87.7). In round 3 every shopper stays where it is, so the centres stop moving: k-means has finished. A bad start cost one extra round here; on 200 shoppers it can also end in a worse split, which is why BigQuery offers `KMEANS++` starts (lab 06).
