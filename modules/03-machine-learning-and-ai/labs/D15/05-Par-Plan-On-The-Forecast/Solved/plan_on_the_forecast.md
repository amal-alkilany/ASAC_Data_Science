# Would you plan on this forecast? · sample answer

The model's numbers below were computed outside BigQuery with a similar method (about); BigQuery's own values differ a little. The simple forecasts are exact.

## The 1959 evidence

| Forecast for 1959 | MAE (thousands a month) | MAPE |
|---|---:|---:|
| ARIMA_PLUS | about 27 | about 6.2% |
| seasonal naive: same month of 1958 | 47.3 | 11.1% |
| naive: December 1958 held flat | 91.3 | 19.5% |
| training mean held flat | 182.4 | 41.3% |
| training median held flat | 194.8 | 44.2% |

Months inside the 95% interval: about 4 of 12 for the stand-in (BigQuery's interval may hold more).

The largest misses are in the summer and late autumn, and almost all are positive: the forecast was too low.

## Three sentences for the planner

1. Plan 1960 on ARIMA_PLUS's forecast: on 1959, a year it had not seen, it missed a typical month by about 27 thousand passengers (about 6%), against 47 thousand for "same month as last year".
2. Roster crews to the upper bound of the 95% interval from June to September, where the misses were largest; use the forecast itself for revenue.
3. The risk is that the summer peak keeps growing with the airline: the model adds a season the size of past years (a swing of about 191 against a real 217 in 1959), so next summer's busiest months are likely to come in above the forecast and possibly above the upper bound.

## Common errors

- "The model is accurate": accurate compared with what? Name the bar (47.3) and the size of the miss.
- Staffing to the forecast in the peak months: half the time the real number will be higher, and on 1959 it was higher in most months.
- Naming a risk that the evidence does not show ("the data is old"). The growing season shows in the signs of the misses and in step 2's swing.

**Bonus:** for revenue, too high and too low cost the same, so hand over the forecast itself (the middle of the interval). For crews, too few costs more, so hand over the upper bound.
