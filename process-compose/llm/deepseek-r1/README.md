# README

You can run this flake using `nix run` from this target repository without manually downloading the rest.

One line commands:

```
nix run "github:lucernae/nix-config?dir=process-compose/llm/deepseek-r1"
```

The terminal will open process-compose interface in foreground mode. As long as you keep it open, Ollama server will run.

The process will try to pull Deepseek-R1:7B models from Ollama repository.
You can view the progress from the terminal panel.

Once pull finished, you can connect your AI assistant to Ollama server in `localhost:11434`.