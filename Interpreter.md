---
title: prohell.rb
---

# インタプリタの解説

この文書ではprohell暫定処理系`prohell.rb`インタプリタの実装を解説します.

# なぜrubyなのか

この処理系は学校の課題を名目として作られました.
学校側がrubyを指定したためrubyです.
haskellやocamlを使いたいと駄々をこねましたがダメでした.

# なぜ生で構文解析をしているのか,モジュール化されてないのか,コードが汚いのか

そういう課題だからです.
純粋な趣味ならparsecを使います.

学習用ということで,初めから書き捨てを前提としているからです.

# 環境

~~~
% ruby -v
ruby 2.3.3p222 (2016-11-21 revision 56859) [x86_64-linux]
~~~

# 構文解析

prohellの構文は極めてシンプルになっています.
これはなるべく美しく簡潔な言語を考えたらこうなっただけで,けして構文解析の手を抜くためではありません.
本当です.

`Prohell`クラスは起動したら同じディレクトリの`prelude.phl`を読み込み,`load`を開始します.
それにより,`@rule`に述語を追加していきます.

`@rule`はデフォルト値を新しく生成された配列にしているため,`load`は既に同じ名前の述語があるかどうか気にせず配列に追加する要領で述語を追加できます.

`statement`には述語本体の構文解析が記述されています.
まず空行をスキップし,`head`で頭部を解析し,`=`があれば体部を抽出します.
体部は`head`を`,`で区切ったものなので,解析は簡単です.

`head`は名前とって引数解析.

`name`は記号以外みんな使えます.

`term`で引数の解析.
これで引数の記号などを解析します.

`token`は空白をスキップしてくれる便利メソッドです.

# 実行

`repl`メソッドでプロンプトが実行されます.

prohellの質問はprologと同じく,頭部だけの述語と同じなので,prohell本体のパーサーが質問にも使えます.

`unify`でユニファイを行います.
ユニファイの意味については[AZ-Prolog ユーザーズマニュアル](http://az-prolog.com/manual/manuals/manual_program.html)が参考になるでしょう.

本来haskellやmlで実装するべきのような物を頑張ってrubyで書いたようなものになっています.
なのであまり綺麗なソースコードではありません.
`match`で変形項を取ってきて変形された腹部があれば再帰で腹部の評価を行い全ての結果を既存の変数にマージした組み合わせを返します.

`set`で項を変形して変数に値をぶち込みます.

`select_var`は自由変数を抽出するためのメソッドです.
これを使って自由変数の返り値を検出します.

`match`で項のマッチングと束縛されるべし変数を計算します.
`builtin`はここで割りこまれて強引に処理されます.
