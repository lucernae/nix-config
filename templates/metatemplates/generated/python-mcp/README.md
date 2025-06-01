# MCP Project

A Model Context Protocol (MCP) project using fastmcp.

## Getting Started

This project uses [Nix](https://nixos.org/) with [flakes](https://nixos.wiki/wiki/Flakes) to provide a consistent development environment. Make sure you have Nix installed with flakes enabled.

### Setup Development Environment

1. Clone this repository
2. Enter the development shell:

```bash
nix develop
```

3. Set up the Python virtual environment:

```bash
setup-venv
```

4. Install dependencies:

```bash
install-deps
```

## Running the MCP Server

To run the MCP server, use the following command:

```bash
run-mcp
```

Alternatively, you can run it directly with:

```bash
uv run mcp-server
```

To run the greeting tool example, use:

```bash
run-greeting
```

Or directly with:

```bash
uv run greeting-tool
```

The server will start and be available at http://localhost:8000 by default.

## Examples

This project includes examples to help you get started with FastMCP:

### Greeting Tool Example

A simple example that demonstrates how to create and use tools with FastMCP. The example includes two tools:

1. `greet`: A tool that greets a user by name
2. `farewell`: A tool that says goodbye to a user by name

To run the example:

```bash
# Activate the virtual environment if not already activated
source .venv/bin/activate

# Run the greeting tool server
python examples/greeting/greeting_tool.py
```

You can also try the client example to see how to use the tools programmatically:

```bash
# In a separate terminal, with the server running
source .venv/bin/activate
python examples/greeting/client_example.py
```

For more details, see the [Greeting Tool Example README](examples/greeting/README.md).

## Project Structure

- `pyproject.toml`: Project configuration and dependencies
- `README.md`: This file
- `examples/`: Example projects
  - `greeting/`: A simple greeting tool example

## Development

This project uses the following tools for development:

- [black](https://black.readthedocs.io/): Code formatting
- [isort](https://pycqa.github.io/isort/): Import sorting
- [mypy](https://mypy.readthedocs.io/): Static type checking
- [pytest](https://docs.pytest.org/): Testing

You can install the development dependencies with:

```bash
uv pip install -e ".[dev]"
```
