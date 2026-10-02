# NO THREE Implementation Sprint v0.1

## 0. Goal

Godot 4.7 / Windows 11 環境で、論理パズル **NO THREE** のプレイ可能なMVPを実装する。

ゲームのコアルールは1つ。

> 点を盤面に配置する。<br>
> どの一直線上にも3個以上の点を置いてはいけない。

Stage 001〜016では指定数まで点を追加して完成させる。

Stage 017〜020では、すでに置かれている点を**1個だけ移動**して、すべての違反直線を消す。

最終成果物は、Stage 001〜020をタイトル画面から連続してプレイでき、Undo・Reset・TRACE表示・クリア判定が機能するGodotプロジェクト。

---

# 1. Product Direction

## Core experience

NO THREEで最も重要なのは、

**「見えていなかった直線が突然見える」**

という体験。

盤面は基本的に静かでミニマルにする。

点を置こうとしたとき、またはTRACEを使ったときだけ、関連する直線を表示する。

数学教材っぽくしすぎない。

プレイヤーには序盤で「傾き」「座標」「外積」などの数学用語を見せない。

---

# 2. Target Platform

Engine:

- Godot 4.7
- GDScript
- 2D

Initial target:

- Windows
- Web exportを将来的に想定

Reference viewport:

- 720 × 1280
- 縦画面基準
- PCでは中央配置

マウスとタッチ双方に対応する。

---

# 3. Main Scene Flow

```text
Boot
 ↓
Title
 ↓
Stage Select
 ↓
Puzzle
 ↓
Clear
 ↓
Next Stage
```

必要Scene:

```text
scenes/
  main.tscn
  title_screen.tscn
  stage_select.tscn
  puzzle_screen.tscn
  clear_overlay.tscn
```

---

# 4. Puzzle Screen Layout

縦画面。

```text
┌────────────────────┐
│ NO THREE       008 │
│ TWO PER LINE       │
│                    │
│      ●      ●      │
│                    │
│   ・ ・ ・ ・       │
│   ・ ・ ・ ・       │
│   ・ ・ ・ ・       │
│   ・ ・ ・ ・       │
│                    │
│       2 / 8        │
│                    │
│ TRACE              │
│ Undo   Reset       │
└────────────────────┘
```

上部:

- Stage番号
- Stage名

中央:

- 正方形盤面
- Grid intersection上に点を配置

下部:

- Current / Target
- TRACE
- Undo
- Reset

クリア時:

```text
8 / 8

COMPLETE
```

盤面を少し縮小。

合法配置によって生成される直線群を約0.5秒だけ表示。

その後:

```text
NEXT
REPLAY
STAGE SELECT
```

---

# 5. Board Representation

盤面座標は整数。

左上を:

```text
(1,1)
```

右下を:

```text
(n,n)
```

とする。

内部的にはVector2iを使用。

例:

```gdscript
Vector2i(1, 1)
Vector2i(4, 3)
```

BoardModel:

```gdscript
class_name BoardModel

var size: int
var stones: Array[Vector2i]
```

---

# 6. Core Rule

3点 A, B, C が一直線上なら違反。

浮動小数点計算は禁止。

整数の外積で判定する。

```gdscript
func are_collinear(a: Vector2i, b: Vector2i, c: Vector2i) -> bool:
    return (
        (b.x - a.x) * (c.y - a.y)
        ==
        (b.y - a.y) * (c.x - a.x)
    )
```

新しい点 `p` を配置できる条件:

```text
既存点から任意の2点 a,b を選ぶ。

a,b,p が一直線なら配置不可。
```

計算量は小さいため、MVPでは単純全探索でよい。

最大盤面はSprint v0.1では6×6。

---

# 7. Placement Feedback

合法位置:

点を置く。

軽いscale animation。

```text
0.85
→
1.08
→
1.0
```

約150ms。

違法位置:

点を確定しない。

原因になった2点との直線を表示。

```text
●────────●────────×
```

その後、仮点を軽く弾き返す。

約250〜400msで直線を消す。

表示メッセージは不要。

必要ならごく小さく:

```text
NO THREE
```

だけ表示可能。

---

# 8. Line Visualization

LineRenderer的なNode2Dを用意する。

```text
LineOverlay
```

盤面外まで伸ばす必要はない。

原因となる最遠端まで、または盤面端まで延長する。

重要なのは、

**3点が一直線になっていることが視覚的に一瞬で分かること。**

TRACEと違法配置時で同じLineOverlayシステムを共有する。

---

# 9. TRACE Mode

TRACEボタンを押している間、またはtoggle ON時、

現在の配置によって禁止されている直線を表示する。

初期仕様:

```text
TRACE OFF
TRACE ON
```

toggle式。

TRACE ON時:

既存のすべての点ペアについて直線を生成。

ただし完全に同じ直線は重複表示しない。

---

# 10. Canonical Line Key

同じ直線を重複描画しないため、直線を整数形式で正規化する。

一般形:

```text
Ax + By + C = 0
```

2点:

```text
A = y2 - y1
B = x1 - x2
C = -(A*x1 + B*y1)
```

A,B,Cを最大公約数で割る。

さらに符号を正規化。

例:

```text
A < 0
```

なら全体に-1を掛ける。

A == 0の場合はBを正にする。

結果:

```text
Vector3i equivalent
```

またはString key:

```text
"A:B:C"
```

を使用。

---

# 11. Stage Types

Sprint v0.1では2種類。

## PLACE

点を追加する。

クリア条件:

```text
stone_count == target
AND
no violations
```

Stage 001〜016。

---

## MOVE_ONE

初期点数はtargetと同じ。

新規追加不可。

既存点をタップすると選択状態になる。

空きマスを選ぶと移動。

1回移動した状態で盤面が合法ならクリア。

Stage 017〜020。

Undoで移動前へ戻れる。

---

# 12. Stage Data

JSONまたはResource。

推奨:

```text
data/stages.json
```

schema:

```json
{
  "id": 1,
  "name": "LAST ONE",
  "size": 3,
  "mode": "place",
  "target": 6,
  "initial": [
    [1,1],
    [2,1],
    [1,2],
    [3,2],
    [2,3]
  ]
}
```

MOVE_ONE:

```json
{
  "id": 17,
  "name": "INTERSECTION",
  "size": 4,
  "mode": "move_one",
  "target": 8,
  "initial": []
}
```

ゲーム本体に正解座標は持たせない。

クリア判定はルールのみで行う。

---

# 13. Stage List

## Chapter 1: THIRD

### 001 LAST ONE

```text
size: 3
target: 6

initial:
(1,1)
(2,1)
(1,2)
(3,2)
(2,3)
```

### 002 TWO LEFT

```text
initial:
(2,1)
(3,1)
(1,2)
(3,2)
```

### 003 THIRD

```text
initial:
(1,1)
(2,1)
(1,2)
```

### 004 WHOLE BOARD

```text
initial:
(3,1)
```

---

# 14. Chapter 2: TWO PER LINE

### 005 EIGHT

```text
size: 4
target: 8

initial:
(1,1)
(2,1)
(3,2)
(4,2)
(1,3)
(2,3)
```

### 006 ROWS

```text
initial:
(1,1)
(3,1)
(1,2)
(3,2)
(2,3)
```

### 007 COLUMNS

```text
initial:
(1,1)
(3,1)
(2,2)
(4,2)
```

### 008 TWO PER LINE

```text
initial:
(1,1)
(4,1)
```

---

# 15. Chapter 3: NOT DIAGONAL

## 009 HALF SLOPE

```text
size: 5
target: 10

initial:
(1,1)
(2,1)
(1,2)
(4,2)
(4,3)
(5,3)
(2,4)
```

## 010 STEEP

```text
initial:
(1,1)
(2,1)
(2,2)
(4,2)
(1,3)
(3,5)
```

## 011 REVERSE

```text
initial:
(1,1)
(3,1)
(1,2)
(4,3)
(3,5)
```

## 012 CENTER TRAP

```text
initial:
(1,1)
(3,1)
(5,2)
(1,4)
```

---

# 16. Chapter 4: INVISIBLE

## 013 GHOST GRID

```text
size: 5
target: 10

initial:
(1,1)
(2,1)
(2,2)
```

## 014 SHADOW LINES

```text
size: 6
target: 12

initial:
(1,1)
(3,3)
(1,4)
(3,4)
```

## 015 THREE SEEDS

```text
initial:
(3,2)
(5,2)
(5,4)
```

## 016 TWO POINTS

```text
initial:
(1,1)
(6,6)
```

---

# 17. Chapter 5: MOVE ONE

Stage 017〜020では、既存の検証済み初期配置をデータ化する。

正解操作は以下。

```text
017
(1,2) → (4,4)

018
(3,1) → (2,4)

019
(3,3) → (2,4)

020
(3,3) → (6,5)
```

IMPORTANT:

MOVE_ONEステージの初期配置は、実装前にsolver fixtureとして保存し、上記以外の合法1手修正が存在しないことを自動テストする。

---

# 18. Interaction

PLACE mode:

```text
empty cell tap
→ validity check
→ valid: place
→ invalid: reject + line flash
```

既存石をタップしても何もしない。

MOVE_ONE mode:

```text
stone tap
→ select

empty cell tap
→ preview

valid destination
→ move

illegal destination
→ line flash
```

選択中の石は少し拡大。

---

# 19. Undo

履歴はBoardStateのsnapshotでよい。

```gdscript
history: Array[Array[Vector2i]]
```

Placement / Move後に追加。

Undo:

```text
current state
↓
previous state
```

初期状態より前へは戻れない。

---

# 20. Reset

現在Stageのinitial状態へ戻す。

Undo履歴もクリア。

TRACE設定は維持する。

---

# 21. Stage Progress

ConfigFileまたはJSONでローカル保存。

保存項目:

```text
highest_unlocked_stage
completed_stages
trace_enabled
```

001のみ初期開放。

Stageクリアで次Stage開放。

開発ビルドでは全ステージ開放可能。

---

# 22. Stage Select

20Stageを5章で表示。

```text
THIRD
001 002 003 004

TWO PER LINE
005 006 007 008

NOT DIAGONAL
009 010 011 012

INVISIBLE
013 014 015 016

MOVE ONE
017 018 019 020
```

未開放:

```text
•
```

クリア済:

```text
✓
```

星評価・スコアは実装しない。

---

# 23. Tutorial Policy

長文チュートリアル禁止。

Stage 001開始時だけ:

```text
PLACE THE LAST DOT
```

Stage 017:

```text
MOVE ONE DOT
```

以上。

「各行2個」や「45°以外の直線」について説明文を出さない。

プレイヤー自身に発見させる。

---

# 24. Clear Animation

配置完成時:

1. input lock
2. board slightly zoom out
3. all unique pair-linesを生成
4. 約0.5秒表示
5. fade out
6. COMPLETE

ただし線が多すぎる場合:

「実際に2個以上の石を含むcanonical line」のみ描画。

クリア演出時間:

```text
1.0〜1.5秒
```

程度。

スキップ可能でもよい。

---

# 25. Visual Direction

非常にミニマル。

盤面:

```text
background
+
small grid points
+
solid dots
```

余計な装飾は付けない。

NO THREEという名前が画面デザインそのものになるようにする。

禁止線は通常非表示。

表示された瞬間だけ視覚的存在感を強くする。

色についてはテーマResourceで一括管理し、ゲームロジックへ直接書かない。

---

# 26. Audio

MVPでは最低3音。

```text
place
reject
clear
```

MOVE:

```text
pickup
```

を追加してもよい。

reject音は失敗感より、

```text
tick / snap
```

系。

不快なbuzzは避ける。

---

# 27. Solver / Validator

ゲーム本体とは別にPythonスクリプトを作る。

```text
tools/
  validate_stages.py
  enumerate_solutions.py
```

役割:

### validate_stages.py

全Stageについて:

- initial coordinates valid
- duplicatesなし
- 初期配置の状態確認
- target <= n²
- PLACE問題の完成解数
- MOVE_ONE問題の合法修正数

を検査。

期待:

```text
Stage 001 PASS solutions=1
...
Stage 016 PASS solutions=1

Stage 017 PASS moves=1
...
Stage 020 PASS moves=1
```

---

# 28. Automated Tests

最低限以下をテスト。

## Geometry

```text
horizontal collinear
vertical collinear
45-degree
slope 1/2
slope 2
negative slope
non-collinear
```

## Placement

```text
valid placement
horizontal violation
vertical violation
non-45° violation
```

## Canonical line

異なる2点組でも同一直線なら同じkeyになる。

## Stage

001〜016:

```text
solution_count == 1
```

017〜020:

```text
valid_move_count == 1
```

---

# 29. Suggested Project Structure

```text
no-three/
├─ project.godot
│
├─ scenes/
│  ├─ main.tscn
│  ├─ title_screen.tscn
│  ├─ stage_select.tscn
│  └─ puzzle_screen.tscn
│
├─ scripts/
│  ├─ game_manager.gd
│  ├─ puzzle_controller.gd
│  ├─ board_model.gd
│  ├─ board_view.gd
│  ├─ line_overlay.gd
│  ├─ stage_loader.gd
│  └─ save_manager.gd
│
├─ data/
│  └─ stages.json
│
├─ tools/
│  ├─ validate_stages.py
│  └─ enumerate_solutions.py
│
├─ tests/
│  ├─ test_geometry.gd
│  └─ test_board.gd
│
└─ docs/
   └─ NO_THREE_IMPLEMENTATION_SPRINT_v0.1.md
```

---

# 30. Implementation Tasks

## TASK-001 Core Geometry

Implement:

```text
are_collinear()
is_valid_position()
get_violation_lines()
canonical_line_key()
```

Acceptance:

斜め・非45°含めテスト成功。

---

## TASK-002 Board UI

3×3〜6×6盤面を動的生成。

クリック / タッチでマス選択可能。

Acceptance:

720×1280基準で全サイズが中央表示される。

---

## TASK-003 PLACE Gameplay

Stage data読込。

点配置。

違法配置拒否。

target到達時にクリア。

Acceptance:

001〜016プレイ可能。

---

## TASK-004 TRACE

現在盤面の点ペアが作る直線を重複なしで描画。

Acceptance:

TRACE ON/OFF可能。

通常プレイ操作を阻害しない。

---

## TASK-005 MOVE_ONE

石選択。

移動。

Undo。

クリア判定。

Acceptance:

017〜020プレイ可能。

---

## TASK-006 Progression

Stage Select。

Unlock。

保存。

Acceptance:

001→020まで順番に進行可能。

---

## TASK-007 Feedback / Animation

place

reject

line flash

clear

を実装。

Acceptance:

禁止された理由が文章なしでも理解できる。

---

## TASK-008 Solver Validation

Python validatorを実装。

20問を全検証。

Acceptance:

```text
PLACE stages:
solution_count == 1

MOVE_ONE stages:
valid_move_count == 1
```

---

# 31. Definition of Done

Sprint v0.1完了条件:

- Godot 4.7で警告なし起動
- Stage 001〜020をプレイ可能
- 001〜016が一意解
- 017〜020が一意1手修正
- 任意角度の3点一直線を正しく検出
- TRACE動作
- Undo動作
- Reset動作
- Stage Select動作
- Progress保存
- Windows操作確認
- 720×1280表示確認
- 360×800相当でもUI崩れなし
- validate_stages.py PASS
- 自動テストPASS

---

# 32. Explicit Non-Goals

v0.1では実装しない:

- Daily
- LAB自由探索
- 7×7以上
- Steam連携
- 実績
- オンラインランキング
- ヒントAI
- 点の色違い
- 特殊マス
- PAR
- タイムアタック
- スコア
- 星評価
- 数学解説ページ

まずは、

**点を置く → 見えなかった直線が現れる → 理解が深くなる**

という一本だけを完成させる。

---

# 33. Final UX Test

初見プレイヤーにStage 001〜012まで遊んでもらう。

観察対象:

1. 説明なしで配置方法を理解できるか
2. 禁止時に「なぜ置けないか」が理解できるか
3. Stage 005〜008で「各行2個」に自力で気づくか
4. Stage 009〜012で45°以外の直線に驚くか
5. TRACEなしでも考えようとするか
6. TRACEが答え表示ではなく補助として機能するか
7. Undo頻度
8. Reset頻度
9. Stage離脱地点
10. 「もう1問」が起こるか

特に重要なのは、

> Stage 009前後で盤面の見え方が変わったか。

ここをNO THREE v0.1のHuman Playtest Gateとする。