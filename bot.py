import logging
import os
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
from dotenv import load_dotenv

# بارگذاری متغیرهای محیطی از فایل .env
load_dotenv()

# تنظیمات لاگ
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

# متغیرهای محیطی
TOKEN = os.getenv("TOKEN")
OWNER_ID = int(os.getenv("OWNER_ID"))
CHANNEL_ID = int(os.getenv("CHANNEL_ID"))
DELETE_AFTER_SECONDS = 6 * 3600  # 6 ساعت

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user.id != OWNER_ID:
        await update.message.reply_text("شما مجاز به استفاده از این ربات نیستید!")
        return
    await update.message.reply_text("سلام! فایل خود را ارسال کنید تا لینک دانلود مستقیم دریافت کنید. فایل‌ها پس از 6 ساعت حذف می‌شوند.")

async def handle_file(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user.id != OWNER_ID:
        await update.message.reply_text("شما مجاز به استفاده از این ربات نیستید!")
        return

    message = update.message
    file = None

    # بررسی نوع فایل ارسالی
    if message.document:
        file = message.document
    elif message.photo:
        file = message.photo[-1]  # بالاترین کیفیت عکس
    elif message.video:
        file = message.video
    elif message.audio:
        file = message.audio
    elif message.voice:
        file = message.voice

    if file:
        # دریافت اطلاعات فایل
        file_info = await file.get_file()
        file_url = file_info.file_path
        file_name = getattr(file, 'file_name', 'unnamed_file')

        # ارسال فایل به کانال
        channel_message = await context.bot.send_document(
            chat_id=CHANNEL_ID,
            document=file.file_id,
            caption=f"فایل: {file_name}\nارسال‌شده توسط: @{update.effective_user.username or 'کاربر'}"
        )

        # برنامه‌ریزی حذف پیام پس از 6 ساعت
        context.job_queue.run_once(
            delete_message,
            DELETE_AFTER_SECONDS,
            data={"chat_id": CHANNEL_ID, "message_id": channel_message.message_id},
            name=f"delete_{channel_message.message_id}"
        )

        # ارسال لینک دانلود به کاربر
        await message.reply_text(f"لینک دانلود فایل شما:\n{file_url}\n\nاین لینک موقت است و فایل پس از 6 ساعت از کانال حذف می‌شود.")
    else:
        await update.message.reply_text("لطفاً یک فایل (عکس، ویدیو، سند و غیره) ارسال کنید.")

async def delete_message(context: ContextTypes.DEFAULT_TYPE):
    job = context.job
    try:
        await context.bot.delete_message(
            chat_id=job.data["chat_id"],
            message_id=job.data["message_id"]
        )
        logger.info(f"پیام {job.data['message_id']} از کانال {job.data['chat_id']} حذف شد.")
    except Exception as e:
        logger.error(f"خطا در حذف پیام: {e}")

async def error_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    logger.error(f"Update {update} caused error {context.error}")
    if update and update.message:
        await update.message.reply_text("خطایی رخ داد. لطفاً دوباره امتحان کنید.")

def main():
    # ایجاد اپلیکیشن ربات
    application = Application.builder().token(TOKEN).build()

    # هندلر دستور /start
    application.add_handler(CommandHandler("start", start))

    # هندلر فایل‌های ارسالی
    application.add_handler(MessageHandler(filters.Document.ALL | filters.PHOTO | filters.VIDEO | filters.AUDIO | filters.VOICE, handle_file))

    # هندلر خطاها
    application.add_error_handler(error_handler)

    # شروع ربات
    application.run_polling()

if __name__ == '__main__':
    main()
