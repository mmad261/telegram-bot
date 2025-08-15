
# R2 Integration Notes (Quick)
## 1) Environment
Add these to your .env (or host env):
- R2_ACCOUNT_ID=<your-account-id>
- R2_ACCESS_KEY_ID=<your-access-key>
- R2_SECRET_ACCESS_KEY=<your-secret>
- R2_BUCKET=<your-bucket>
- S3_ENDPOINT=https://<account-id>.r2.cloudflarestorage.com

`pip install -r requirements-r2.txt`

## 2) Upload to R2 instead of local file
When you receive a Telegram file and resolve `file.file_path` to a URL (e.g., via Bot API or your local bot-api server), replace your "save to disk" step with:

```python
from storage_backend_r2 import put_stream, iter_telegram_file

tg_url = f"{TG_BOTAPI_BASE}/file/bot{BOT_TOKEN}/{file.file_path}"
object_key = f"{doc.file_unique_id}/{safe_name}"
put_stream(iter_telegram_file(tg_url, chunk_mb=1), object_key, content_type=doc.mime_type, part_size_mb=32)
# store object_key in DB instead of local file path
```

## 3) Redirect /d/<file_id> to a pre-signed URL
After validating your HMAC/expiry like before, if the record has `object_key`, do:

```python
from storage_backend_r2 import make_presigned_get

ttl_left = max(60, int(exp_ts - time.time()))
url = make_presigned_get(object_key, filename=safe_name, expires_seconds=ttl_left if ttl_left < 3600*7*24 else 3600)  # cap to 1h if you prefer
return redirect(url, code=302)
```

## 4) Deletion after 4h
Where you previously removed local files, call:

```python
from storage_backend_r2 import delete as r2_delete
r2_delete(object_key)
```

Keep your existing JobQueue/cron that runs exactly at +4h to enforce the TTL. Lifecycle in R2 works in days, not hours.

## 5) Large files (up to 4 GiB)
- Use local Telegram Bot API server or MTProto to bypass the 20MB download cap of the cloud Bot API endpoint.
- Multipart part size 32 MiB keeps part count ~128 for 4 GiB (within S3 limits).
- Pre-signed links are resumable (Range).

## 6) Safety tips
- Compute `expires_seconds` for pre-signed URLs from the remaining HMAC TTL to minimize link lifetime.
- Consider keeping both old (local) and new (R2) paths during migration. If `object_key` is empty, fall back to local file serving.
