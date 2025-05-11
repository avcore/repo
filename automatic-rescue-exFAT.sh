#!/bin/bash

# =============================================
# 🛡️ Скрипт автоматического спасения exFAT диска с Telegram уведомлениями
# =============================================

# === НАСТРОЙКИ TELEGRAM ===
TELEGRAM_BOT_TOKEN="ВСТАВЬ_СВОЙ_ТОКЕН"
TELEGRAM_CHAT_ID="ВСТАВЬ_СВОЙ_CHAT_ID"

send_telegram() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"         -d chat_id="$TELEGRAM_CHAT_ID"         -d text="$message" > /dev/null
}

send_telegram "🛡️ Запуск скрипта спасения exFAT"

# УСТАНОВКА ОБЯЗАТЕЛЬНЫХ ПАКЕТОВ
sudo apt-get update
sudo apt-get install -y gddrescue testdisk exfatprogs smartmontools

# ЗАПРОС У ПОЛЬЗОВАТЕЛЯ
read -p "Укажите имя устройства (пример: /dev/sde2): " DEVICE

# ПРОВЕРКА ДИСКА
echo "\n👉 Проверка SMART статуса..."
sudo smartctl -a $(echo $DEVICE | sed 's/[0-9]*$//') > smart_status.txt
send_telegram "✅ Проверка SMART статуса завершена. Проверь файл smart_status.txt"

# СОЗДАНИЕ ОБРАЗА
echo "\n👉 Создание образа..."
read -p "Введите имя файла образа (пример: backup_sde2.img): " IMAGE
sudo ddrescue -d -r3 $DEVICE $IMAGE ${IMAGE}.log
if [ $? -eq 0 ]; then
    send_telegram "✅ Образ успешно создан: $IMAGE"
else
    send_telegram "❌ Ошибка при создании образа!"
    exit 1
fi

# ПОПЫТКА МОНТИРОВАНИЯ
echo "\n👉 Попытка монтирования образа..."
sudo mkdir -p /mnt/recovery
sudo mount -o loop,ro $IMAGE /mnt/recovery && send_telegram "✅ Образ смонтирован в /mnt/recovery" && exit 0

# ЕСЛИ НЕ ПОЛУЧИЛОСЬ → ПРОБОВАТЬ FSCK
echo "\n⚠️ Образ не монтируется. Попытка восстановления..."
sudo fsck.exfat $IMAGE || sudo exfatrepair $IMAGE

# ПОВТОРНАЯ ПОПЫТКА МОНТИРОВАНИЯ
echo "\n👉 Повторная попытка монтирования..."
sudo mount -o loop,ro $IMAGE /mnt/recovery && send_telegram "✅ Образ восстановлен и смонтирован в /mnt/recovery" && exit 0

# ПОСЛЕДНИЙ ШАНС — TESTDISK
send_telegram "❗ Не удалось восстановить автоматически. Запустите вручную: sudo testdisk $IMAGE"
echo "\n❗ Если не получилось — запускаем TestDisk вручную"
echo "Выполните: sudo testdisk $IMAGE"
