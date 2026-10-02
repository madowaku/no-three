# NO THREE

点を置く。どの一直線上にも、3個置かない。

Godot **4.7 stable / GDScript / 2D** のプレイ可能なMVPです。001〜016は点を追加し、017〜020は点を1個だけ移動します。タイトル、5章のステージ選択、TRACE、Undo、Reset、クリア演出、ローカル保存、4種類の効果音を実装しています。

## 起動

Godot 4.7で `project.godot` をインポートして **F6ではなくF5** で実行してください。CLIからも起動できます。

```powershell
godot --path .
```

開発用に全ステージを選択する場合:

```powershell
godot --path . -- --unlock-all
```

通常は001のみ開放し、クリアごとに次を開放します。進行とTRACE設定は `user://progress.cfg` に保存します。テストは別の `evidence/` 内の保存ファイルを使います。

## 操作

- 空いている点をクリック／タップして配置。
- MOVE ONEでは石を選び、空いている点を選んで移動。同じ石を再選択すると解除。
- 禁止配置は確定せず、原因の線と仮点を一瞬表示。
- TRACEで点ペアが作る直線を表示。Resetと次ステージでも設定を維持。
- Undoはクリア後にも使用可能。Reset／Replayは初期配置と空の履歴へ戻る。
- Escでステージ選択、さらにEscでタイトルへ。

720×1280を基準に伸縮し、横長ウィンドウでは盤面を中央配置します。360×800の表示とマウス入力、合成タッチ入力も検証済みです。

## 検証

Pythonは標準ライブラリだけを使います。

```powershell
python tools/validate_stages.py
python -m unittest discover -s tests -p 'test_*.py'
godot --headless --path . --import
godot --headless --debug --ignore-error-breaks --path . --script res://tests/check_project.gd
godot --headless --debug --ignore-error-breaks --path . --script res://tests/run_tests.gd
```

Windowsではまとめて実行できます。`-Godot` に実行ファイルを指定してください。

```powershell
./tools/run_checks.ps1 -Godot 'C:/path/to/Godot_v4.7-stable_win64_console.exe'
```

Godotスキルのscenario runnerを使う描画／UIチェックを加える場合は `-Visual -GodotSkillRoot 'C:/path/to/godot-skill'` を追加します。ログ・画像・UI配置レポートは `evidence/` に出力します。

全20問の解を独立Python solverで列挙し、PLACEの一意解とMOVE ONEの一意修正を確認します。Godot側でも実際のBoardModelと画面コントローラーを通して全20問、拒否・Undo・Reset・TRACE・進行保存をテストします。

## データと設計

- `data/stages.json`: 実行時の問題データ。正解は含みません。
- `tests/fixtures/stage_solutions.json`: 開発用の解・期待移動。ゲームは読みません。
- `tools/build_stage_data.py`: 元仕様のPLACE配置を保存し、不足していたMOVE ONE配置を再現可能に生成。
- `themes/palette.tres`: 盤面・線の色。`themes/no_three_theme.tres`: UIテーマ。
- `tools/generate_audio.py`: オリジナル効果音を生成。
- `docs/NO_THREE_IMPLEMENTATION_SPRINT_v0.1.md`: 元の実装仕様。
- `docs/VALIDATION.md`: 検証結果と人によるプレイテスト項目。

017／018は4×4、019は5×5、020は6×6としました。元仕様にない018〜020の名前は ONE SHIFT／CROSSING／INVISIBLE KNOT です。指定された正解移動はすべて維持しています。

配布用エクスポートでは `tests/*, tools/*, docs/*, evidence/*` を除外してください。Windows実行ファイルとWeb向けのパッケージ作成はこのMVPには含めていません。
