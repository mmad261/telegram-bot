#!/bin/bash

# رنگ‌ها برای خروجی زیباتر
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # بدون رنگ

# متغیرها
INSTALL_DIR="/home/telegrambot/telegram-bot"
VENV_DIR="$INSTALL_DIR/venv"
SERVICE_NAME="bot"
BOT_USER="telegrambot"

# تابع نمایش خطا و خروج
error_exit() {
  echo -e "${RED}خطا: $1${NC}"
  exit 1
}

# تابع بررسی دسترسی روت
check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}لطفاً پنل را با sudo اجرا کنید!${NC}"
    exit 1
  fi
}

# تابع به‌روزرسانی
update_bot() {
  echo -e "${GREEN}به‌روزرسانی ربات تلگرامی...${NC}"
  if [ ! -d "$INSTALL_DIR" ]; then
    error_exit "ربات نصب نشده است. ابتدا ربات را نصب کنید."
  fi

  # کشیدن کد جدید
  echo "دریافت کد جدید از GitHub..."
  su - $BOT_USER -c "cd $INSTALL_DIR && git pull origin main" || error_exit "دریافت کد جدید شکست خورد"

  # به‌روزرسانی وابستگی‌ها
  echo "به‌روزرسانی وابستگی‌ها..."
  su - $BOT_USER -c "source $VENV_DIR/bin/activate && pip install -r $INSTALL_DIR/requirements.txt" || error_exit "به‌روزرسانی وابستگی‌ها شکست خورد"

  # ری‌استارت سرویس
  echo "ری‌استارت سرویس ربات..."
  systemctl restart $SERVICE_NAME || error_exit "ری‌استارت سرویس شکست خورد"

  echo -e "${GREEN}به‌روزرسانی با موفقیت انجام شد!${NC}"
}

# تابع شروع/توقف
start_stop_bot() {
  echo "1) شروع ربات"
  echo "2) توقف ربات"
  read -p "انتخاب کنید (1 یا 2): " choice
  case $choice in
    1)
      echo -e "${GREEN}شروع ربات...${NC}"
      systemctl start $SERVICE_NAME || error_exit "شروع سرویس شکست خورد"
      echo -e "${GREEN}ربات با موفقیت شروع شد!${NC}"
      ;;
    2)
      echo -e "${GREEN}توقف ربات...${NC}"
      systemctl stop $SERVICE_NAME || error_exit "توقف سرویس شکست خورد"
      echo -e "${GREEN}ربات با موفقیت متوقف شد!${NC}"
      ;;
    *)
      echo -e "${RED}انتخاب نامعتبر!${NC}"
      ;;
  esac
}

# تابع حذف
uninstall_bot() {
  echo -e "${GREEN}حذف ربات تلگرامی...${NC}"
  systemctl stop $SERVICE_NAME 2>/dev/null
  systemctl disable $SERVICE_NAME 2>/dev/null
  rm -f /etc/systemd/system/$SERVICE_NAME.service
  systemctl daemon-reload 2>/dev/null
  rm -rf $INSTALL_DIR
  userdel -r $BOT_USER 2>/dev/null
  rm -f /etc/sudoers.d/$BOT_USER
  rm -f /root/botlink/bopanel
  rm -f /usr/local/bin/bopanel
  echo -e "${GREEN}ربات با موفقیت حذف شد!${NC}"
}

# تابع نمایش وضعیت
status_bot() {
  echo -e "${GREEN}نمایش وضعیت ربات...${NC}"
  systemctl status $SERVICE_NAME
}

# تابع نمایش لاگ‌ها
logs_bot() {
  echo -e "${GREEN}نمایش لاگ‌های ربات...${NC}"
  tail -n 50 $INSTALL_DIR/bot.log
  echo -e "${GREEN}برای مشاهده لاگ‌ها به صورت زنده، اجرا کنید: tail -f $INSTALL_DIR/bot.log${NC}"
}

# منوی اصلی پنل
check_root
while true; do
  clear
  echo -e "${GREEN}پنل مدیریت ربات تلگرامی${NC}"
  echo "1) به‌روزرسانی ربات"
  echo "2) شروع/توقف ربات"
  echo "3) حذف ربات"
  echo "4) نمایش وضعیت"
  echo "5) نمایش لاگ‌ها"
  echo "6) خروج"
  read -p "لطفاً یک گزینه را انتخاب کنید (1-6): " choice

  case $choice in
    1)
      update_bot
      read -p "برای ادامه Enter را فشار دهید..."
      ;;
    2)
      start_stop_bot
      read -p "برای ادامه Enter را فشار دهید..."
      ;;
    3)
      uninstall_bot
      break
      ;;
    4)
      status_bot
      read -p "برای ادامه Enter را فشار دهید..."
      ;;
    5)
      logs_bot
      read -p "برای ادامه Enter را فشار دهید..."
      ;;
    6)
      echo -e "${GREEN}خروج از پنل...${NC}"
      break
      ;;
    *)
      echo -e "${RED}گزینه نامعتبر!${NC}"
      read -p "برای ادامه Enter را فشار دهید..."
      ;;
  esac
done
