# Markdown Style Guideline

This document defines the markdown writing style for this project.

## General Rules

### Language
- Use English for all documentation
- Keep language clear and concise
- Use technical terms consistently

### Formatting

#### Emojis
- Avoid unnecessary emojis in documentation
- Only use emojis when they add clear value (e.g., in status indicators)
- Never use emojis in headings

#### Bold Text
- Minimize use of bold text (`**text**`)
- Use bold only for:
  - Critical warnings or important notes
  - First occurrence of key terms in a section
- Do not use bold for emphasis in regular paragraphs

#### Code Blocks
- All code examples must use four-space indentation
- Always specify language for syntax highlighting
- Example:

        ```javascript
        const example = "code here";
        ```

#### Headings
- Use clear, descriptive headings
- Follow proper heading hierarchy (h1 > h2 > h3)
- No trailing punctuation in headings
- Use sentence case (capitalize only first word)

#### Lists
- Use hyphens (`-`) for unordered lists
- Keep list items concise
- Maintain consistent indentation (2 spaces per level)

#### Links
- Use descriptive link text
- Avoid "click here" or "this link"
- Format: `[descriptive text](url)`

## Structure

### README.md Structure
1. Title and brief description
2. Features (if applicable)
3. Installation
4. Quick start / Usage
5. API documentation (if applicable)
6. Project structure
7. Testing
8. Documentation links
9. License and author

### Code Examples
- Keep examples simple and focused
- Show real-world usage
- Include comments only when necessary
- Always indent with 4 spaces

### Example Format

    # Project title

    Brief description of what this project does.

    ## Features

    - Feature one
    - Feature two
    - Feature three

    ## Installation

        npm install package-name

    ## Usage

        const module = require('module-name');

        // Use the module
        const result = module.doSomething();

    ## API

    ### functionName(param1, param2)

    Description of what the function does.

    Parameters:
    - `param1` - Description
    - `param2` - Description

    Returns: Description of return value

    Example:

        const result = functionName('value1', 'value2');

## What to Avoid

- Excessive emojis (❌, ✅, 🎉, etc.)
- Overuse of bold text
- Long paragraphs without structure
- Mixing languages (stick to English)
- Code blocks without language specification
- Inconsistent indentation
- Vague or ambiguous language
