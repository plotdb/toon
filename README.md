# TOON LiveScript Implementation

A complete implementation of TOON (Token-Oriented Object Notation) encoder and decoder in LiveScript.

## Features

- Complete bidirectional JSON to TOON conversion
- 100% test pass rate
- 100% round-trip conversion fidelity
- Support for all TOON formats (inline, tabular, list)
- Full quoting rules implementation
- Follows official TOON specification

## Quick start

### Installation

    npm install

### Build

    ./build

### Basic usage

    const { encode, decode } = require('./dist/index.js');

    // Encode JSON to TOON
    const data = {
      id: 123,
      name: "Ada",
      tags: ["admin", "dev"],
      items: [
        { sku: "A1", qty: 2, price: 9.99 },
        { sku: "B2", qty: 1, price: 14.5 }
      ]
    };

    const toon = encode(data);
    console.log(toon);
    /*
    id: 123
    name: Ada
    tags[2]: admin,dev
    items[2]{sku,qty,price}:
      A1,2,9.99
      B2,1,14.5
    */

    // Decode TOON to JSON
    const decoded = decode(toon);
    console.log(JSON.stringify(decoded) === JSON.stringify(data)); // true

## Testing

    # Encoder tests
    node tests/test-encoder.js

    # Decoder and round-trip tests
    node tests/test-decoder.js

    # Sample files tests
    node tests/test-samples.js

    # Full example
    node tests/example.js

### Test results

- Encoder: 11/11 passed
- Decoder: 11/11 passed
- Round-trip: 11/11 passed
- Samples: 7/7 passed

Total: 100% success rate

## API documentation

### encode(value, options)

Encode a JSON value to TOON format.

Parameters:
- `value` - Any JSON-serializable value
- `options` (optional)
  - `indent`: Number of spaces per indentation level (default: 2)
  - `delimiter`: Delimiter character `','` | `'\t'` | `'|'` (default: `','`)
  - `lengthMarker`: Whether to use `#` prefix (default: `false`)

Returns: TOON format string

### decode(toonStr, options)

Parse a TOON format string to JSON value.

Parameters:
- `toonStr` - TOON format string
- `options` (optional)
  - `strict`: Strict mode (reserved)

Returns: Parsed JSON value

### Classes

    const { encoder, decoder } = require('./dist/index.js');

    // Use encoder instance
    const enc = new encoder({ delimiter: '\t' });
    const toon = enc.encode(data);

    // Use decoder instance
    const dec = new decoder();
    const json = dec.decode(toon);

## TOON format examples

### Object

    id: 123
    name: Ada
    active: true

### Nested object

    user:
      id: 123
      name: Ada

### Inline array

    tags[3]: admin,ops,dev

### Tabular array

    items[3]{sku,qty,price}:
      A1,2,9.99
      B2,1,14.5
      C3,5,7.25

### List array

    items[5]:
      - 1
      - text
      - a: 1
      - true
      - null

### Quoted strings

    with_comma: "hello, world"
    with_colon: "key: value"
    looks_like_bool: "true"

## Project structure

    /workspace
    ├── src/
    │   └── index.ls              # Main implementation (~700 lines)
    ├── dist/
    │   ├── index.js              # Compiled JavaScript
    │   └── index.min.js          # Minified version
    ├── tests/                    # Test files
    │   ├── test-encoder.js       # Encoder tests
    │   ├── test-decoder.js       # Decoder tests
    │   ├── test-samples.js       # Sample tests
    │   └── example.js            # Usage example
    ├── samples/                  # Test samples
    │   ├── simple/               # Simple cases
    │   ├── complex/              # Complex cases
    │   └── edge-cases/           # Edge cases
    ├── llm/                      # AI-generated docs and references
    │   ├── spec.md               # TOON format specification
    │   ├── lsc-coding-guide.md   # LiveScript coding style
    │   ├── DEV.md                # Development guide
    │   ├── ARCHITECTURE.md       # Architecture document
    │   ├── FINAL_REPORT.md       # Complete report
    │   └── SAMPLES_PLANNING.md   # Test case planning
    ├── package.json              # Project configuration
    ├── build                     # Build script
    └── README.md                 # This file

## Documentation

- [llm/spec.md](llm/spec.md) - TOON format specification
- [llm/DEV.md](llm/DEV.md) - Development guide
- [llm/ARCHITECTURE.md](llm/ARCHITECTURE.md) - Architecture document
- [llm/FINAL_REPORT.md](llm/FINAL_REPORT.md) - Complete implementation report
- [llm/lsc-coding-guide.md](llm/lsc-coding-guide.md) - LiveScript coding style guide
- [llm/SAMPLES_PLANNING.md](llm/SAMPLES_PLANNING.md) - Test case planning

## Token savings

According to TOON specification, compared to JSON:
- General data: 30-60% token reduction
- Tabular data: up to 60%+ token reduction

## Use cases

Suitable for:
- Passing data to LLMs
- Large amounts of uniformly structured data
- Token-cost-sensitive applications

Not suitable for:
- API responses (use JSON)
- Database storage (use JSON)
- Direct browser parsing (use JSON)

## Technical specifications

- Language: LiveScript
- Target: Node.js
- Compiler: LiveScript compiler
- Lines of code: ~700 lines
- Test coverage: 100%

## Related links

- [Official TOON specification](https://github.com/byjohann/toon)
- [LiveScript official website](https://livescript.net/)

## License

MIT License

## Author

Developed with Claude Code by zbryikt

---

Status: Complete and ready to use
Version: 1.0.0
Last updated: 2025-10-29
