# LLAMA Server - Zig Build System

## Quick Start

1. **Clone and setup**:
```bash
git clone --recursive https://github.com/yourusername/llama.cpp.zig.git
cd llama.cpp.zig
```

2. **Download a model**:
```bash
mkdir -p models
wget https://huggingface.co/TheBloke/rocket-3B-GGUF/resolve/main/rocket-3b.Q4_K_M.gguf -O models/rocket-3b.Q4_K_M.gguf
```

3. **Build and run**:
```bash
# Quick start - builds and runs with default model
zig build quickstart

# Or build manually
zig build -Dserver=true -Doptimize=ReleaseFast

# Run with custom settings
zig build run-server -- -m models/rocket-3b.Q4_K_M.gguf --threads 8
```

4. **Test the server**:
```bash
# In another terminal
curl http://localhost:8080/health

# Test completion
curl -X POST http://localhost:8080/completion \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello, world!", "n_predict": 20}'
```

5. **Open WebUI**:
Visit http://localhost:8080 in your browser

## Build Options

| Option | Description | Default |
|--------|-------------|---------|
| `-Dserver=true` | Build llama-server | false |
| `-Dserver-ssl=true` | Enable SSL support | false |
| `-Dserver-metrics=true` | Enable metrics endpoint | true |
| `-Dserver-embed=true` | Embed web assets | true |
| `-Doptimize=ReleaseFast` | Optimization level | Debug |

## Testing

Run the automated test suite:
```bash
./test_server.sh
```

## Documentation

See `.docs/build-llama-server-through-zig.md` for the complete guide.