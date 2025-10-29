# TOON Encoder and Decoder for LiveScript
# Converts between JSON and TOON (Token-Oriented Object Notation)

# ============================================================================
# ENCODER
# ============================================================================

encoder = (options = {}) ->
  # Set default options then override with user options
  @ <<<
    indent: 2
    delimiter: ','
    length-marker: false

  @ <<< options
  @

encoder.prototype = Object.create(Object.prototype) <<<
  constructor: encoder

  # Main encode entry point
  encode: (value) ->
    | value is null => 'null'
    | value is undefined => 'null'
    | typeof value is 'object' and value isnt null and not Array.is-array value =>
        # Root-level object
        keys = Object.keys value
        if keys.length is 0
          ''  # Empty object at root returns empty string
        else
          @encode-object value, 0
    | Array.is-array value =>
        # Root-level array - join lines into string
        lines = @encode-array value, 0, null
        lines.join '\n'
    | otherwise =>
        # Root-level primitive
        @encode-primitive value

  # Encode object to TOON format
  encode-object: (obj, depth) ->
    lines = []
    indent-str = ' ' * (depth * @indent)

    for key, value of obj
      formatted-key = @format-key key
      value-lines = @encode-value value, depth, formatted-key
      lines ++= value-lines

    lines.join '\n'

  # Encode a value with its key
  encode-value: (value, depth, key) ->
    indent-str = ' ' * (depth * @indent)

    if value is null or value is undefined
      ["#{indent-str}#{key}: null"]
    else if typeof value is 'boolean'
      ["#{indent-str}#{key}: #{value}"]
    else if typeof value is 'number'
      ["#{indent-str}#{key}: #{@normalize-number value}"]
    else if typeof value is 'bigint'
      ["#{indent-str}#{key}: #{String value}"]
    else if value instanceof Date
      ["#{indent-str}#{key}: #{@quote-string value.toISOString!}"]
    else if typeof value is 'string'
      ["#{indent-str}#{key}: #{@encode-string value}"]
    else if typeof value is 'function' or typeof value is 'symbol'
      ["#{indent-str}#{key}: null"]
    else if typeof value is 'object' and value isnt null and not Array.is-array value
      # Nested object
      header = "#{indent-str}#{key}:"
      keys = Object.keys value
      if keys.length is 0
        [header]  # Empty object
      else
        obj-lines = @encode-object value, depth + 1
        # Split into lines and return as array
        lines = [header] ++ obj-lines.split '\n'
        lines
    else if Array.is-array value
      # Array
      @encode-array value, depth, key
    else
      ["#{indent-str}#{key}: null"]

  # Encode array (auto-select format: inline / tabular / list)
  encode-array: (arr, depth, key) ->
    len = arr.length
    len-marker = if @length-marker => "##{len}" else len
    indent-str = ' ' * (depth * @indent)
    delim = @delimiter
    delim-marker = if delim is ',' => '' else delim

    # Check for tabular format
    if @is-tabular arr
      @format-tabular arr, depth, key, len-marker
    else
      # Check for inline format (all primitives)
      all-primitives = arr.every (el) ~> @is-primitive el

      if all-primitives
        values = arr.map (el) ~> @encode-primitive el
        values-str = values.join delim

        # Add colon and space only if there are values
        suffix = if values-str then ": #{values-str}" else ":"

        if key?
          ["#{indent-str}#{key}[#{len-marker}#{delim-marker}]#{suffix}"]
        else
          ["[#{len-marker}#{delim-marker}]#{suffix}"]
      else
        # List format
        @format-list arr, depth, key, len-marker

  # Check if array is suitable for tabular format
  is-tabular: (arr) ->
    return false if arr.length is 0
    return false unless arr.every (el) ->
      typeof el is 'object' and el isnt null and not Array.is-array el

    # Get keys from first object
    first-keys = Object.keys arr[0] .sort!
    return false if first-keys.length is 0

    # Check all objects have same keys
    return false unless arr.every (obj) ->
      keys = Object.keys obj .sort!
      keys.length is first-keys.length and
        keys.every (k, i) -> k is first-keys[i]

    # Check all values are primitives (using a helper would be cleaner)
    arr.every (obj) ~>
      Object.values obj .every (v) ~> @is-primitive v

  # Check if value is primitive (null or non-object/non-array)
  is-primitive: (value) ->
    value is null or
    value is undefined or
    typeof value in <[ string number boolean bigint ]> or
    value instanceof Date

  # Format array as tabular
  format-tabular: (arr, depth, key, len-marker) ->
    indent-str = ' ' * (depth * @indent)
    row-indent = ' ' * ((depth + 1) * @indent)
    delim = @delimiter
    delim-marker = if delim is ',' => '' else delim

    # Get fields from first object
    fields = Object.keys arr[0]
    formatted-fields = fields.map (f) ~> @format-key f
    fields-str = formatted-fields.join delim

    # Header line
    header = if key?
      "#{indent-str}#{key}[#{len-marker}#{delim-marker}]{#{fields-str}}:"
    else
      "[#{len-marker}#{delim-marker}]{#{fields-str}}:"

    # Data rows
    rows = arr.map (obj) ~>
      values = fields.map (field) ~> @encode-primitive obj[field]
      "#{row-indent}#{values.join delim}"

    [header] ++ rows

  # Format array as list
  format-list: (arr, depth, key, len-marker) ->
    indent-str = ' ' * (depth * @indent)
    item-indent = ' ' * ((depth + 1) * @indent)
    delim = @delimiter
    delim-marker = if delim is ',' => '' else delim

    # Header
    header = if key?
      "#{indent-str}#{key}[#{len-marker}#{delim-marker}]:"
    else
      "[#{len-marker}#{delim-marker}]:"

    lines = [header]

    # Process each item
    for item in arr
      if typeof item is 'object' and item isnt null and not Array.is-array item
        # Object: first field on "- " line
        keys = Object.keys item
        if keys.length > 0
          first-key = keys[0]
          formatted-first-key = @format-key first-key
          first-value = @encode-value item[first-key], depth + 1, formatted-first-key

          # Replace indent with "- " for first line
          first-line = first-value[0].replace /^\s+/, "#{item-indent}- "
          lines.push first-line

          # Add remaining fields
          for i from 1 til keys.length
            k = keys[i]
            formatted-k = @format-key k
            v-lines = @encode-value item[k], depth + 1, formatted-k
            lines ++= v-lines
        else
          # Empty object
          lines.push "#{item-indent}-"

      else if Array.is-array item
        # Nested array: inline on "- " line
        inner-len = item.length
        inner-len-marker = if @length-marker => "##{inner-len}" else inner-len
        inner-delim-marker = if delim is ',' => '' else delim
        values = item.map (el) ~> @encode-primitive el
        values-str = values.join delim
        lines.push "#{item-indent}- [#{inner-len-marker}#{inner-delim-marker}]: #{values-str}"

      else
        # Primitive
        lines.push "#{item-indent}- #{@encode-primitive item}"

    lines

  # Encode primitive value
  encode-primitive: (value) ->
    | value is null => 'null'
    | value is undefined => 'null'
    | typeof value is 'boolean' => String value
    | typeof value is 'number' => @normalize-number value
    | typeof value is 'bigint' => String value
    | value instanceof Date => @quote-string value.toISOString!
    | typeof value is 'string' => @encode-string value
    | typeof value is 'function' => 'null'
    | typeof value is 'symbol' => 'null'
    | otherwise => 'null'

  # Normalize number (avoid scientific notation, handle special values)
  normalize-number: (num) ->
    return 'null' unless isFinite num
    return '0' if num is 0 or num is -0

    # Convert to string
    str = String num

    # Handle scientific notation by converting to fixed decimal
    if /e/i.test str
      # Determine decimal places needed
      if num > 0 and num < 1
        # Small number: use enough decimals
        str = num.toFixed 20
      else if Math.abs(num) > 1e15
        # Large number: no decimals needed
        str = num.toFixed 0
      else
        # Medium number
        str = num.toFixed 10

      # Remove trailing zeros
      str = str.replace /\.?0+$/, ''

    str

  # Encode string (add quotes if needed)
  encode-string: (str) ->
    if @should-quote str
      @quote-string str
    else
      str

  # Check if string needs quotes
  should-quote: (str) ->
    return true if str is ''
    return true if str.0 is ' ' or str[str.length - 1] is ' '
    return true if str.indexOf(@delimiter) >= 0
    return true if str.indexOf(':') >= 0
    return true if str.indexOf('"') >= 0
    return true if str.indexOf('\\') >= 0
    return true if /[\x00-\x1F]/.test str
    return true if str in <[ true false null ]>
    return true if /^-?\d+(\.\d+)?([eE][+-]?\d+)?$/.test str
    return true if str.starts-with '- '
    return true if /^\[.*\]$/.test str
    return true if /^\{.*\}$/.test str
    false

  # Quote and escape string
  quote-string: (str) ->
    escaped = str
      .replace /\\/g, '\\\\'
      .replace /"/g, '\\"'
      .replace /\n/g, '\\n'
      .replace /\r/g, '\\r'
      .replace /\t/g, '\\t'

    "\"#{escaped}\""

  # Format object key (add quotes if needed)
  format-key: (key) ->
    if /^[a-zA-Z_][a-zA-Z0-9_\.]*$/.test key
      key
    else
      @quote-string key

# ============================================================================
# DECODER
# ============================================================================

decoder = (options = {}) ->
  @ <<<
    strict: false

  @ <<< options
  @

decoder.prototype = Object.create(Object.prototype) <<<
  constructor: decoder

  # Main decode entry point
  decode: (toon-str) ->
    return {} if toon-str is ''

    lines = toon-str.split '\n'
    return {} if lines.length is 0

    first-line = lines[0].trim!

    # Check root type
    if first-line.starts-with '['
      # Root array
      result = @parse-array lines, 0, 0
      result.value
    else if first-line.indexOf(':') >= 0
      # Root object
      result = @parse-object lines, 0, 0
      result.value
    else
      # Root primitive
      @parse-value first-line

  # Parse object from lines
  parse-object: (lines, start-idx, depth) ->
    obj = {}
    expected-indent = depth * 2  # Assuming indent = 2
    idx = start-idx

    while idx < lines.length
      line = lines[idx]
      current-indent = @get-indent line

      # Stop if indent is less than expected
      break if current-indent < expected-indent

      # Skip if deeper indent (handled by nested structures)
      if current-indent > expected-indent
        idx++
        continue

      trimmed = line.trim!

      # Skip empty lines
      if not trimmed
        idx++
        continue

      # Check if this is an array definition (inline, tabular, or list)
      if /^[^:]+\[.*\](\{[^}]+\})?:/.test trimmed
        # This is an array definition (e.g., tags[3]: ... or items[2]{...}:)
        # Extract the key name
        bracket-pos = trimmed.indexOf '['
        key = trimmed.substring 0, bracket-pos

        # Remove key name from line to get array definition
        array-def = trimmed.substring bracket-pos

        # Check if it's an inline array or multi-line array
        colon-pos = array-def.indexOf ':'
        after-colon = array-def.substring(colon-pos + 1).trim!

        if after-colon and not /^\[.*\]\{/.test array-def
          # Inline array (has values after colon and not tabular)
          result = @parse-array [array-def], 0, depth
          obj[key] = result.value
          idx++
        else
          # Multi-line array (tabular or list) - parse with subsequent lines
          # Create array of lines starting with array definition
          remaining-lines = [array-def] ++ lines.slice(idx + 1)
          result = @parse-array remaining-lines, 0, depth
          obj[key] = result.value
          idx = idx + result.next-idx

      # Parse key-value pair
      else if @find-colon(trimmed) >= 0
        parsed = @parse-key-value trimmed
        key = parsed.key
        value-str = parsed.value
        is-nested = parsed.is-nested

        if is-nested
          # Check next line to determine type
          next-idx = idx + 1

          if next-idx < lines.length
            next-line = lines[next-idx]
            next-indent = @get-indent next-line
            next-trimmed = next-line.trim!

            if next-indent > current-indent
              # Has nested content
              if next-trimmed.starts-with '- '
                # List array
                result = @parse-list lines, next-idx, depth + 1
                obj[key] = result.value
                idx = result.next-idx
              else if /^\[.*\]\{/.test next-trimmed or /^\[.*\]:/.test next-trimmed
                # Array (tabular or inline)
                result = @parse-array lines, next-idx, depth + 1
                obj[key] = result.value
                idx = result.next-idx
              else
                # Nested object
                result = @parse-object lines, next-idx, depth + 1
                obj[key] = result.value
                idx = result.next-idx
            else
              # Empty nested value
              obj[key] = {}
              idx++
          else
            # Empty nested value
            obj[key] = {}
            idx++
        else
          # Simple value
          obj[key] = @parse-value value-str
          idx++
      else
        # No colon, skip line
        idx++

    { value: obj, next-idx: idx }

  # Parse array (dispatcher)
  parse-array: (lines, start-idx, depth) ->
    return { value: [], next-idx: start-idx + 1 } if start-idx >= lines.length

    line = lines[start-idx]
    trimmed = line.trim!

    # Check array format
    if /^\[.*\]\{/.test trimmed
      # Tabular format
      @parse-tabular lines, start-idx, depth
    else if /^\[.*\]:/.test trimmed
      # Inline or list format - check if there are values after colon
      colon-pos = trimmed.indexOf ':'
      after-colon = trimmed.substring(colon-pos + 1).trim!

      if after-colon
        # Inline format
        @parse-inline lines, start-idx, depth
      else
        # Check next line for list items
        next-idx = start-idx + 1
        if next-idx < lines.length and lines[next-idx].trim!.starts-with '- '
          @parse-list lines, start-idx, depth
        else
          # Empty array
          @parse-inline lines, start-idx, depth
    else
      { value: [], next-idx: start-idx + 1 }

  # Parse inline array format
  parse-inline: (lines, start-idx, depth) ->
    line = lines[start-idx].trim!

    # Match [N]: values or [#N]: values or [N<delim>]: values
    m = line.match /^\[#?(\d+)(.?)\]:\s*(.*)$/

    return { value: [], next-idx: start-idx + 1 } unless m

    length = parseInt m[1], 10
    delimiter = m[2] or ','
    values-str = m[3]

    # Empty array
    return { value: [], next-idx: start-idx + 1 } unless values-str

    # Split and parse values
    values = @split-values values-str, delimiter
    arr = values.map (v) ~> @parse-value v

    { value: arr, next-idx: start-idx + 1 }

  # Parse tabular array format
  parse-tabular: (lines, start-idx, depth) ->
    line = lines[start-idx].trim!

    # Parse header: [N]{fields}: or [#N]{fields}: or [N<delim>]{fields}:
    m = line.match /^\[#?(\d+)(.?)\]\{([^}]+)\}:$/

    return { value: [], next-idx: start-idx + 1 } unless m

    length = parseInt m[1], 10
    delimiter = m[2] or ','
    fields-str = m[3]

    # Parse fields
    fields = @split-values fields-str, delimiter

    # Remove quotes from field names
    fields = fields.map (f) ~>
      f = f.trim!
      if f.0 is '"' and f[f.length - 1] is '"'
        @unquote f
      else
        f

    # Parse data rows
    arr = []
    row-indent = (depth + 1) * 2
    idx = start-idx + 1

    for i from 0 til length
      break if idx >= lines.length

      row-line = lines[idx]
      current-indent = @get-indent row-line

      break if current-indent < row-indent

      trimmed = row-line.trim!
      values = @split-values trimmed, delimiter

      # Create object from fields and values
      obj = {}
      for field, j in fields
        obj[field] = @parse-value (values[j] or 'null')

      arr.push obj
      idx++

    { value: arr, next-idx: idx }

  # Parse list array format
  parse-list: (lines, start-idx, depth) ->
    # If start line has header, parse it
    first-line = lines[start-idx].trim!
    idx = start-idx

    if /^\[.*\]:$/.test first-line
      # Has header
      idx++

    arr = []
    item-indent = (depth + 1) * 2

    while idx < lines.length
      line = lines[idx]
      current-indent = @get-indent line

      break if current-indent < item-indent

      trimmed = line.trim!

      if trimmed.starts-with '- '
        content = trimmed.substring 2

        # Check if it's an object
        if content.indexOf(':') >= 0
          # Object item
          parsed = @parse-key-value content
          obj = {}
          obj[parsed.key] = @parse-value parsed.value

          # Collect remaining fields
          idx++
          while idx < lines.length
            next-line = lines[idx]
            next-indent = @get-indent next-line

            break if next-indent <= item-indent

            next-trimmed = next-line.trim!

            # Check if it's another list item
            break if next-trimmed.starts-with '- '

            # Parse field
            if next-trimmed.indexOf(':') >= 0
              parsed2 = @parse-key-value next-trimmed
              obj[parsed2.key] = @parse-value parsed2.value

            idx++

          arr.push obj
        else if content.starts-with '['
          # Inline array item
          m = content.match /^\[#?(\d+)(.?)\]:\s*(.*)$/
          if m
            delimiter = m[2] or ','
            values-str = m[3]
            values = @split-values values-str, delimiter
            inner-arr = values.map (v) ~> @parse-value v
            arr.push inner-arr
          idx++
        else
          # Primitive item
          arr.push @parse-value content
          idx++
      else
        idx++

    { value: arr, next-idx: idx }

  # Get indentation level of a line
  get-indent: (line) ->
    count = 0
    for char in line
      break if char isnt ' '
      count++
    count

  # Find first unquoted colon
  find-colon: (str) ->
    in-quote = false
    i = 0

    while i < str.length
      char = str[i]

      if char is '"' and (i is 0 or str[i - 1] isnt '\\')
        in-quote := not in-quote
      else if char is ':' and not in-quote
        return i

      i++

    -1

  # Parse key-value pair
  parse-key-value: (str) ->
    colon-idx = @find-colon str

    if colon-idx < 0
      return { key: str, value: '', is-nested: false }

    key-str = str.substring 0, colon-idx .trim!
    value-str = str.substring colon-idx + 1 .trim!

    # Remove quotes from key if present
    key = if key-str.0 is '"' and key-str[key-str.length - 1] is '"'
      @unquote key-str
    else
      key-str

    is-nested = value-str is ''

    { key: key, value: value-str, is-nested: is-nested }

  # Parse value and infer type
  parse-value: (str) ->
    str = str.trim!

    return null if str is 'null'
    return true if str is 'true'
    return false if str is 'false'

    # Check if it's a number
    if /^-?\d+(\.\d+)?$/.test str
      return parseFloat str

    # Check if it's a quoted string
    if str.0 is '"' and str[str.length - 1] is '"'
      return @unquote str

    # Otherwise it's an unquoted string
    str

  # Remove quotes and unescape string
  unquote: (str) ->
    # Remove surrounding quotes
    content = str.substring 1, str.length - 1

    # Unescape
    content
      .replace /\\n/g, '\n'
      .replace /\\r/g, '\r'
      .replace /\\t/g, '\t'
      .replace /\\"/g, '"'
      .replace /\\\\/g, '\\'

  # Split values by delimiter, respecting quotes
  split-values: (str, delimiter) ->
    values = []
    current = ''
    in-quote = false
    i = 0

    while i < str.length
      char = str[i]

      if char is '"'
        # Check if it's escaped
        if i > 0 and str[i - 1] is '\\' and (i < 2 or str[i - 2] isnt '\\')
          current += char
        else
          in-quote := not in-quote
          current += char

      else if char is delimiter and not in-quote
        values.push current.trim!
        current := ''

      else
        current += char

      i++

    values.push current.trim! if current or values.length is 0
    values

# ============================================================================
# CONVENIENCE FUNCTIONS
# ============================================================================

# Convenience encode function
encode = (value, options) ->
  enc = new encoder options
  enc.encode value

# Convenience decode function
decode = (toon-str, options) ->
  dec = new decoder options
  dec.decode toon-str

# ============================================================================
# EXPORTS
# ============================================================================

if window?
  window <<< { encoder, decoder, encode, decode }
else
  module.exports = { encoder, decoder, encode, decode }
