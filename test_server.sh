#!/bin/bash
set -e

echo "🚀 Starting server tests..."

# Function to test endpoint
test_endpoint() {
    local name=$1
    local method=$2
    local url=$3
    local data=$4
    local expected_status=${5:-200}
    
    echo -n "Testing $name... "
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url")
    fi
    
    status=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$status" -eq "$expected_status" ]; then
        echo "✅ OK (HTTP $status)"
        return 0
    else
        echo "❌ FAILED (HTTP $status)"
        echo "Response: $body"
        return 1
    fi
}

# Start server in background
echo "Starting server..."
zig build run-server -- -m models/rocket-3b.Q4_K_M.gguf &
SERVER_PID=$!

# Wait for server to start
echo "Waiting for server to start..."
for i in {1..30}; do
    if curl -s http://localhost:8080/health > /dev/null; then
        echo "Server is ready!"
        break
    fi
    sleep 1
done

# Run tests
test_endpoint "Health Check" "GET" "http://localhost:8080/health"
test_endpoint "Model Info" "GET" "http://localhost:8080/v1/models"
test_endpoint "Completion" "POST" "http://localhost:8080/completion" \
    '{"prompt": "Hello", "n_predict": 5}'
test_endpoint "Chat Completion" "POST" "http://localhost:8080/v1/chat/completions" \
    '{"model": "test", "messages": [{"role": "user", "content": "Hi"}], "max_tokens": 10}'

# Cleanup
echo "Stopping server..."
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null || true

echo "✅ All tests completed!"