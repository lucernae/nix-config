# Template Processing with processTemplates

This directory contains a Nix function for processing templates with variable substitution.

## Overview

The `processTemplates` function reads files from a source directory, performs variable substitution using a provided context, and writes the results to a target directory with proper permissions.

## Usage

### Using nix run

The `processTemplates` function is exposed as a flake app, which can be run using `nix run`:

```bash
# From the repository root
nix run .#processTemplates -- --help

# Basic usage
nix run .#processTemplates -- \
  --context ./templates/metatemplates/sample-context.nix \
  --source ./path/to/source/templates \
  --target ./path/to/target/directory
```

### Command-line Options

- `--context FILE`: Path to a Nix file containing the context variables (required)
- `--source DIR`: Path to the source directory containing templates (required)
- `--target DIR`: Path to the target directory where processed files will be written (required)
- `--help`: Show help message

### Context File Format

The context file should be a Nix file that evaluates to an attribute set. For example:

```nix
{
  name = "MyProject";
  version = "1.0.0";
  author = "Your Name";
  description = "A sample project created with processTemplates";
  license = "MIT";
  year = "2023";
}
```

### Template Format

Templates are regular files with variable placeholders in the format `${variable}`. For example:

```markdown
# ${name}

Version: ${version}
Author: ${author}

## Description

${description}

## License

Copyright (c) ${year} ${author}

Licensed under the ${license} License.
```

## Examples

### Basic Example

1. Create a context file:

```nix
# context.nix
{
  name = "MyProject";
  version = "1.0.0";
  author = "Your Name";
}
```

2. Create template files in a source directory:

```
# source/README.md
# ${name}

Version: ${version}
Author: ${author}
```

3. Run the processTemplates app:

```bash
nix run .#processTemplates -- \
  --context ./context.nix \
  --source ./source \
  --target ./output
```

4. Check the output:

```
# output/README.md
# MyProject

Version: 1.0.0
Author: Your Name
```

## Implementation Details

The `processTemplates` function:

1. Recursively gets all files from the source directory
2. For each file, it reads the content and performs variable substitution
3. It creates the necessary directory structure in the target directory
4. It writes the processed content to the target directory with proper permissions

## Testing

Tests for the `processTemplates` function are available in the `.junie/tests/metatemplates` directory.
