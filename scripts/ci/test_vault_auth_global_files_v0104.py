#!/usr/bin/env python3
"""Static guards for v0.10.4: per-file auth, thumbnails, folders, global files."""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "SolidSecViewer"

vault = (APP / "PrivateVaultView.swift").read_text(encoding="utf-8")
session = (APP / "PrivateVaultSession.swift").read_text(encoding="utf-8")
bio = (APP / "NikaidoBiometricUnlock.swift").read_text(encoding="utf-8")
store = (APP / "SecurityScopedFolderStore.swift").read_text(encoding="utf-8")
models = (APP / "ExplorerModels.swift").read_text(encoding="utf-8")
explorer = (APP / "ExplorerView.swift").read_text(encoding="utf-8")
global_files = (APP / "ExplorerGlobalFiles.swift").read_text(encoding="utf-8")
pbx = (ROOT / "SolidSecViewer.xcodeproj" / "project.pbxproj").read_text(encoding="utf-8")

checks = {
    "file auth helper": "enum NikaidoFileAuth" in bio and "evaluatePolicy" in bio,
    "password verification (constant time)": "func verifyPassword" in session and "constantTimeEquals" in session,
    "protected open gate": "func protectedOpen" in vault and vault.count("protectedOpen(") >= 6,
    "cancel never opens": "case .cancelled:" in vault,
    "thumbnails hidden until auth": "revealed: thumbnailsRevealed" in vault and "guard revealed else" in vault,
    "vault thumbnail fixed container": "Color.clear" in vault and ".aspectRatio(1.25, contentMode: .fit)" in vault,
    "explorer thumbnail fixed container": "Color.clear" in explorer and "thumbnailContent" in explorer,
    "folder source labels": "enum ExplorerStorageSource" in models and "ExplorerUnavailableLocation" in models,
    "stale folder handling": "retryUnavailable" in store and "removeUnavailable" in store,
    "duplicate folder identity": "fileResourceIdentifierKey" in store and "isSameFolder" in store,
    "global files scanner": "enum ExplorerGlobalScanner" in global_files and "nextObject()" in global_files,
    "global files filters": "case images" in global_files and "case videos" in global_files and "case text" in global_files,
    "global files wired": "ExplorerGlobalFilesView" in explorer and "showGlobalFiles" in explorer,
    "global files registered": "ExplorerGlobalFiles.swift" in pbx and "NikaidoExtras.swift" in pbx,
    "vault is not indexed": "PrivateVault" not in global_files,
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("OK   " if ok else "FAIL ") + name)

if failed:
    print("VAULT AUTH / GLOBAL FILES GUARD: FAIL")
    sys.exit(1)

print("VAULT AUTH / GLOBAL FILES GUARD: OK")
