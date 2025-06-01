"""
Example client for the greeting tool.

This example demonstrates how to use the greeting tools programmatically.
"""

import asyncio
from fastmcp.client import StdioClient


async def main():
    # Connect to the FastMCP server via stdio
    client = StdioClient()

    try:
        # List available tools
        tools = await client.list_tools()
        print("Available tools:", [tool.name for tool in tools])

        # Call the greet tool
        result = await client.call_tool("greet", {"name": "Alice"})
        print(result)  # Output: Hello, Alice!

        # Call the greet tool with default parameter
        result = await client.call_tool("greet", {})
        print(result)  # Output: Hello, World!

        # Call the farewell tool
        result = await client.call_tool("farewell", {"name": "Bob"})
        print(result)  # Output: Goodbye, Bob! Have a great day!
    except Exception as e:
        print(f"Error: {e}")
    finally:
        pass


if __name__ == "__main__":
    asyncio.run(main())
