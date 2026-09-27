#!/bin/bash

echo "🔄 RAG Ingestion Monitor - Press Ctrl+C to stop"
echo "=================================================="

while true; do
    clear
    echo "📊 RAG Status (Updated every 5 seconds)"
    echo "=================================================="
    echo ""

    STATUS=$(curl -s http://localhost:3001/api/rag/status)
    DOCS=$(echo $STATUS | python3 -c "import sys, json; print(json.load(sys.stdin).get('documents', 0))")
    CATS=$(echo $STATUS | python3 -c "import sys, json; print(json.load(sys.stdin).get('categories', 0))")

    echo "Documents indexed: $DOCS"
    echo "Categories found:  $CATS"
    echo ""

    if [ "$DOCS" -eq 0 ]; then
        echo "⏳ Ingestion in progress..."
        echo "   (Fetching from documentation sources)"
    else
        echo "✅ RAG database is ready!"
        echo "   Chat will now include documentation context"
    fi

    echo ""
    echo "Last updated: $(date)"
    sleep 5
done
