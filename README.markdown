

---

# BotLink – ربات تلگرام مدیریت فایل‌ها (Ubuntu 24.04)

BotLink یک ربات تلگرام است که فایل‌های ارسال‌شده را در یک کانال خصوصی ذخیره می‌کند و لینک دانلود مستقیم می‌دهد. با گذشت مدت مشخص (پیش‌فرض ۶ ساعت) فایل‌ها به‌صورت خودکار از کانال حذف می‌شوند تا فضا آزاد بماند.
این مخزن برای اوبونتو **24.04** به‌روز شده و نصب پایتون را **داخل virtualenv (.venv)** انجام می‌دهد (سازگار با **PEP 668**) و اجرای دائم با **systemd** دارد.

---

## ✨ ویژگی‌ها

* پشتیبانی از انواع فایل‌ها و ارائه لینک دانلود مستقیم
* حذف خودکار فایل‌ها پس از زمان تعیین‌شده
* نصب یک‌مرحله‌ای با `install.sh` (می‌سازد: `.venv`، نصب وابستگی‌ها، سرویس systemd)
* اسکریپت مدیریتی ساده `manage.sh` برای `start/stop/restart/status/logs`
* پیکربندی خارج از کد با فایل `.env`

---

## ✅ پیش‌نیازها

* سرور اوبونتو **24.04** با دسترسی `sudo`
* ساخت ربات و دریافت **BOT\_TOKEN** از [BotFather](https://t.me/BotFather)
* دسترسی ادمین ربات به کانال مقصد و داشتن `CHANNEL_ID` (مثلاً `@my_channel`)
* شناسه عددی مالک ربات (**OWNER\_ID**)

---

## 🚀 نصب سریع

```bash
# 1) کلون مخزن
git clone https://github.com/<your-username>/telegram-bot.git
cd telegram-bot

# 2) مجوز اجرا به اسکریپت‌ها
chmod +x install.sh manage.sh

# 3) نصب
./install.sh

# 4) مشاهده وضعیت یا لاگ‌ها
./manage.sh status
./manage.sh logs
```

> **نکته:** اسکریپت نصب، اگر `.env` نداشته باشید و `.env.example` وجود داشته باشد، یک `.env` برای شما می‌سازد؛ مقادیرش را ویرایش کنید.

---

## 🔧 پیکربندی (`.env`)

نمونه فایل در `.env.example`:

```ini
BOT_TOKEN=توکن_ربات_از_BotFather
OWNER_ID=شناسه_عددی_مالک
CHANNEL_ID=@نام_کانال

# اختیاری‌ها
# WEBHOOK_URL=
# PORT=8080
# DATABASE_URL=
```

> **مهم:** فایل `.env` در سرویس systemd با `EnvironmentFile` خوانده می‌شود. هر تغییری دادید:

```bash
sudo systemctl restart telegram-bot
```

---

## 🧭 مدیریت سرویس

```bash
./manage.sh start     # شروع سرویس
./manage.sh stop      # توقف
./manage.sh restart   # ریستارت
./manage.sh status    # وضعیت
./manage.sh logs      # لاگ‌های زنده (journalctl)
```

نام سرویس پیش‌فرض: `telegram-bot`
اگر لازم بود عوضش کنید، مقدار `SERVICE_NAME` را در `install.sh` تغییر دهید.

---

## ♻️ به‌روزرسانی

```bash
git pull
./install.sh   # venv را نگه می‌دارد و وابستگی‌ها را به‌روز می‌کند
```

---

## 🗂️ ساختار پیشنهادی مخزن

```
telegram-bot/
├─ bot.py
├─ requirements.txt
├─ install.sh
├─ manage.sh
├─ .env.example
├─ .gitignore
└─ README.markdown
```

`.gitignore` حتماً این‌ها را داشته باشد:

```gitignore
# Python
__pycache__/
*.py[cod]
*.egg-info/

# Virtualenv
.venv/

# Env
.env

# OS/Editor
.DS_Store
.idea/
.vscode/
```

---

## 🧪 تست سریع محلی (اختیاری)

اگر خواستید بدون systemd هم اجرا بگیرید:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
python bot.py
```

---

## ❗ عیب‌یابی

* **PEP 668 / externally-managed-environment**
  از `./install.sh` استفاده کنید؛ همه چیز داخل `.venv` نصب می‌شود.

* **سرویس بالا نمی‌آید**

  ```bash
  ./manage.sh status
  ./manage.sh logs
  ```

  پیام خطا را بررسی و مقادیر `.env` را تصحیح کنید؛ سپس `./manage.sh restart`.

* **مجوز فایل‌ها**
  سرویس با کاربر فعلی (`$USER`) اجرا می‌شود. اگر کاربر دیگری می‌خواهید، در یونیت systemd مقدار `User=` را تغییر دهید و دسترسی‌های مسیر پروژه را مطابق آن تنظیم کنید.

---

## 📝 مجوز

این پروژه تحت مجوز MIT منتشر شده است. جزئیات در فایل `LICENSE`.

---

### ضمیمه – خلاصه اسکریپت‌ها (برای مرجع)

**install.sh**: ایجاد `.venv`، نصب وابستگی‌ها، نوشتن یونیت systemd و فعال‌سازی سرویس.
**manage.sh**: میانبرهای `systemctl` و `journalctl` برای کار سریع با سرویس.

> محتوای کامل این اسکریپت‌ها در مخزن موجود است؛ اگر تغییر می‌دهید، بعد از ذخیره، `sudo systemctl daemon-reload` و سپس `./manage.sh restart` را اجرا کنید.

---

اگر خواستی، نسخه انگلیسی README هم برات آماده می‌کنم.
