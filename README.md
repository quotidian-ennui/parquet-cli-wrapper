# parquet-cli-wrapper

Builds https://github.com/apache/parquet-mr/tree/master/parquet-cli according to their _non-hadoop_ instructions, and has a simple shell script that wraps the execution.

## TLDR;

```
export PARQUET_VERSION=1.13.0
make build
cd ./build/dist
./parquet convert-csv xxxx
```

- `make dist` will build a tgz file that you can extract so that the parquet script is in your path somewhere.

## Why this and not that?

Homebrew is great; and if you're on the mac then you should use that.

Sometimes you just want to do stuff w/o having doing more stuff (that and because I'm unlikely to run homebrew on Windows)

## Ongoing tinkering

- Fun and games with publishing the output of `make dist` as a release?
- Update cli to detect github releases of `parquet-mr?` and create corresponding bundles?
- Create a wrapper jar file that has the appropriate `META-INF/MANIFEST.MF` that means I don't need to cobble a classpath together?
- Making the release available in my personal scoop bucket? (though I would probably need to have the equivalent .cmd file then)
