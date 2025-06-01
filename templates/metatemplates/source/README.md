# Nix Flake Metatemplates

This is an example of a metatemplates.

Some of the content here were interpolated.

It has project name: ${context.name}

It can run nix function ${builtins.toJSON {foo="bar";}}
Like this too ${utils.custom-func {bar="biz";}}