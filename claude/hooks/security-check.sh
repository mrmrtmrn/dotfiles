#!/bin/bash
#
# security-check.sh - Claude Code PreToolUse hook
#
# git commit / git push 実行前にステージング済みファイルの
# 機密情報をチェックし、検出時はブロックする。

set -euo pipefail

# stdin から JSON を読み取る
INPUT=$(cat)

# tool_name が Bash でなければスキップ
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

# コマンドを取得
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# git commit または git push コマンドかどうか判定
IS_COMMIT=false
IS_PUSH=false

if echo "$COMMAND" | grep -qE '(^|\s|&&|\|\||;)git\s+commit(\s|$)'; then
  IS_COMMIT=true
elif echo "$COMMAND" | grep -qE '(^|\s|&&|\|\||;)git\s+push(\s|$)'; then
  IS_PUSH=true
fi

if ! $IS_COMMIT && ! $IS_PUSH; then
  exit 0
fi

# リポジトリのルートを特定（コマンドの working directory を推定）
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "$REPO_ROOT" ]]; then
  exit 0
fi

# チェック対象ファイルの一覧を取得
FILES=""
if $IS_COMMIT; then
  FILES=$(cd "$REPO_ROOT" && git diff --cached --name-only 2>/dev/null || true)
elif $IS_PUSH; then
  # upstream が設定されている場合は差分を取得
  FILES=$(cd "$REPO_ROOT" && git diff --name-only '@{u}...HEAD' 2>/dev/null || true)
  if [[ -z "$FILES" ]]; then
    # upstream 未設定の場合はステージング済みファイルをチェック
    FILES=$(cd "$REPO_ROOT" && git diff --cached --name-only 2>/dev/null || true)
  fi
fi

if [[ -z "$FILES" ]]; then
  exit 0
fi

ISSUES=()

# --- 1. 危険なファイル名の検出 ---
DANGEROUS_PATTERNS=(
  '\.env$'
  '\.env\.'
  '\.pem$'
  '\.key$'
  'id_rsa'
  'id_ed25519'
  'id_ecdsa'
  'id_dsa'
  'credentials\.json$'
  '\.p12$'
  '\.pfx$'
  '\.jks$'
  '\.keystore$'
  '\.secret$'
  '\.secrets$'
)

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if echo "$file" | grep -qiE "$pattern"; then
      ISSUES+=("  [FILENAME] $file (matches: $pattern)")
      break
    fi
  done
done <<< "$FILES"

# --- 2. ファイル内容の検出 ---
# 各ファイルのステージング済み or コミット済みの内容をスキャン

CONTENT_PATTERNS=(
  # AWS Access Key
  'AKIA[0-9A-Z]{16}'
  # OpenAI API Key
  'sk-[a-zA-Z0-9]{20,}'
  # GitHub Token
  'gh[ps]_[a-zA-Z0-9]{36,}'
  'gho_[a-zA-Z0-9]{36,}'
  # Slack Token
  'xoxb-[0-9]+'
  'xoxp-[0-9]+'
  'xoxa-[0-9]+'
  # Private Key
  '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'
  # Connection strings with credentials
  '://[^:]+:[^@]+@[^/]+'
)

ASSIGNMENT_PATTERNS=(
  # password/secret/key assignments (key=value, key: value 形式)
  '(password|passwd|secret|api_key|apikey|api_secret|access_token|auth_token|private_key)\s*[=:]\s*["\x27]?[^\s"'\'']{8,}'
)

while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  # ファイルが存在し、バイナリでないことを確認
  FULL_PATH="$REPO_ROOT/$file"
  if [[ ! -f "$FULL_PATH" ]]; then
    continue
  fi

  # バイナリファイルはスキップ
  if file "$FULL_PATH" | grep -q 'binary\|executable\|archive\|image\|font'; then
    continue
  fi

  # ステージング済みの内容を取得
  if $IS_COMMIT; then
    CONTENT=$(cd "$REPO_ROOT" && git show ":$file" 2>/dev/null || true)
  else
    CONTENT=$(cat "$FULL_PATH" 2>/dev/null || true)
  fi

  [[ -z "$CONTENT" ]] && continue

  for pattern in "${CONTENT_PATTERNS[@]}"; do
    if echo "$CONTENT" | grep -qE "$pattern"; then
      MATCH=$(echo "$CONTENT" | grep -oE "$pattern" | head -1 | cut -c1-40)
      ISSUES+=("  [CONTENT]  $file (detected: ${MATCH}...)")
      break
    fi
  done

  for pattern in "${ASSIGNMENT_PATTERNS[@]}"; do
    if echo "$CONTENT" | grep -qiE "$pattern"; then
      MATCH=$(echo "$CONTENT" | grep -oiE "$pattern" | head -1 | cut -c1-40)
      ISSUES+=("  [SECRET]   $file (detected: ${MATCH}...)")
      break
    fi
  done

done <<< "$FILES"

# --- 結果判定 ---
if [[ ${#ISSUES[@]} -gt 0 ]]; then
  echo "" >&2
  echo "╔══════════════════════════════════════════════════════════════╗" >&2
  echo "║  WARNING: SECURITY CHECK FAILED - Sensitive data detected!   ║" >&2
  echo "╚══════════════════════════════════════════════════════════════╝" >&2
  echo "" >&2
  echo "The following issues were found:" >&2
  echo "" >&2
  for issue in "${ISSUES[@]}"; do
    echo "$issue" >&2
  done
  echo "" >&2
  echo "Action: Remove sensitive files/data before committing." >&2
  echo "If this is intentional, add the file to .gitignore or" >&2
  echo "use 'git update-index --assume-unchanged <file>'." >&2
  echo "" >&2
  exit 2
fi

exit 0
