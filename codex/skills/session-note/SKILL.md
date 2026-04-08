---
name: session-note
description: "互換用エイリアス。TIL への記録は til-send を使い、実処理は TIL 側の til-update 仕様に従う"
---

# /session-note

このコマンドは後方互換のために残しているエイリアス。
新規運用では `/til-send` を優先すること。

## 振る舞い

- `/session-note` は `/til-send` と同じ意味で扱う
- 実処理の正本は TIL リポジトリ側の `til-update`
- 詳細手順は TIL リポジトリの `AGENTS.md` と `.ai/til-update.md` を参照する
