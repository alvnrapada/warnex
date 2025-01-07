# Warnex

[![Hex.pm](https://img.shields.io/hexpm/v/warnex.svg)](https://hex.pm/packages/warnex)
[![Docs](https://img.shields.io/badge/hex-docs-brightgreen.svg)](https://hexdocs.pm/warnex)

A Phoenix/Elixir application warning manager that helps track and manage application warnings effectively.

## Installation

The package can be installed by adding `warnex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:warnex, "~> 0.1.0"}
  ]
end
```

## Usage

Initially, you must gather the warnings from the compilation output:

```
Run this on your terminal:

rm warnings.log; mix compile --force --all-warnings > warnings.log 2>&1

OR

alias Warnex
Warnex.generate_warnings()


```

this will generate `warnings.log` into your root folder, then you can now alias Warnex and use its functions

## Features

- Track application warnings
- Manage warning states
- Integrate with Phoenix applications

## Documentation

Full documentation can be found at [https://hexdocs.pm/warnex](https://hexdocs.pm/warnex).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

