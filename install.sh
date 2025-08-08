#!/bin/bash

# رنگ‌ها برای خروجی زیباتر
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # بدون رنگ

# متغیرها
REPO_URL="https://github.com/mmad261/telegram-bot.git"
INSTALL_DIR="/home/telegrambot/telegram-bot"
BOT_USER="telegrambot"
VENV_DIR="$INSTALL_DIR/venv"
SERVICE_NAME="bot"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
ENV_FILE="$INSTALL_DIR/.env"
PANEL_DIR="/root/botlink"
PANEL_SCRIPT="$PANEL_DIR/bopanel"

# تابع نمایش خطا و خروج
error_exit() {
  echo -e "${RED}خطا: $1${NC}"
  exit 1
}

# تابع بررسی دسترسی روت
check_root() {
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}لطفاً اسکریپت را با sudo اجرا کنید!${NC}"
    exit 1
  fi
}

# تابع دریافت ورودی‌های کاربر
get_user_input() {
  echo -e "${GREEN}لطفاً اطلاعات زیر را وارد کنید:${NC}"
  read -p "توکن ربات تلگرام: " TOKEN
  if [ -z "$TOKEN" ]; then
    error_exit "توکن نمی‌تواند خالی باشد!"
  fi
  read -p "آیدی صاحب ربات (Owner ID): " OWNER_ID
  if ! [[ "$OWNER_ID" =~ ^[0-9]+$ ]]; then
    error_exit "آیدی صاحب ربات باید یک عدد باشد!"
  fi
  read -p "آیدی کانال (Channel ID، با - شروع شود): " CHANNEL_ID
  if ! [[ "$CHANNEL_ID" =~ ^-[0-9]+$ ]]; then
    error_exit "آیدی کانال باید یک عدد با پیشوند - باشد!"
  fi
}

# تابع نصب اولیه
install_bot() {
  echo -e "${GREEN}شروع نصب ربات تلگرامی...${NC}"

  # دریافت اطلاعات از کاربر
  get_user_input

  # نصب وابستگی‌های سیستمی
  echo "نصب پکیج‌های مورد نیاز..."
  apt update || error_exit "به‌روزرسانی مخازن شکست خورد"
  apt install -y python3 python3-pip python3-venv git || error_exit "نصب پکیج‌ها شکست خورد"

  # ایجاد کاربر برای ربات
  if ! id "$BOT_USER" >/dev/null 2>&1; then
    echo "ایجاد کاربر $BOT_USER..."
    adduser --disabled-password --gecos "" $BOT_USER || error_exit "ایجاد کاربر شکست خورد"
    usermod -aG sudo $BOT_USER
  fi

  # کلون کردن مخزن
  echo "کلون کردن مخزن پروژه..."
  if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
  fi
  su - $BOT_USER -c "git clone $REPO_URL $INSTALL_DIR" || error_exit "کلون کردن مخزن شکست خورد. مطمئن شوید دسترسی SSH یا توکن GitHub تنظیم شده است."

  # تنظیم محیط مجازی و نصب وابستگی‌ها
  echo "تنظیم محیط مجازی و نصب وابستگی‌ها..."
  su - $BOT_USER -c "python3 -m venv $VENV_DIR"
  su - $BOT_USER -c "source $VENV_DIR/bin/activate && pip install -r $INSTALL_DIR/requirements.txt" || error_exit "نصب وابستگی‌ها شکست خورد"

  # ایجاد فایل .env
  echo "ایجاد فایل .env..."
  su - $BOT_USER -c "cat > $ENV_FILE <<EOF
TOKEN=$TOKEN
OWNER_ID=$OWNER_ID
CHANNEL_ID=$CHANNEL_ID
EOF"
  chown $BOT_USER:$BOT_USER $ENV_FILE
  chmod 600 $ENV_FILE

  # تنظیم سرویس systemd
  echo "تنظیم سرویس systemd..."
  cp $INSTALL_DIR/bot.service $SERVICE_FILE || error_exit "کپی فایل سرویس شکست خورد"
  chown root:root $SERVICE_FILE
  chmod 644 $SERVICE_FILE
  systemctl daemon-reload || error_exit "بارگذاری مجدد systemd شکست خورد"
  systemctl enable $SERVICE_NAME || error_exit "فعال‌سازی سرویس شکست خورد"
  systemctl start $SERVICE_NAME || error_exit "راه‌اندازی سرویس شکست خورد"

  # تنظیم دسترسی برای ری‌استارت سرویس
  echo "تنظیم دسترسی sudo برای ری‌استارت سرویس..."
  echo "$BOT_USER ALL=(ALL) NOPASSWD: /bin/systemctl restart $SERVICE_NAME" > /etc/sudoers.d/$BOT_USER
  chmod 440 /etc/sudoers.d/$BOT_USER

  # نصب اسکریپت پنل
  echo "نصب پنل مدیریت در $PANEL_DIR..."
  mkdir -p $PANEL_DIR
  cp $INSTALL_DIR/bopanel.sh $PANEL_SCRIPT || error_exit "کپی اسکریپت پنل شکست خورد"
  chown root:root $PANEL_SCRIPT
  chmod 755 $PANEL_SCRIPT
  ln -sf $PANEL_SCRIPT /usr/local/bin/bopanel || error_exit "ایجاد لینک پنل شکست خورد"

  echo -e "${GREEN}نصب با موفقیت انجام شد! ربات در حال اجرا است.${NC}"
  echo "وضعیت سرویس را بررسی کنید: sudo systemctl status $SERVICE_NAME"
  echo "لاگ‌ها را بررسی کنید: tail -f $INSTALL_DIR/bot.log"
  echo "برای مدیریت ربات، به $PANEL_DIR بروید و 'bopanel' را اجرا کنید."
  echo "یا از دستور زیر استفاده کنید:"
  echo "sudo bash -c \"\$(curl -sL $REPO_URL/raw/main/install.sh)\" @ <دستور>"
  echo "دستورات موجود: install, update"
}

# تابع به‌روزرسانی
update_bot() {
  echo -e "${GREEN}به‌روزرسانی ربات تلگرامی...${NC}"
  if [ ! -d "$INSTALL_DIR" ]; then
    error_exit "ربات نصب نشده است. ابتدا '@ install' را اجرا کنید."
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
  echo "وضعیت سرویس را بررسی کنید: sudo systemctl status $SERVICE_NAME"
}

# مدیریت دستورات
case "$1" in
  install)
    check_root
    install_bot
    ;;
  update)
    check_root
    update_bot
    ;;
  *)
    echo -e "${RED}دستور نامعتبر. استفاده:${NC}"
    echo "sudo bash -c \"\$(curl -sL $REPO_URL/raw/main/install.sh)\" @ <دستور>"
    echo "دستورات موجود: install, update"
    echo "برای پنل مدیریت، به $PANEL_DIR بروید و 'bopanel' را اجرا کنید."
    exit 1
    ;;
esac
