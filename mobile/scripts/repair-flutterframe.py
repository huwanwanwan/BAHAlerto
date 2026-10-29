"""Work around FlutterFrame 2.0.0 hiding a healthy app on DDS warnings.
Back up the extension before applying this local, version-specific patch.
Run again after an extension reinstall only if the same issue returns.
"""
from pathlib import Path
import os
root = Path(os.environ["USERPROFILE"]) / ".vscode/extensions/yashpatel-2611.flutterframe-2.0.0/out"
file = root / "extension.js"
text = file.read_text(encoding="utf-8")
marker = "// BAHAlerto: keep a running preview visible on known debug transport warnings."
if marker in text:
    print("FlutterFrame debug-warning fix already installed.")
    # Continue to apply the independent preview-server fix.
    pass
old = """        processManager.on('error', (err) => {
            statusBar?.setError();"""
new = """        processManager.on('error', (err) => {
            // BAHAlerto: keep a running preview visible on known debug transport warnings.
            const debugTransportWarning = /Utilities: Error in unawaited Future:Error: Bad state: Cannot add event after closing|Failed to create WebSocket debug connection|Hot restart requested before application started/.test(String(err));
            if (processManager?.isRunning && debugTransportWarning) {
                statusBar?.setRunning(currentDevice.name);
                return;
            }
            statusBar?.setError();"""
if marker not in text and text.count(old) != 1:
    raise SystemExit("Unexpected extension version/content; no files changed.")
backup = file.with_suffix(".js.bahalerto-backup")
if not backup.exists():
    backup.write_bytes(file.read_bytes())
file.write_text(text.replace(old, new, 1), encoding="utf-8")
print("Patched FlutterFrame recoverable debugger warning handler; original backup retained.")

# FlutterFrame is an embedded preview, not a DDS debugger client.
process_file = root / "flutterProcess.js"
process_text = process_file.read_text(encoding="utf-8")
old_args = "'run', '-d', 'web-server',"
new_args = "'run', '-d', 'web-server', '--no-dds',"
if new_args in process_text:
    print("FlutterFrame no-DDS preview fix already installed.")
elif process_text.count(old_args) == 1:
    process_backup = process_file.with_suffix(".js.bahalerto-backup")
    if not process_backup.exists():
        process_backup.write_bytes(process_file.read_bytes())
    process_file.write_text(process_text.replace(old_args, new_args, 1), encoding="utf-8")
    print("FlutterFrame now starts the preview with --no-dds; backup retained.")
else:
    raise SystemExit("Unexpected FlutterFrame launch arguments; no process file changed.")
