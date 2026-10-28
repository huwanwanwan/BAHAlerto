from pathlib import Path
root = Path(__file__).resolve().parents[1]
parts = []
for migration in sorted((root / "supabase/migrations").glob("*.sql")):
    body = migration.read_text(encoding="utf-8")
    body = "\n".join(line for line in body.splitlines() if line.strip().lower() not in ("begin;", "commit;"))
    parts.append(f"-- Migration: {migration.name}\n{body}")
(root / "schema.sql").write_text("-- NEW DATABASE SETUP ONLY. Fails safely if schema conflicts exist.\n-- Generated from backend/supabase/migrations; do not edit this bundle manually.\nbegin;\n" + "\n\n".join(parts) + "\ncommit;\n", encoding="utf-8")
print("Built backend/schema.sql from versioned migrations.")
