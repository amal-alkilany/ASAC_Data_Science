-- D14 · 06 · Choose a model, then test it once · Starter
-- Run only after you and your partner have chosen, and written down why.
-- You need ml.insurance_features (activity 05, block 2) and the model you chose.

-- 1. The test, once: the chosen model on the 267 test people it has never seen.
SELECT ROUND(mean_absolute_error) AS mae,
       ROUND(SQRT(mean_squared_error)) AS rmse,
       ROUND(r2_score, 2) AS r2
FROM ML.EVALUATE(MODEL ml.ins_linear_plus,
  (SELECT * FROM ml.insurance_features WHERE split = 'test'));

-- 2. The guess on the same test people: the training average, 13,267, for everyone.
SELECT ROUND(AVG(ABS(charges - 13267))) AS mae_of_the_guess
FROM ml.insurance_features
WHERE split = 'test';
