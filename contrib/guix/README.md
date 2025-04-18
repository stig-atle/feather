# Bootstrappable Feather Wallet Builds

This directory contains the files necessary to perform [bootstrappable](https://bootstrappable.org) Feather Wallet builds.

Bootstrappability allows us to _audit and reproduce_ our toolchain instead of blindly _trusting_ binary downloads.
Our build environment can be built from source, [all the way down](https://guix.gnu.org/en/blog/2023/the-full-source-bootstrap-building-from-source-all-the-way-down/).

We achieve bootstrappability by using [Guix](https://guix.gnu.org/) as a functional package manager. Guix runs on any Linux distribution and on
most architectures (x86_64, aarch64, riscv64). To produce reproducible release binaries, you only need to install Guix
and run the build script.

Guix allows us to modify any detail about our build environment with ease.
Unlike [Gitian](https://github.com/devrandom/gitian-builder), we are not limited to the package set of a particular Ubuntu version.
With Guix, we can configure our toolchains to use the latest compilers while still targeting older versions of glibc.
We drastically reduce our supply chain attack surface by only including the package we need in our build environment, and nothing else.
Packages that are not available in Guix can easily be defined in the [manifest](https://github.com/feather-wallet/feather/blob/master/contrib/guix/manifest.scm) or upstreamed.

Feather releases are independently reproduced and cryptographically attested to by multiple contributors.
You can submit attestations to the [feather-sigs](https://github.com/feather-wallet/feather-sigs) repo.

# Requirements

- any Linux distribution
- 50 GB of free disk space
- 4 or more cores recommended
- 2 GB RAM per thread

# Quick setup

If you're just here to get a build running (e.g. to test your changes) and quickly want to get up and running:

### Install Guix

On Ubuntu 22.04, Debian 11, or later:

```bash
$ apt install guix
```

If Guix is not available in your package manager, use the official [install script](https://guix.gnu.org/manual/en/html_node/Binary-Installation.html).

### Clone the repo

```bash
$ git clone https://github.com/feather-wallet/feather
$ cd feather
```

### Before building

#### Ubuntu

On **Ubuntu**, you may run into the following error caused by [this Ubuntu bug](https://bugs.launchpad.net/ubuntu/+source/guix/+bug/2064115):

`guix environment: error: mount: mount "none" on "/tmp/guix-directory.Ile657": Permission denied`

To work around this issue, you need to create a permissive AppArmor profile for Guix:

```bash
$ apt install apparmor-utils
$ cat <<EOL >> /etc/apparmor.d/guix
abi <abi/4.0>,
include <tunables/global>

profile guix /usr/bin/guix flags=(unconfined) {
  userns,
  include if exists <local/guix>
}
EOL

$ /etc/init.d/apparmor reload
$ aa-enforce guix
```

#### Fedora

On **Fedora**, you may run into the following error:

`guix gc: error: remounting /gnu/store writable: Permission denied`

To work around this issue, you need to temporarily disable SELinux:

```bash
sudo setenforce 0
```

You can re-enable it after the build with:

```bash
sudo setenforce 1
```

### Run the build

To build all targets using all available cores:

```bash
$ make build
```

To limit the number of threads to N:

```
$ JOBS=N make build
```

To only build the x86_64 linux target:

```
$ HOSTS="x86_64-linux-gnu" make build
```

More recognized environment variables can be found further below.

# Installation and Setup

If you don't have Guix installed and set up, please follow the instructions in
[INSTALL.md](./INSTALL.md)

# Usage

If you haven't considered your security model yet, please read [the relevant
section](#choosing-your-security-model) before proceeding to perform a build.

## Building

*The author highly recommends at least reading over the [common usage patterns
and examples](#common-guix-build-invocation-patterns-and-examples) section below
before starting a build. For a full list of customization options, see the
[recognized environment variables][env-vars-list] section.*

To build Feather Wallet reproducibly with all default options, invoke the
following from the top of a clean repository:

```sh
make build
```

## Cleaning intermediate work directories

By default, `guix-build` leaves all intermediate files or "work directories"
(e.g. `depends/work`, `guix-build-*/distsrc-*`) intact at the end of a build so
that they are available to the user (to aid in debugging, etc.). However, these
directories usually take up a large amount of disk space. Therefore, a
`guix-clean` convenience script is provided which cleans the current `git`
worktree to save disk space:

```
make clean
```


## Attesting to build outputs

After you've cloned the `feather-sigs` repository, to attest to the current
worktree's commit/tag:

```
make attest
```

For a step-by-step walkthrough, see: https://paste.debian.net/plainh/dfecbbcc. Make sure to replace the version number
with the version you want to build.

## Verifying build output attestations

After at least one other signer has uploaded their signatures to the `feather-sigs`
repository:

```
git submodule update --recursive
make verify
```


## Common `guix-build` invocation patterns and examples

### Keeping caches outside of the worktree

If you perform a lot of builds and have a bunch of worktrees, you may find it
more efficient to keep the depends tree's download cache and build cache
outside of the worktrees to avoid duplicate downloads and unnecessary builds. To
help with this situation, the `guix-build` script honours the `SOURCES_PATH`,
`BASE_CACHE` environment variables and will pass them on to the
depends tree so that you can do something like:

```sh
env SOURCES_PATH="$HOME/depends-SOURCES_PATH" BASE_CACHE="$HOME/depends-BASE_CACHE" make build
```

Note that the paths that these environment variables point to **must be
directories**, and **NOT symlinks to directories**.

See the [recognized environment variables][env-vars-list] section for more
details.

### Building a subset of platform triples

Sometimes you only want to build a subset of the supported platform triples, in
which case you can override the default list by setting the space-separated
`HOSTS` environment variable:

```sh
env HOSTS='x86_64-w64-mingw32 x86_64-apple-darwin' make build
```

See the [recognized environment variables][env-vars-list] section for more
details.

### Controlling the number of threads used by `guix` build commands

Depending on your system's RAM capacity, you may want to decrease the number of
threads used to decrease RAM usage or vice versa.

By default, the scripts under `./contrib/guix` will invoke all `guix` build
commands with `--cores="$JOBS"`. Note that `$JOBS` defaults to `$(nproc)` if not
specified. However, astute manual readers will also notice that `guix` build
commands also accept a `--max-jobs=` flag (which defaults to 1 if unspecified).

Here is the difference between `--cores=` and `--max-jobs=`:

> Note: When I say "derivation," think "package"

`--cores=`

  - controls the number of CPU cores to build each derivation. This is the value
    passed to `make`'s `--jobs=` flag.

`--max-jobs=`

  - controls how many derivations can be built in parallel
  - defaults to 1

Therefore, the default is for `guix` build commands to build one derivation at a
time, utilizing `$JOBS` threads.

Specifying the `$JOBS` environment variable will only modify `--cores=`, but you
can also modify the value for `--max-jobs=` by specifying
`$ADDITIONAL_GUIX_COMMON_FLAGS`. For example, if you have a LOT of memory, you
may want to set:

```sh
export ADDITIONAL_GUIX_COMMON_FLAGS='--max-jobs=8'
```

Which allows for a maximum of 8 derivations to be built at the same time, each
utilizing `$JOBS` threads.

Or, if you'd like to avoid spurious build failures caused by issues with
parallelism within a single package, but would still like to build multiple
packages when the dependency graph allows for it, you may want to try:

```sh
export JOBS=1 ADDITIONAL_GUIX_COMMON_FLAGS='--max-jobs=8'
```

See the [recognized environment variables][env-vars-list] section for more
details.

## Recognized environment variables

* _**HOSTS**_

  Override the space-separated list of platform triples for which to perform a
  bootstrappable build.

  _(defaults to "x86\_64-linux-gnu aarch64-linux-gnu arm-linux-gnueabihf x86\_64-linux-gnu.no-tor-bundle 
 x86\_64-linux-gnu.pack riscv64-linux-gnu x86\_64-w64-mingw32 x86\_64-w64-mingw32.installer x86\_64-apple-darwin arm64-apple-darwin")_

* _**SOURCES_PATH**_

  Set the depends tree download cache for sources. This is passed through to the
  depends tree. Setting this to the same directory across multiple builds of the
  depends tree can eliminate unnecessary redownloading of package sources.

  The path that this environment variable points to **must be a directory**, and
  **NOT a symlink to a directory**.

* _**BASE_CACHE**_

  Set the depends tree cache for built packages. This is passed through to the
  depends tree. Setting this to the same directory across multiple builds of the
  depends tree can eliminate unnecessary building of packages.

  The path that this environment variable points to **must be a directory**, and
  **NOT a symlink to a directory**.

* _**JOBS**_

  Override the number of jobs to run simultaneously, you might want to do so on
  a memory-limited machine. This may be passed to:

  - `guix` build commands as in `guix environment --cores="$JOBS"`
  - `make` as in `make --jobs="$JOBS"`
  - `xargs` as in `xargs -P"$JOBS"`

  See [here](#controlling-the-number-of-threads-used-by-guix-build-commands) for
  more details.

  _(defaults to the value of `nproc` outside the container)_

* _**V**_

  If non-empty, will pass `V=1` to all `make` invocations, making `make` output
  verbose.

  Note that any given value is ignored. The variable is only checked for
  emptiness. More concretely, this means that `V=` (setting `V` to the empty
  string) is interpreted the same way as not setting `V` at all, and that `V=0`
  has the same effect as `V=1`.

* _**SUBSTITUTE_URLS**_

  A whitespace-delimited list of URLs from which to download pre-built packages.
  A URL is only used if its signing key is authorized (refer to the [substitute
  servers section](#option-1-building-with-substitutes) for more details).

* _**ADDITIONAL_GUIX_COMMON_FLAGS**_

  Additional flags to be passed to all `guix` commands.

* _**ADDITIONAL_GUIX_TIMEMACHINE_FLAGS**_

  Additional flags to be passed to `guix time-machine`.

* _**ADDITIONAL_GUIX_ENVIRONMENT_FLAGS**_

  Additional flags to be passed to the invocation of `guix environment` inside
  `guix time-machine`.

# Choosing your security model

No matter how you installed Guix, you need to decide on your security model for
building packages with Guix.

Guix allows us to achieve better binary security by using our CPU time to build
everything from scratch. However, it doesn't sacrifice user choice in pursuit of
this: users can decide whether or not to use **substitutes** (pre-built
packages).

## Option 1: Building with substitutes

### Step 1: Authorize the signing keys

Depending on the installation procedure you followed, you may have already
authorized the Guix build farm key. In particular, the official shell installer
script asks you if you want the key installed, and the debian distribution
package authorized the key during installation.

You can check the current list of authorized keys at `/etc/guix/acl`.

At the time of writing, a `/etc/guix/acl` with just the Guix build farm key
authorized looks something like:

```lisp
(acl
 (entry
  (public-key
   (ecc
    (curve Ed25519)
    (q #8D156F295D24B0D9A86FA5741A840FF2D24F60F7B6C4134814AD55625971B394#)
    )
   )
  (tag
   (guix import)
   )
  )
 )
```

If you've determined that the official Guix build farm key hasn't been
authorized, and you would like to authorize it, run the following as root:

```
guix archive --authorize < /var/guix/profiles/per-user/root/current-guix/share/guix/ci.guix.gnu.org.pub
```

If
`/var/guix/profiles/per-user/root/current-guix/share/guix/ci.guix.gnu.org.pub`
doesn't exist, try:

```sh
guix archive --authorize < <PREFIX>/share/guix/ci.guix.gnu.org.pub
```

Where `<PREFIX>` is likely:
- `/usr` if you installed from a distribution package
- `/usr/local` if you installed Guix from source and didn't supply any
  prefix-modifying flags to Guix's `./configure`

For dongcarl's substitute server at https://guix.carldong.io, run as root:

```sh
wget -qO- 'https://guix.carldong.io/signing-key.pub' | guix archive --authorize
```

#### Removing authorized keys

To remove previously authorized keys, simply edit `/etc/guix/acl` and remove the
`(entry (public-key ...))` entry.

### Step 2: Specify the substitute servers

Once its key is authorized, the official Guix build farm at
https://ci.guix.gnu.org is automatically used unless the `--no-substitutes` flag
is supplied. This default list of substitute servers is overridable both on a
`guix-daemon` level and when you invoke `guix` commands. See examples below for
the various ways of adding dongcarl's substitute server after having [authorized
his signing key](#step-1-authorize-the-signing-keys).

Change the **default list** of substitute servers by starting `guix-daemon` with
the `--substitute-urls` option (you will likely need to edit your init script):

```sh
guix-daemon <cmd> --substitute-urls='https://guix.carldong.io https://ci.guix.gnu.org'
```

Override the default list of substitute servers by passing the
`--substitute-urls` option for invocations of `guix` commands:

```sh
guix <cmd> --substitute-urls='https://guix.carldong.io https://ci.guix.gnu.org'
```

For scripts under `./contrib/guix`, set the `SUBSTITUTE_URLS` environment
variable:

```sh
export SUBSTITUTE_URLS='https://guix.carldong.io https://ci.guix.gnu.org'
```

## Option 2: Disabling substitutes on an ad-hoc basis

If you prefer not to use any substitutes, make sure to supply `--no-substitutes`
like in the following snippet. The first build will take a while, but the
resulting packages will be cached for future builds.

For direct invocations of `guix`:
```sh
guix <cmd> --no-substitutes
```

For the scripts under `./contrib/guix/`:
```sh
export ADDITIONAL_GUIX_COMMON_FLAGS='--no-substitutes'
```

## Option 3: Disabling substitutes by default

`guix-daemon` accepts a `--no-substitutes` flag, which will make sure that,
unless otherwise overridden by a command line invocation, no substitutes will be
used.

If you start `guix-daemon` using an init script, you can edit said script to
supply this flag.

[r12e/source-date-epoch]: https://reproducible-builds.org/docs/source-date-epoch/
[env-vars-list]: #recognized-environment-variables
