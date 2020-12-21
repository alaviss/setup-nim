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

**Note**: It is recommended to use a tagged version at the moment instead of
`master`. This makes sure that future backward-incompatible changes will not
cause your CI to fail suddenly. See the [Update](#update) section for how
to keep the action up-to-date.

Basic:

```yaml
steps:
  - uses: alaviss/setup-nim@0.1.1
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
      - uses: alaviss/setup-nim@0.1.1
        with:
          path: 'nim'
          version: ${{ matrix.nim }}
      - run: nimble test
```

Testing 32bit Windows:

```yaml
jobs:
  test:
    name: Nim 32bit on Windows
    runs-on: windows-latest

    steps:
      - uses: actions/checkout@v2
      - uses: egor-tensin/setup-mingw@v1
        with:
          platform: x86
      - uses: alaviss/setup-nim@0.1.1
        with:
          path: 'nim'
          version: devel
          architecture: i386
      - run: nimble test
```

# Update

Github's Dependabot can be used to keep actions up-to-date, see [here][1] for
more information.

Example `.github/dependabot.yml` (copied from [Github Docs][1]):

```yaml
version: 2

updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      # Check for updates to GitHub Actions every weekday
      interval: "daily"
```

# License

Unless stated otherwise, scripts and documentations within this project are
released under the [GNU GPLv3 license](license.txt).

[1]: https://docs.github.com/en/free-pro-team@latest/github/administering-a-repository/keeping-your-actions-up-to-date-with-dependabot
