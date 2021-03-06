# FILE2PIGAIMG Ver.02
## はじめに
FILE2PIGAIMGは、プチコン4のTXT, GRPリソースからPIGATEST(制作者:まつたく氏, 公開キー:4KK4QS3Q4)用のテープイメージを生成する、プチコン4向けのツール群です。  
TXTリソースからはTXT2PIGAIMGで、GRPリソースからはGRP2PIGAIMGで生成できます。  
また、イメージファイルのヘッダ(格納ファイル本体の形式, ファイル名)を確認するツールとして、INFOPIGAIMGも付属しています。  
なお、テープイメージに格納されるデータ構造は独自のものとなります。デコードには付属PHPスクリプトのDEC_PIGAIMGを使います。  

## TXT2PIGAIMGの使い方
変数FNAME_TXTに入力ファイル名を、変数FNAME_OUTに出力ファイル名を記述し、プログラムを実行してください。  
オプションとして、以下の設定を行うことができます。  
- 変数FNAME_HEAD(イメージファイルのヘッダに格納するファイル名)
	- 空欄の場合は入力ファイル名を使用します。(デフォルト:空欄)
- 定数#MODE_COMP_TXT(簡易圧縮設定)
	- FALSEならUTF-16LEテキスト形式、TRUEならUTF-16LE簡易圧縮テキスト形式で格納します。(デフォルト:TRUE)

## GRP2PIGAIMGの使い方
変数FNAME_GRPに入力ファイル名を記述し、プログラムを実行してください。  
オプションとして、以下の設定を行うことができます。  
- 変数FNAME_OUT(出力ファイル名), 変数FNAME_HEAD(イメージファイルのヘッダに格納するファイル名)
	- 空欄の場合は入力ファイル名を改変して使用します。(デフォルト:空欄)
- 定数#MODE_COMP_GRP(簡易圧縮設定)
	- FALSEならBMP形式、TRUEなら簡易圧縮グラフィック形式でグラフィックを格納します。(デフォルト:TRUE)
- 定数#FORCE_RGB888(強制RGB888モード)
	- TRUEなら強制的にRGB888の色空間でグラフィックを格納します。(デフォルト:FALSE)
- 定数#AUTODETECT_RGB888(RGB888自動判定モード)
	- TRUEなら、透明度情報が不要であると判定された場合にRGB888の色空間でグラフィックを格納します。(デフォルト:TRUE)

定数#FORCE_RGB888, 定数#AUTODETECT_RGB888がどちらもFALSEである場合、常にARGBの色空間で格納されます。  

## INFOPIGAIMGの使い方
プログラムを実行するとファイル名入力ダイアログが開きますので、ヘッダ情報を表示したいテープイメージのファイル名を入力して下さい。  
テープイメージをロードして、ヘッダ情報を表示します。  

## Switchからのデータ転送方法
まずは、下のほうにある注意点をよくお読みください。  
生成したテープイメージをPIGATESTに読み込ませてPC-6001方式のFSK変調音声をSwitchから出力します。  
出力した音声をPCのライン入力などで録音し、それを[P6DatRec](http://morigon.jp/p6.html)などに読み込ませてデータを得ます。  
あとは、先程得たデータをDEC_PIGAIMG.BATにドラッグ＆ドロップすれば格納ファイル本体の形式などを判定して自動でデコードされます。  

## イメージファイルの構造
先頭4バイトは格納されているファイル本体の形式を示す情報です。  
(CTXT:UTF-16LE簡易圧縮テキスト, RTXT:UTF-16LEテキスト, CGRP:簡易圧縮グラフィック形式, RGRP:BMP形式)  
その後の12バイトは今のところ0x00固定です。(今後何か拡張する可能性はあります。)  
次にはファイル名の長さが1バイトで入り、その先から指定された長さ分のファイル名が入ります。  
さらに、ファイル名の直後からファイル本体が入ります。ファイル本体のサイズを示す情報は格納されていません。  

## UTF-16LE簡易圧縮テキストについて
コードポイント0x0000,0x0002～0x00FFについては、上位1バイトを取り除き下位1バイトのデータとして追記します。  
(例: コードポイント0x0032 "2" -> バイト列0x32)  
コードポイント0x0001,0x0100～については、先頭に0x01を付加して3バイトのデータとして追記します。  
(例: コードポイント0x306D "ね" -> バイト列0x01, 0x6D, 0x30)  
TXTリソースはASCII範囲内の文字の割合が多いと思われますので、これで転送量を抑えられると思います。  
逆に、ASCII範囲外の文字が多い場合には逆効果です。ご注意下さい。  

## 簡易圧縮グラフィック形式について
最初に、画像サイズ, BPP(ピクセルごとのビット数)から簡易圧縮グラフィックヘッダ(9バイト)を生成します。  
内容は次の通りです: [横ピクセル数(LE, 4バイト)][縦ピクセル数(LE, 4バイト)][BPP(1バイト)] (LEはリトルエンディアンを指します。)  
次に、簡易圧縮グラフィックデータを生成します。  
- 簡易圧縮はARGBの成分ごとに行われます。
- 始めに、各色成分のデータをBMP形式のピクセル配列の順にPUSHしていき、各成分ごとに配列を生成します。
- 次に、そのピクセル配列をもとに、同じ値を繰り返す回数, その値を各1バイトずつPUSHしていき、簡易圧縮を行った配列を各成分ごとに生成します。
	- (繰り返す回数は255回までです。256回目が現れた場合、255回+1回として扱います。)
- 配列終端に達した場合は、それを示すために繰り返す回数が0回となる値を配列にPUSHします。
	- (この場合は繰り返される値をPUSHしません。)

このようにして生成したヘッダ, 各成分ごとの配列を「ヘッダ,A,R,G,B」の順で結合します。(RGB888モードなら「ヘッダ,R,G,B」の順で結合します。)  
これが簡易圧縮グラフィック形式のファイル本体となります。  

## 注意点
- PIGATESTをPCへの転送に用いる場合には、[こちらのツイート](https://twitter.com/a_bkns/status/1247618338437476352)にあるようなプログラムの修正を行う必要があります。
- DEC_PIGAIMGの実行にはPHPがインストールされている必要があります。

## プチコン4 公開キーについて
プチコン4用BASICプログラムのダウンロードを行いやすくするため、公開作品としてソフト内からダウンロードできるようにしています。  
公開キー: `4KAQVA3N4`  

## 謝辞
このプログラムの作成にあたり、PIGATESTのコードを一部参考にしました。ありがとうございました。  

## 不具合報告等
以下のうちどれかまでお願いします。  
- Twitter: @odoq7211 @a_bkns
- Discord: mtar3_01#8897
- GitHub: このリポジトリ

## 更新履歴
- Ver.01
	- 初版公開
- Ver.02
	- TXT2PIGAIMG
		- メッセージ表示部分の処理の最適化を行いました。
	- GRP2PIGAIMG
		- 横ピクセル数が4の倍数でなかった場合に、破損したBMPファイルが生成されることがあった問題を修正しました。
			- (RGB888モードで生成したBMPファイルにて、パディングが行われていなかったことが原因でした。)
		- 透明度情報が必要かどうかを自動判定する機能を追加しました。
	- INFOPIGAIMG
		- グラフィックのBPP数値から色空間を推定する機能を追加しました。
