# 次期流行株ドライ解析テストデータ（セミナー用）
⚫︎このGitHubに含まれるデータ
1. multinomial_independent.ver2.stan
   Rとは別に使用するStanのスクリプト
2. metadata_filtered_USA_230701_231130.txt.zip
   メインのメタデータファイルであるインプット

https://colab.research.google.com/drive/1-4ZP70zQTcQBAJeahSJ7V1GS7akta5BA?usp=sharing

⚫︎手順

Step 1 必要なパッケージをインストール
- デフォルトで備わっているパッケージ以外はその都度インストールをしないといけない
- 今回の場合は、rbin, cmdstanr, patchwork

Step 2 インストールしたパッケージを読み込む
- パッケージは読み込まないと使えないので起動する

Step 3 cmdstanをインストールする（少し時間がかかる）

Step 4 GitHubからファイルを取ってくる
- GitHubのリンクを使って、Google Colabと連携させる
- ただしメタデータファイルは.zipに圧縮されているのでStep 5で解凍する

Step 5 解析に使う変数とパラメータを設定する
- cmdstanのパス名を設定→Step 3で表示されたcmdstanのインストール先合わせて変更
- 改めてStanファイルの変数名を設定＆メタデータを解凍し変数名を設定
- アウトプットする際の名前を設定（GoogleColab上で結果を可視化する場合はいらない）
- 他、解析のコア数、基準となる変数、インプットの解析期間、最小配列数などを設定

Step 6 インプットデータの加工
- メタデータをそのままでは使えないのでフィルタリングなど加工をする

Step 7 実効再生産数の解析（かなり時間がかかる）

Step 8 ビジュアライズ①実効再生産数

Step 9 ビジュアライズ②流行動態

Step 10 解析結果をpdfなどにアウトプットする（ここもGoogleColab上で結果を可視化する場合はいらない）
