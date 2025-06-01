# Greeting Tool Example

This is a simple example of a FastMCP server with a greeting tool. It demonstrates how to create and use tools with
FastMCP.

## Overview

This example includes two tools:

1. `greet`: A tool that greets a user by name
2. `farewell`: A tool that says goodbye to a user by name

## Running the Example

To run this example, follow these steps:

1. Make sure you have set up the development environment as described in the main README.md
2. Activate the virtual environment:
   ```bash
   source .venv/bin/activate
   ```
3. Run the greeting tool example:
   ```bash
   python examples/greeting/greeting_tool.py
   ```

## Using the Tools

Once the server is running, you can use the tools through the FastMCP API. Here are some examples:

### Using the API

You can also use the tools programmatically:

```python
import asyncio
from fastmcp.client import Client


async def main():
    # Connect to the FastMCP server
    client = Client("http://localhost:8000")

    # List available tools
    tools = await client.list_tools()
    print("Available tools:", [tool.name for tool in tools])

    # Call the greet tool
    result = await client.call_tool("greet", {"name": "Alice"})
    print(result)  # Output: Hello, Alice!

    # Call the farewell tool
    result = await client.call_tool("farewell", {"name": "Bob"})
    print(result)  # Output: Goodbye, Bob! Have a great day!


if __name__ == "__main__":
    asyncio.run(main())
```

## Next Steps

You can extend this example by:

1. Adding more tools with different functionality
2. Adding more parameters to the existing tools
3. Creating a class-based implementation using `MCPMixin`