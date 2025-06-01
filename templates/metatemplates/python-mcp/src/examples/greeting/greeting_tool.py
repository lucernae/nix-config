"""
A simple example of a greeting tool using fastmcp.

This example demonstrates how to create a simple tool that greets a user by name.
"""

from fastmcp import FastMCP

# Create a FastMCP instance
mcp = FastMCP()


@mcp.tool()
def greet(name: str = "World") -> str:
    """
    Greet a user by name.

    Args:
        name: The name of the user to greet. Defaults to "World".

    Returns:
        A greeting message.
    """
    return f"Hello, {name}!"


@mcp.tool()
def farewell(name: str = "World") -> str:
    """
    Say goodbye to a user by name.

    Args:
        name: The name of the user to say goodbye to. Defaults to "World".

    Returns:
        A farewell message.
    """
    return f"Goodbye, {name}! Have a great day!"


def main():
    """Run the FastMCP server with greeting tools."""
    # Run the FastMCP server
    print("Starting FastMCP server with greeting tools...")
    print("Available tools:")
    print("- greet: Greet a user by name")
    print("- farewell: Say goodbye to a user by name")
    mcp.run()


if __name__ == "__main__":
    main()