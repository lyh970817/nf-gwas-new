# Jackknife

## Overview

The jackknife function measures similarity between pairs of vectors containing predicted and observed values. It calculates correlation, correlation squared (on the observed scale), mean squared error, and mean absolute error, along with corresponding standard deviation estimates. For binary observed values, it can also compute area under curve and correlation squared on the liability scale. This tool was designed primarily for assessing the accuracy of polygenic risk scores created by LDAK's Prediction tools.

> "Always read the screen output, which suggests arguments and estimates memory usage."

## Main Arguments

The primary argument is `--jackknife <outfile>`.

### Required Options

- **`--data-pairs <datapairs>` or `--profile <profile>`** — Provides pairs of predicted and observed values
  - With `--data-pairs`: file should contain two or three columns (no headers) with predicted values, observed values, and optional regression weights
  - With `--profile`: use output from Calculate Scores function

- **`--num-blocks <integer>`** — Specifies the number of jackknife blocks (200 is typically recommended)

### Optional Arguments

- **`--binary YES`** — For binary outcomes; computes area under curve and Nagelkerke's pseudo-R²
- **`--prevalence <float>`** — Specifies population case proportion; enables liability scale correlation squared reporting

Results are saved to `<outfile>.jack`.

## Example Usage

```
echo "Predictor A1 A2 Centre Effect1 Effect2
21:14642464 A G 0.88 0.3 -0.1
21:14649798 C A 0.97 -0.2 0.4" > scores.txt
```

Calculate scores:
```
./ldak.out --calc-scores scores --scorefile scores.txt --bfile human --power 0 --pheno binary.pheno
```

Run jackknife analysis:
```
./ldak.out --jackknife jack --profile scores.profile --num-blocks 200
```

For binary traits:
```
./ldak.out --jackknife jack --profile scores.profile --num-blocks 200 --binary YES
```

The resulting `jack.jack` file reports correlation, correlation squared, mean squared error, mean absolute error, and (if applicable) area under curve with jackknife-derived standard deviations.

---

**Website:** [DougSpeed.com](https://dougspeed.com/)
