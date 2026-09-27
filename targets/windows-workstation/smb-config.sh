#!/bin/bash

echo "[SMB] Configuring Samba..."

# Ensure Samba is running
service smbd restart 2>/dev/null || true
service nmbd restart 2>/dev/null || true

echo "[SMB] SMB configuration complete"
