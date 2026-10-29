"""Copy only public Supabase client configuration from admin to mobile."""
import base64
import json
from pathlib import Path
root = Path(__file__).resolve().parents[2]
values = {}
for line in (root / "admin/.env.local").read_text(encoding="utf-8-sig").splitlines():
    if "=" in line and not line.lstrip().startswith("#"):
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip("\"'")
url = values["NEXT_PUBLIC_SUPABASE_URL"]
key = values["NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY"]
if not url.startswith("https://"):
    raise ValueError("Expected the shared HTTPS Supabase project URL")
if key.startswith("eyJ"):
    payload = key.split(".")[1]
    role = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))["role"]
    if role != "anon":
        raise ValueError("Only an anonymous public key may be copied to mobile")
elif not key.startswith("sb_publishable_"):
    raise ValueError("Expected a publishable client key")
(root / "mobile/assets/backend.local.json").write_text(json.dumps({
    "SUPABASE_URL": url, "SUPABASE_PUBLISHABLE_KEY": key,
}, indent=2) + "\n", encoding="utf-8")
print("Configured mobile with the same public Supabase project as admin. No server secrets copied.")
