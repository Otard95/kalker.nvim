# kalker.nvim

A Neovim plugin that integrates with [Kalker](https://kalker.xyz/), a scientific calculator supporting user-defined variables and functions. Get live calculation results displayed as virtual text directly in your buffer.

## Features

- **Live Calculations**: Results appear automatically as virtual text at the end of each line
- **Error Diagnostics**: Invalid expressions show as Neovim diagnostics
- **Debounced Updates**: Efficient recalculation on text changes
- **Comment Support**: Lines starting with `--` are ignored

## Requirements

- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [Kalker](https://kalker.xyz/) CLI installed and available in PATH

### Installing Kalker

```bash
# macOS
brew install kalker

# Cargo (Rust)
cargo install kalker

# Arch Linux
pacman -S kalker

# See https://kalker.xyz/ for more options
```

## Installation

### lazy.nvim

```lua
{
  'Otard95/kalker.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  ft = 'kalker',
  config = function()
    require('kalker').setup()
  end
}
```

### packer.nvim

```lua
use {
  'Otard95/kalker.nvim',
  requires = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('kalker').setup()
  end
}
```

## Configuration

```lua
require('kalker').setup({
  calculations = {
    timeout = 300,    -- Timeout for calculations in ms
  },
  debounce = 300,     -- Debounce delay for recalculation in ms
  log_level = nil,    -- Log level (DEBUG, INFO, WARN, ERROR, FATAL)
  log_file = nil,     -- Path to log file (nil = print to messages)
})
```

## Usage

1. Create or open a file with the `.kalker` extension
2. Write mathematical expressions, one per line
3. Results appear automatically as virtual text

### Example

```kalker
-- Variable assignment
x = 5
y = 10

-- Basic arithmetic
x + y
x * y

-- Function definition
f(x) = x^2 + 2x + 1
f(3)

-- Calculus
f'(x)
∫(0, π, sin(x), dx)

-- Summation (approximating e)
Σ(n=0, 20, 1/n!)
```

See [examples/basic-expressions.kalker](examples/basic-expressions.kalker) for more examples.

### Kalker Syntax

Kalker supports a rich set of mathematical operations:

| Feature | Syntax | Example |
|---------|--------|---------|
| Variables | `name = value` | `x = 42` |
| Functions | `f(x) = expr` | `f(x) = x^2` |
| Differentiation | `f'(x)` | `sin'(x)` |
| Integration | `∫(a, b, expr, dx)` | `∫(0, 1, x^2, dx)` |
| Summation | `Σ(n=a, b, expr)` | `Σ(n=1, 10, n)` |
| Constants | `π`, `e`, `i` | `e^(iπ)` |

For full documentation, visit [kalker.xyz](https://kalker.xyz/).

## License

[MIT](LICENSE)
