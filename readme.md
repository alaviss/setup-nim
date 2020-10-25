# Setup Nim

![Check shell scripts](https://github.com/alaviss/setup-nim/workflows/Check%20shell%20scripts/badge.svg)
![Test Github Actions](https://github.com/alaviss/setup-nim/workflows/Test%20Github%20Actions/badge.svg)

An action for setting up the Nim environment for use within Github Actions.
This includes:

- The full Nim toolchain built by the official builder at
  [nim-lang/nightlies](https://github.com/nim-lang/nightlies).
- A [problem matcher](https://github.com/actions/toolkit/blob/master/docs/problem-matchers.md)
  for converting compiler errors/warnings into annotations.

# Usage

See [action.yml](action.yml)

Basic:

```yaml
steps:
  - uses: alaviss/setup-nim@master
    with:
      version: 'version-1-4' # The Nim nightly version branch to download
      path: 'nim' # The directory relative to ${{ github.workspace }} to
                  # store the downloaded toolchain
  - uses: actions/checkout@v2
  - run: nimble build
```

Matrix testing:

```yaml
jobs:
  test:
    strategy:
      matrix:
        os: ['windows-latest', 'macos-latest', 'ubuntu-latest']
        nim: ['devel', 'version-1-4', 'version-1-0']

    name: Nim ${{ matrix.nim }} on ${{ matrix.os }}
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v2
      - uses: alaviss/setup-nim@master
        with:
          path: 'nim'
          version: ${{ matrix.nim }}
      - run: nimble test
```

# License

Unless stated otherwise, scripts and documentations within this project are
released under the [GNU GPLv3 license](license.txt).
