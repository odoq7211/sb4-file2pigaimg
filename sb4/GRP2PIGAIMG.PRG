'//////////////////////
'/ GRP2PIGAIMG Ver.02 /
'//////////////////////
'
'[はじめに]
'この度はプログラムをダウンロードして頂き、ありがとうございます。
'GRP2PIGAIMGは、GRPリソースからPIGATEST(制作者:まつたく氏, 公開キー:4KK4QS3Q4)用の
'テープイメージを生成するツールです。
'テープイメージに格納されるデータ構造は独自のものとなります。デコード用のPHPスクリプトは後述のGitHubリポジトリにあります。
'
'[使い方]
'変数FNAME_GRPに入力ファイル名を記述し、プログラムを実行してください。
'オプションとして、以下の設定を行うことができます。
' 変数FNAME_OUT(出力ファイル名), 変数FNAME_HEAD(イメージファイルのヘッダに格納するファイル名)
'  空欄の場合は入力ファイル名を改変して使用します。(デフォルト:空欄)
' 定数#MODE_COMP_GRP(簡易圧縮設定)
'  FALSEならBMP形式、TRUEなら簡易圧縮グラフィック形式でグラフィックを格納します。(デフォルト:TRUE)
' 定数#FORCE_RGB888(強制RGB888モード)
'  TRUEなら強制的にRGB888の色空間でグラフィックを格納します。(デフォルト:FALSE)
' 定数#AUTODETECT_RGB888(RGB888自動判定モード)
'  TRUEなら、透明度情報が不要であると判定された場合にRGB888の色空間でグラフィックを格納します。(デフォルト:TRUE)
'定数#FORCE_RGB888, 定数#AUTODETECT_RGB888がどちらもFALSEである場合、常にARGBの色空間で格納されます。
'
'[イメージファイルの構造]
'先頭4バイトは格納されているファイル本体の形式を示す情報です。(CGRP:簡易圧縮グラフィック形式, RGRP:BMP形式)
'その後の12バイトは今のところ0x00固定です。(今後何か拡張する可能性はあります。)
'次にはファイル名の長さが1バイトで入り、その先から指定された長さ分のファイル名が入ります。
'さらに、ファイル名の直後からファイル本体が入ります。ファイル本体のサイズを示す情報は格納されていません。
'
'[簡易圧縮グラフィック形式について]
'最初に、画像サイズ, BPP(ピクセルごとのビット数)から簡易圧縮グラフィックヘッダ(9バイト)を生成します。
' 内容は次の通りです: [横ピクセル数(LE, 4バイト)][縦ピクセル数(LE, 4バイト)][BPP(1バイト)]
' (LEはリトルエンディアンを指します。)
'次に、簡易圧縮グラフィックデータを生成します。
' 簡易圧縮はARGBの成分ごとに行われます。
' 始めに、各色成分のデータをBMP形式のピクセル配列の順にPUSHしていき、各成分ごとに配列を生成します。
' 次に、そのピクセル配列をもとに、同じ値を繰り返す回数, その値を各1バイトずつPUSHしていき、簡易圧縮を行った配列を各成分ごとに生成します。
' (繰り返す回数は255回までです。256回目が現れた場合、255回+1回として扱います。)
' 配列終端に達した場合は、それを示すために繰り返す回数が0回となる値を配列にPUSHします。(この場合は繰り返される値をPUSHしません。)
'このようにして生成したヘッダ, 各成分ごとの配列を「ヘッダ,A,R,G,B」の順で結合します。
'(RGB888モードなら「ヘッダ,R,G,B」の順で結合します。)
'これが簡易圧縮グラフィック形式のファイル本体となります。
'
'[注意点]
'PIGATESTをPCへの転送に用いる場合には、以下のツイートにあるようなプログラムの修正を行う必要があります。
' https://twitter.com/a_bkns/status/1247618338437476352
'
'[GitHubリポジトリについて]
'このプログラムや、生成したテープイメージをデコードするためのPHPスクリプト、PCへのデータ転送の詳細な手順などを
'以下のGitHubリポジトリに保存してあります。
' https://github.com/odoq7211/sb4-file2pigaimg
'
'[謝辞]
'このプログラムの作成にあたり、PIGATESTのコードを一部参考にしました。
'ありがとうございました。
'
'[不具合報告等]
'以下のうちどれかまでお願いします。
'Twitter: @odoq7211 @a_bkns
'Discord: mtar3_01#8897
'GitHub: odoq7211/sb4-file2pigaimg
'
'[更新履歴]
'Ver.01: 初版公開
'Ver.02: 横ピクセル数が4の倍数でなかった場合に、破損したBMPファイルが生成されることがあった問題を修正しました。
'        (RGB888モードで生成したBMPファイルにて、パディングが行われていなかったことが原因でした。)
'        透明度情報が必要かどうかを自動判定する機能を追加しました。
'
'[以下 プログラム本体]


'設定ここから
FNAME_GRP="" '入力ファイル名
FNAME_OUT="" '出力ファイル名 (空欄なら入力ファイル名を改変して使う)
FNAME_HEAD="" 'イメージファイルのヘッダに格納するファイル名 (空欄なら入力ファイル名を改変して使う)
LANG=GETLANG$() '言語設定 / Language Settings
CONST #MODE_COMP_GRP=#TRUE '簡易圧縮モード (TRUEなら簡易圧縮を行う)
CONST #FORCE_RGB888=#FALSE '強制RGB888モード (TRUEなら透明度情報を格納しないよう強制する)
CONST #AUTODETECT_RGB888=#TRUE 'RGB888自動判定モード (TRUEなら透明度情報を格納するかどうかを自動判定)
'設定ここまで

DIM IMAGE%[0],PXARR_A%[0],PXARR_R%[0],PXARR_G%[0],PXARR_B%[0]
CONST #GRP2PIGAIMG_VER="02"
MODE_RGB888=#FORCE_RGB888

PRINT "GRP2PIGAIMG Ver."+#GRP2PIGAIMG_VER
PRINT
'簡易圧縮が有効ならメッセージを出す
IF #MODE_COMP_GRP THEN PRINT GETMESSAGE$(17)
'格納モードのメッセージを出す
CASE ((#FORCE_RGB888)*2)+(#AUTODETECT_RGB888)
 WHEN 0:
  PRINT GETMESSAGE$(28)
 WHEN 1:
  PRINT GETMESSAGE$(27)
 WHEN 2:
 WHEN 3:
  PRINT GETMESSAGE$(13)
ENDCASE
'設定内容を確認
IF FNAME_GRP=="" THEN
 '入力ファイル名未指定
 PRINT GETMESSAGE$(0)
 END 
ENDIF
IF FNAME_HEAD=="" THEN
 'ヘッダ用ファイル名未指定
 PRINT GETMESSAGE$(14)
 IF RIGHT$(FNAME_GRP,4)==".GRP" THEN
  FNAME_HEAD=LEFT$(FNAME_GRP,LEN(FNAME_GRP)-4)+".BMP"
 ELSE
  FNAME_HEAD=FNAME_GRP+".BMP"
 ENDIF
ELSEIF LEN(FNAME_HEAD)>255 THEN
 'ヘッダ用ファイル名が長すぎる
 PRINT GETMESSAGE$(15)
 END
ELSE
 'ヘッダ用ファイル名の指定を表示
 PRINT GETMESSAGER$(16,FNAME_HEAD)
ENDIF
IF !CHKFILENAME(FNAME_HEAD) THEN
 'ヘッダ用ファイル名に使用できない文字が含まれている
 PRINT GETMESSAGE$(25)
 END
ENDIF
IF FNAME_OUT=="" THEN
 '出力ファイル名未指定
 PRINT GETMESSAGE$(1)
 IF RIGHT$(FNAME_GRP,4)==".GRP" THEN
  FNAME_OUT=LEFT$(FNAME_GRP,LEN(FNAME_GRP)-4)+".IMG"
 ELSE
  FNAME_OUT=FNAME_GRP+".IMG"
 ENDIF
ENDIF
IF LEN(FNAME_GRP)>255 THEN
 '入力ファイル名が長すぎる
 PRINT GETMESSAGE$(2)
 END
ENDIF
IF LEN(FNAME_OUT)>255 THEN
 '出力ファイル名が長すぎる
 PRINT GETMESSAGE$(3)
 END
ENDIF

'入力ファイルの存在確認
IF !CHKFILE("GRP:"+FNAME_GRP) THEN
 PRINT GETMESSAGE$(26)
 END
ENDIF
'入力ファイル読込
PRINT GETMESSAGER$(4,FNAME_GRP);
IN_DATA%=LOADV("GRP:"+FNAME_GRP)
IF RESULT() THEN
 PRINT " ";GETMESSAGE$(7)
ELSE
 PRINT " ";GETMESSAGE$(8)
 PRINT GETMESSAGE$(24)
 END
ENDIF
GRP_W%=DIM(IN_DATA%,1)'横
GRP_H%=DIM(IN_DATA%,0)'縦
GRP_RGB888_PADDING%=GRP_W% MOD 4
'GRPリソースからARGBの値を取得
FOR H%=GRP_H%-1 TO 0 STEP -1
 FOR W%=0 TO GRP_W%-1
  LOCATE 0,
  PRINT GETMESSAGE$(11*(MODE_RGB888+1));" (";STR$(W%,4);",";STR$(H%,4);")";
  IF MODE_RGB888 THEN
   RGB IN_DATA%[H%,W%] OUT PX_R,PX_G,PX_B
  ELSE
   RGB IN_DATA%[H%,W%] OUT PX_A,PX_R,PX_G,PX_B
   PUSH PXARR_A%,PX_A
  ENDIF
  PUSH PXARR_R%,PX_R
  PUSH PXARR_G%,PX_G
  PUSH PXARR_B%,PX_B
 NEXT
NEXT
PRINT " ";GETMESSAGE$(7)
IF (!MODE_RGB888)&&(MIN(PXARR_A%)==255)&&(#AUTODETECT_RGB888) THEN
 PRINT GETMESSAGE$(29)
 MODE_RGB888=#TRUE
ENDIF
'イメージファイル生成
'イメージファイル生成:header-filetype
IF #MODE_COMP_GRP THEN HEAD_DATA$="CGRP" ELSE HEAD_DATA$="RGRP"
FOR I%=0 TO 15
 IF I%>LAST(HEAD_DATA$) THEN
  PUSH IMAGE%,0
 ELSE
  TEXT_CP=ASC(MID$(HEAD_DATA$,I%,1))
  PUSH IMAGE%,TEXT_CP MOD 256
 ENDIF
NEXT
'イメージファイル生成:header-filename
PUSH IMAGE%,LEN(FNAME_HEAD)
FOR I%=0 TO LAST(FNAME_HEAD)
 TEXT_CP=ASC(MID$(FNAME_HEAD,I%,1))
 PUSH IMAGE%,TEXT_CP MOD 256
NEXT
'イメージファイル生成:body
IF #MODE_COMP_GRP THEN
 '色成分ごとに圧縮
 IF !MODE_RGB888 THEN COMP_A%=GRP_COMPRESS%(PXARR_A%,"A") 'A
 COMP_R%=GRP_COMPRESS%(PXARR_R%,"R") 'R
 COMP_G%=GRP_COMPRESS%(PXARR_G%,"G") 'G
 COMP_B%=GRP_COMPRESS%(PXARR_B%,"B") 'B
 '簡易圧縮形式ヘッダ構造 (9bytes)
 COMPBITMAPHEADER$=""
 INC COMPBITMAPHEADER$,HEX_LE$(GRP_W%,4) 'W_SIZE
 INC COMPBITMAPHEADER$,HEX_LE$(GRP_H%,4) 'H_SIZE
 INC COMPBITMAPHEADER$,HEX$(32-(MODE_RGB888*8),2) 'BPP
 '簡易圧縮形式ヘッダ生成
 FOR I%=0 TO LAST(COMPBITMAPHEADER$) STEP 2
  PUSH IMAGE%,VAL("&H"+MID$(COMPBITMAPHEADER$,I%,2))
 NEXT
 '簡易圧縮形式データ生成
 IF !MODE_RGB888 THEN
  FOR I%=0 TO LEN(COMP_A%)
   LOCATE 0,
   PRINT GETMESSAGE$(21);" (A, ";I%;"/";LEN(COMP_A%);")";
   IF I%==LEN(COMP_A%) THEN BREAK
   PUSH IMAGE%,COMP_A%[I%]
  NEXT
  PRINT " ";GETMESSAGE$(7)
 ENDIF
 FOR I%=0 TO LEN(COMP_R%)
  LOCATE 0,
  PRINT GETMESSAGE$(21);" (R, ";I%;"/";LEN(COMP_R%);")";
  IF I%==LEN(COMP_R%) THEN BREAK
  PUSH IMAGE%,COMP_R%[I%]
 NEXT
 PRINT " ";GETMESSAGE$(7)
 FOR I%=0 TO LEN(COMP_G%)
  LOCATE 0,
  PRINT GETMESSAGE$(21);" (G, ";I%;"/";LEN(COMP_G%);")";
  IF I%==LEN(COMP_G%) THEN BREAK
  PUSH IMAGE%,COMP_G%[I%]
 NEXT
 PRINT " ";GETMESSAGE$(7)
 FOR I%=0 TO LEN(COMP_B%)
  LOCATE 0,
  PRINT GETMESSAGE$(21);" (B, ";I%;"/";LEN(COMP_B%);")";
  IF I%==LEN(COMP_B%) THEN BREAK
  PUSH IMAGE%,COMP_B%[I%]
 NEXT
 PRINT " ";GETMESSAGE$(7)
ELSE
 'BMPファイル生成
 'BMPヘッダ構造: BITMAPFILEHEADER (14bytes)
 BITMAPHEADER$="424D"+"00"*8+"36"+"00"*3
 'BMPヘッダ構造: BITMAPINFOHEADER (40bytes)
 INC BITMAPHEADER$,"28"+"00"*3
 INC BITMAPHEADER$,HEX_LE$(GRP_W%,4) 'W_SIZE
 INC BITMAPHEADER$,HEX_LE$(GRP_H%,4) 'H_SIZE
 INC BITMAPHEADER$,"0100"
 INC BITMAPHEADER$,HEX$(32-(MODE_RGB888*8),2) 'BPP
 INC BITMAPHEADER$,"00"*25
 'BMPファイル生成: HEADER
 FOR I%=0 TO LAST(BITMAPHEADER$) STEP 2
  PUSH IMAGE%,VAL("&H"+MID$(BITMAPHEADER$,I%,2))
 NEXT
 'BMPファイル生成: DATA
 '色の並びはBGRA(RGB888モードならBGR)
 'RGB888モードの場合、それぞれの横ピクセルの列の終端にパディングが必要。([GRP_W% MOD 4]バイト)
 FOR I%=0 TO LEN(PXARR_R%)
  LOCATE 0,
  PRINT GETMESSAGE$(5*(MODE_RGB888+1));" (";I%;"/";LEN(PXARR_R%);")";
  IF I%==LEN(PXARR_R%) THEN BREAK
  PUSH IMAGE%,PXARR_B%[I%]
  PUSH IMAGE%,PXARR_G%[I%]
  PUSH IMAGE%,PXARR_R%[I%]
  IF !MODE_RGB888 THEN
   PUSH IMAGE%,PXARR_R%[I%]
  ELSEIF (I% MOD GRP_W%)==(GRP_W%-1) THEN
   FOR J%=1 TO GRP_RGB888_PADDING%
    PUSH IMAGE%,0
   NEXT
  ENDIF
 NEXT
 PRINT " ";GETMESSAGE$(7)
ENDIF
'イメージファイルの保存
PRINT GETMESSAGER$(12,STR$(LEN(IMAGE%)))
PRINT GETMESSAGER$(6,FNAME_OUT);" ";
SAVEV "DAT:"+FNAME_OUT,IMAGE%
CASE RESULT()
 WHEN  1:PRINT GETMESSAGE$(7)
 WHEN  0:PRINT GETMESSAGE$(8)
 WHEN -1:PRINT GETMESSAGE$(9)
ENDCASE
END


DEF HEX_LE$(NUM%,WORDSIZE%)
 NUM_BE$=HEX$(NUM%,WORDSIZE%*2)
 NUM_LE$=""
 FOR I%=LAST(NUM_BE$)-1 TO 0 STEP -2
  INC NUM_LE$,MID$(NUM_BE$,I%,2)
 NEXT
 RETURN NUM_LE$
END

DEF GRP_COMPRESS%(PX_ARRAY%,COL_TYPE$)
 DIM RET_ARRAY%[0]
 COL_VALUE%=0:COL_TIMES%=0
 FOR I%=0 TO LEN(PX_ARRAY%)
  LOCATE 0,
  PRINT GETMESSAGE$(20);" (";COL_TYPE$;", ";I%;"/";LEN(PX_ARRAY%);")";
  IF I%!=LEN(PX_ARRAY%) THEN
   COL_RAW_VAL%=PX_ARRAY%[I%]
   IF I%==0 THEN
    COL_TIMES%=1
    COL_VALUE%=COL_RAW_VAL%
   ELSEIF (COL_TIMES%==255)||(COL_VALUE%!=COL_RAW_VAL%) THEN
    PUSH RET_ARRAY%,COL_TIMES%
    PUSH RET_ARRAY%,COL_VALUE%
    COL_TIMES%=1
    COL_VALUE%=COL_RAW_VAL%
   ELSEIF COL_VALUE%==COL_RAW_VAL% THEN
    INC COL_TIMES%
   ELSE
    '本来はここに来ないはず。来たら修正の必要あり。
    PRINT GETMESSAGE$(18)
   ENDIF
  ELSE
   PUSH RET_ARRAY%,COL_TIMES%
   PUSH RET_ARRAY%,COL_VALUE%
   PUSH RET_ARRAY%,0
   PRINT " ";GETMESSAGE$(7);
   PRINT " (";GETMESSAGER$(23,STR$(LEN(RET_ARRAY%)));")"
  ENDIF
 NEXT
 RETURN RET_ARRAY%
END

DEF GRP_DECOMPRESS%(COMP_ARRAY%)
 DIM RET_ARRAY%[0]
 FOR I%=0 TO LAST(COMP_ARRAY%)
  IF COMP_ARRAY%[I%]!=0 THEN
   IF I%!=LAST(COMP_ARRAY%) THEN
    COMP_TIMES%=COMP_ARRAY%[I%]
    COMP_VALUE%=COMP_ARRAY%[I%+1]
    INC I%
    FOR H%=1 TO COMP_TIMES%
     PUSH RET_ARRAY%,COMP_VALUE%
    NEXT
   ELSE
    'EOF(回数が0x00)がない
    PRINT GETMESSAGE$(19)
   ENDIF
  ENDIF
 NEXT
 RETURN RET_ARRAY%
END

DEF GETMESSAGE$(MNO%)
 LANG$=VAR("LANG")
 CASE LANG$
  WHEN "ja":'日本語(Japanese)
   CASE MNO%
    WHEN    0:MSTRING$="エラー: 入力ファイル名が指定されていません。"
    WHEN    1:MSTRING$="情報: 出力ファイル名が指定されていないため、入力ファイル名から生成しました。"
    WHEN    2:MSTRING$="エラー: 入力ファイル名が長過ぎます。"
    WHEN    3:MSTRING$="エラー: 出力ファイル名が長過ぎます。"
    WHEN    4:MSTRING$="GRPリソース「%A」をロードしています..."
    WHEN    5:MSTRING$="ARGB BMPを構成しています..."
    WHEN    6:MSTRING$="テープイメージを「%A」としてセーブしています..."
    WHEN    7:MSTRING$="完了。"
    WHEN    8:MSTRING$="失敗。"
    WHEN    9:MSTRING$="キャンセル。"
    WHEN   10:MSTRING$="RGB888 BMPを構成しています..."
    WHEN   11:MSTRING$="GRPリソースの色コードをARGB成分の数値に変換しています..."
    WHEN   12:MSTRING$="ファイルサイズ: %A バイト"
    WHEN   13:MSTRING$="情報: 強制RGB888モードが有効です。透明度情報は格納されません。"
    WHEN   14:MSTRING$="情報: ヘッダ用ファイル名が指定されていないため、入力ファイル名から生成しました。"
    WHEN   15:MSTRING$="エラー: ヘッダ用ファイル名が長過ぎます。"
    WHEN   16:MSTRING$="情報: ヘッダ用ファイル名が「%A」に指定されています。"
    WHEN   17:MSTRING$="情報: 簡易圧縮が有効です。"
    WHEN   18:MSTRING$="エラー: 簡易圧縮処理に失敗しました。"
    WHEN   19:MSTRING$="エラー: 簡易圧縮データにEOFがありません。"
    WHEN   20:MSTRING$="簡易圧縮処理を実行しています..."
    WHEN   21:MSTRING$="簡易圧縮グラフィックを構成しています..."
    WHEN   22:MSTRING$="GRPリソースの色コードをRGB成分の数値に変換しています..."
    WHEN   23:MSTRING$="チャンクサイズ: %A バイト"
    WHEN   24:MSTRING$="エラー: 入力ファイルのロードに失敗しました。"
    WHEN   25:MSTRING$="エラー: ヘッダ用ファイル名に使用できない文字が含まれています。"
    WHEN   26:MSTRING$="エラー: 入力ファイルが存在しません。"
    WHEN   27:MSTRING$="情報: RGB888自動判定モードが有効です。透明度情報が不要な場合には格納されません。"
    WHEN   28:MSTRING$="情報: 強制RGB888モードとRGB888自動判定モードの両方が無効です。透明度情報は常に格納されます。"
    WHEN   29:MSTRING$="情報: 透明度情報を格納する必要がないと判定されました。RGB888の色空間で格納します。"
    OTHERWISE:MSTRING$="[不正なメッセージ番号です]"
   ENDCASE
  WHEN "en":'English
   CASE MNO%
    WHEN    0:MSTRING$="Error: Input file name not specified."
    WHEN    1:MSTRING$="Notice: Output file name not specified, genetared automatically."
    WHEN    2:MSTRING$="Error: Input file name too long."
    WHEN    3:MSTRING$="Error: Output file name too long."
    WHEN    4:MSTRING$="Loading GRP resource "+CHR$(34)+"%A"+CHR$(34)+"..."
    WHEN    5:MSTRING$="Constituting ARGB BMP format..."
    WHEN    6:MSTRING$="Saving tape image file as "+CHR$(34)+"%A"+CHR$(34)+"..."
    WHEN    7:MSTRING$="Done."
    WHEN    8:MSTRING$="Failed."
    WHEN    9:MSTRING$="Cancelled."
    WHEN   10:MSTRING$="Constituting RGB888 BMP format..."
    WHEN   11:MSTRING$="Converting GRP color code to ARGB color component..."
    WHEN   12:MSTRING$="File size: %A bytes"
    WHEN   13:MSTRING$="Notice: Forced RGB888 mode enabled. Alpha channel won't be saved."
    WHEN   14:MSTRING$="Notice: File name for header not specified, genetared automatically."
    WHEN   15:MSTRING$="Error: File name for header too long."
    WHEN   16:MSTRING$="Notice: File name for header is specified as "+CHR$(34)+"%A"+CHR$(34)+"."
    WHEN   17:MSTRING$="Notice: Compression enabled."
    WHEN   18:MSTRING$="Error: Compression failed."
    WHEN   19:MSTRING$="Error: EOF code for compressed data not found"
    WHEN   20:MSTRING$="Compressing..."
    WHEN   21:MSTRING$="Constituting compressed graphic format..."
    WHEN   22:MSTRING$="Converting GRP color code to RGB color component..."
    WHEN   23:MSTRING$="Chunk size: %A bytes"
    WHEN   24:MSTRING$="Error: Loading of input file failed."
    WHEN   25:MSTRING$="Error: Invalid character found in file name for header."
    WHEN   26:MSTRING$="Error: Input file not found."
    WHEN   27:MSTRING$="Notice: RGB888 auto detection mode enabled. Alpha channel might not be saved."
    WHEN   28:MSTRING$="Notice: Both forced RGB888 mode and RGB888 auto detection mode are disabled. Alpha channel will always be saved."
    WHEN   29:MSTRING$="Notice: Detected that alpha channel is unneeded for this graphic. Alpha channel won't be saved."
    OTHERWISE:MSTRING$="[Invalid message number]"
   ENDCASE
  OTHERWISE:MSTRING$="[Invalid language specification (不正な言語指定です)]"
 ENDCASE
 RETURN MSTRING$
END

DEF GETMESSAGER$(MNO%,TOTEXT$)
 ORIG_MESSAGE$=GETMESSAGE$(MNO%)
 SUB_POS%=INSTR(ORIG_MESSAGE$,"%A")
 IF SUB_POS%==-1 THEN 
  RET$=ORIG_MESSAGE$
 ELSE
  RET$=SUBST$(ORIG_MESSAGE$,SUB_POS%,2,TOTEXT$)
 ENDIF
 RETURN RET$
END

DEF GETLANG$()
 CASE SYSPARAM("LANG")
  WHEN "ja":
  WHEN "en":
   RETLANG$=SYSPARAM("LANG")
  OTHERWISE:
   RETLANG$="en"
 ENDCASE
 RETURN RETLANG$
END

DEF CHKFILENAME(FILENAME$)
 '雑なプログラムでごめんなさい。 (大文字小文字を無視して比較する方法を思いつかなかったためにこうなっています)
 DIM NGLIST_ARRAY$[0],NGLIST_DEVICES$[0]
 'MS-DOSデバイス名一覧
 'CON
 PUSH NGLIST_DEVICES$,"con"
 PUSH NGLIST_DEVICES$,"Con"
 PUSH NGLIST_DEVICES$,"cOn"
 PUSH NGLIST_DEVICES$,"coN"
 PUSH NGLIST_DEVICES$,"COn"
 PUSH NGLIST_DEVICES$,"CoN"
 PUSH NGLIST_DEVICES$,"cON"
 PUSH NGLIST_DEVICES$,"CON"
 'AUX
 PUSH NGLIST_DEVICES$,"aux"
 PUSH NGLIST_DEVICES$,"Aux"
 PUSH NGLIST_DEVICES$,"aUx"
 PUSH NGLIST_DEVICES$,"auX"
 PUSH NGLIST_DEVICES$,"AUx"
 PUSH NGLIST_DEVICES$,"AuX"
 PUSH NGLIST_DEVICES$,"aUX"
 PUSH NGLIST_DEVICES$,"AUX"
 'PRN
 PUSH NGLIST_DEVICES$,"prn"
 PUSH NGLIST_DEVICES$,"Prn"
 PUSH NGLIST_DEVICES$,"pRn"
 PUSH NGLIST_DEVICES$,"prN"
 PUSH NGLIST_DEVICES$,"PRn"
 PUSH NGLIST_DEVICES$,"PrN"
 PUSH NGLIST_DEVICES$,"pRN"
 PUSH NGLIST_DEVICES$,"PRN"
 'NUL
 PUSH NGLIST_DEVICES$,"nul"
 PUSH NGLIST_DEVICES$,"Nul"
 PUSH NGLIST_DEVICES$,"nUl"
 PUSH NGLIST_DEVICES$,"nuL"
 PUSH NGLIST_DEVICES$,"NUl"
 PUSH NGLIST_DEVICES$,"NuL"
 PUSH NGLIST_DEVICES$,"nUL"
 PUSH NGLIST_DEVICES$,"NUL"
 'COM, LPT
 FOR NUM%=0 TO 9
  'COM0〜COM9
  PUSH NGLIST_DEVICES$,"com"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"Com"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"cOm"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"coM"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"COm"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"CoM"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"cOM"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"COM"+STR$(NUM%)
  'LPT0〜LPT9
  PUSH NGLIST_DEVICES$,"lpt"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"Lpt"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"lPt"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"lpT"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"LPt"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"LpT"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"lPT"+STR$(NUM%)
  PUSH NGLIST_DEVICES$,"LPT"+STR$(NUM%)
 NEXT
 FOR G%=0 TO LAST(NGLIST_DEVICES$)
  PUSH NGLIST_ARRAY$,NGLIST_DEVICES$[G%] 'MS-DOSデバイス名
  FOR H%=0 TO LAST(NGLIST_DEVICES$)
   PUSH NGLIST_ARRAY$,NGLIST_DEVICES$[G%]+NGLIST_DEVICES$[H%] 'MS-DOSデバイス名x2 (CONCON対策)
  NEXT
 NEXT
 PUSH NGLIST_ARRAY$,"." '先頭の「.」 (隠しファイル, カレントディレクトリ, 親ディレクトリ等)
 NGLIST_1BYTE$="/\?<>:*|^"+CHR$(34) 'NTFS等で使用できない文字
 RESULT%=#TRUE
 FOR I%=0 TO LAST(NGLIST_ARRAY$)
  'MS-DOSデバイス名がないか確認
  IF FILENAME$==NGLIST_ARRAY$[I%] THEN RESULT%=#FALSE '単体
  IF MID$(FILENAME$,0,LEN(NGLIST_ARRAY$[I%])+1)==(NGLIST_ARRAY$[I%]+".") THEN RESULT%=#FALSE '拡張子付き
 NEXT
 FOR I%=0 TO LAST(NGLIST_1BYTE$)
  'NTFS等で使用できない文字がないか確認
  IF INSTR(FILENAME$,MID$(NGLIST_1BYTE$,I%,1))!=-1 THEN RESULT%=#FALSE
 NEXT
 RETURN RESULT%
END

