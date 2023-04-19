# parquet-cli-wrapper

Builds https://github.com/apache/parquet-mr/tree/master/parquet-cli according to their _non-hadoop_ instructions, and has a simple shell script that wraps the execution.

## TLDR;

```
make build
cd ./build/dist
./parquet convert-csv xxxx
```

- `make dist` will build a tgz file that you can extract so that the parquet script is in the path; or just make _build/dist_ part of the path.

```
$ export PATH=$PATH:/home/quotidian-ennui/parquet-cli-wrapper/build/dist
$ cd ~
$ parquet convert-csv --help
Usage: parquet [general options] convert-csv [command options]

  Description:

    Create a file from CSV data

  Command options:
...
```

## Why this and not that?

Homebrew is great; and if you're on the mac then you should use that.

Sometimes you just want to do stuff w/o having doing more stuff (that and because I'm unlikely to run homebrew on Windows)

I spend my life in git+bash + WSL2; I don't care about powershell enough (I should probably care more), that's why there's no equivalent .cmd file (there should be)

## Ongoing tinkering

- [x] Fun and games with publishing the output of `make dist` as a release?
- [x] Update cli to detect github releases of `parquet-mr?` and create a PR
- [ ] Create a wrapper jar file that has the appropriate `META-INF/MANIFEST.MF` that means I don't need to cobble a classpath together?
- [x] Making the release available in my personal scoop bucket?
- [ ] Create a .cmd equivalent of the shell script
- [ ] add a `make test` because even a single invocation that does something before doing a release might be useful.
