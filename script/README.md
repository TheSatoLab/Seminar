# 次期流行株ドライ解析テストデータ（講義に使用しない）

### ⚫︎目的　　
1. Nextstrainから新型コロナウイルスに実際感染した人のメタデータ（どこで、いつ、どのような変異株の・・・etc）をダウンロードし、
講義のテスト解析用にフィルタリングする
2. 多項ロジスティックモデルを用いて新型コロナウイルスの変異株の実効再生産数（Re）を推定し、Reの高い次期流行株を検出する

### ⚫︎このGitHub「script」フォルダに含まれるデータ
1. filtered_metadata.R
- 講義用のメタデータ作成に使用したRスクリプト　（=目的1）

- 今回のフィルタリング内容は下記の通り：
  - 2023年7月1日から2023年11月30日のデータ
  - 採取年月日が判明していないデータは省く
  - pango_lineageが不明なデータは省く
  - dataの箇所をas.Date()関数を使って日付型に変更
  - 国名を整理して、興味のある国（今回はUSA）のデータのみを抽出

2. transmissibility.R
- 解析に使用するR言語で書かれたスクリプト（=目的2）

3. country_info.txt
- 1.のスクリプトに使用する国名リスト

### 1. 手順（1. filtered_metadata.R）

Step 1 Nextstrainからメタデータをダウンロード
- [Nextstrain](https://nextstrain.org/ncov/open/global/6m?lang=ja)から　「All sequences and metadata」の「metadata.tsv.zst」をダウンロード。

Step 2 ダウンロードしたデータを解凍
- 解凍コマンドは下記の通り
```bash
zstd -d metadata.tsv.zst
```
Step 3 必要があれば、R をPCにインストール
- Rのサイト、[CRAN（Comprehensive R Archive Network）](https://cran.r-project.org/)を開き、PCのOS、バージョンに合ったインストーラをダウンロードし、インストール

Step 4 必要があれば、R studio をPCにインストール
- R Studioのサイト、[Posit社のサイト](https://posit.co/download/rstudio-desktop/)を開き、PCのOS、バージョンに合ったインストーラをダウンロードし、インストール

Step 5 必要なパッケージをインストール
- Rのコンソール上で下記コマンドを入力してパッケージをインストール

```R
install.packages("tidyverse")
install.packages("data.table")
```
Step 6 スクリプト内を適宜変更する
- ディレクトリ
- 取り出したい日付・期間
- 興味のある国、他

Step 7 Rスクリプトを実行する
- R studio でRスクリプトを開き、「Run」をクリックして実行、または、ターミナル上で下記コマンドで実行
```bash
Rscript /Your_dir/filtered_metadata.R
```
> [!NOTE]
> このスクリプトを動かすには大きなメモリを確保する必要がある  
> また、GoogleColab上での動作も困難かと思われる

### 2. 手順（2. transmissibility.R）

Step 1　必要なパッケージをインストール
- Rのコンソール上で下記コマンドを入力してパッケージをインストール
```R
install.packages("tidyverse")
install.packages("data.table")
install.packages("rbin")
install.packages("patchwork")
install.packages("RColorBrewer")
```
- cmdstanrのパッケージインストール方法については下記の通り
```R
install.packages("cmdstanr", repos = c('https://stan-dev.r-universe.dev', getOption("repos")))
```
参考：[CmdStanR](https://mc-stan.org/cmdstanr/)

Step 2 CmdStanをインストール
- cmdstan（Stanを実装するソフトウェア）をインストール
- Rのコンソール上で下記コマンドを入力してパッケージをインストール
```R
check_cmdstan_toolchain()
install_cmdstan(cores = 2)
```
参考：[Getting started with CmdStanR](https://mc-stan.org/cmdstanr/articles/cmdstanr.html)

Step 3　スクリプト内を適宜変更する
- ディレクトリ
- input、outputファイル
- 解析のコア数、基準となる変数、インプットの解析期間、最小配列数などを設定

Step 4 Rスクリプトを実行する
- R studio でRスクリプトを開き、「Run」をクリックして実行、または、ターミナル上で下記コマンドで実行
```bash
Rscript /Your_dir/transmissibility.R
```

> [!NOTE]
> このフォルダの全スクリプト類については講義では使用しない  
> 講義に利用するインプットデータは2023年12月18日にダウンロードし、フィルタリングしたものであるため、現在Nextstrainに登録されているメタデータを同じように解析しても全く同じ結果が出ない可能性があることをご留意いただきたい
