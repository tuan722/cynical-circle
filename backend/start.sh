#!/bin/bash

echo "🚀 Запуск Cynical Circle веб-интерфейса..."
echo "📁 Директория: $(pwd)"
echo "🌐 Сервер будет доступен на: http://localhost:3000"
echo "⏹️  Для остановки нажмите Ctrl+C"
echo ""

# Запускаем HTTP сервер
python3 -m http.server 3000
