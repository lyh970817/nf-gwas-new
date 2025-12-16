# LDAK-KVIK Downloads

LDAK-KVIK is part of LDAK, a command-line software designed for Linux and Mac systems. The Linux version is recommended for superior performance.

> "LDAK does not run on Windows, so we suggest using a Linux server (for example, you can use putty to ssh into your local computer cluster)."

## Installation Methods

### Method 1: Command Line Download

**For Linux:**
```bash
wget https://github.com/dougspeed/LDAK/raw/refs/heads/main/ldak6.1.linux
chmod a+x ldak6.1.linux
```

**For Mac:**
```bash
curl -L -o ldak6.1.mac https://github.com/dougspeed/LDAK/raw/main/ldak6.1.mac
chmod a+x ldak6.1.mac
```

### Method 2: Direct Download from GitHub

Download executables directly from the GitHub repository:
- Linux executable: `ldak6.1.linux`
- Mac executable: `ldak6.1.mac`

Use keyboard shortcut `Ctrl+Shift+S` or select the download option from the menu.

### Method 3: Conda Installation (Linux Only)

```bash
conda create -n ldak_env -c genomedk ldak6
conda activate ldak_env
ldak6
```

Replace `ldak6.1.linux` with `ldak6` in examples when using the conda version.

### Method 4: Compile from Source

**Linux compilation:**
```bash
gcc -O3 -o ldak6 ldak.c libqsopt.linux.a -lblas -llapack -lm -lz -fopenmp
chmod a+x ldak6
```

**Mac compilation:**
```bash
gcc -O3 -o ldak6.mac ldak.c libqsopt.mac.a -lblas -llapack -lm -lz
chmod a+x ldak6.mac
```

Mac users may need to install xcode first:
```bash
xcode-select --install
```

## Additional Resources

- **Mailing List:** Sign up at https://dougspeed.com/downloads/ for major update notifications
- **GitHub Repository:** https://github.com/dougspeed/LDAK
- **Main Website:** https://www.ldak.org
