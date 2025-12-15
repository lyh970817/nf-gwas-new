# Kinship Formats

## Overview

The default format for storing kinships uses four files:

- **grm.bin**: Binary file containing pairwise kinships
- **grm.id**: Text file with sample IDs
- **grm.details**: Text file with predictor details
- **grm.adjust**: Text file with kinship matrix information

## Legacy Format (gzipped)

Previously until around 2014, pairwise kinships were saved in gzipped format. To convert from this format to the current binary format, use:

```
--convert-gz <output> --grm <kinfile>
```

LDAK expects files named `<kinfile>.grm.gz` and `<kinfile>.grm.id`.

To save in gzipped format, add `--kinship-gz YES` to any LDAK command that produces a kinship matrix.

## Raw Text Format

If pairwise kinships are stored as a square matrix (text file, no headers), convert to binary using:

```
--convert-raw <output> --grm <kinfile>
```

LDAK searches for `<kinfile>.grm.raw` and `<kinfile>.grm.id`.

To save in raw text format, add `--kinship-raw YES` to any LDAK command producing a kinship matrix.

---

**Source**: [DougSpeed.com](https://dougspeed.com/) - The Home of LDAK
