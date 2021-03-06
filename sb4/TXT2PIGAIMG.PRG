'//////////////////////
'/ TXT2PIGAIMG Ver.02 /
'//////////////////////
'
'[はじめに]
'この度はプログラムをダウンロードして頂き、ありがとうございます。
'TXT2PIGAIMGは、TXTリソースからPIGATEST(制作者:まつたく氏, 公開キー:4KK4QS3Q4)用の
'テープイメージを生成するツールです。
'テープイメージに格納されるデータ構造は独自のものとなります。デコード用のPHPスクリプトは後述のGitHubリポジトリにあります。
'
'[使い方]
'変数FNAME_TXTに入力ファイル名を、変数FNAME_OUTに出力ファイル名を記述し、プログラムを実行してください。 
'オプションとして、以下の設定を行うことができます。
' 変数FNAME_HEAD(イメージファイルのヘッダに格納するファイル名)
'  空欄の場合は入力ファイル名を使用します。(デフォルト:空欄)
' 定数#MODE_COMP_TXT(簡易圧縮設定)
'  FALSEならUTF-16LEテキスト形式、TRUEならUTF-16LE簡易圧縮テキスト形式で格納します。
'  (デフォルト:TRUE)
'
'[イメージファイルの構造]
'先頭4バイトは格納されているファイル本体の形式を示す情報です。(CTXT:UTF-16LE簡易圧縮テキスト, RTXT:UTF-16LEテキスト)
'その後の12バイトは今のところ0x00固定です。(今後何か拡張する可能性はあります。)
'次にはファイル名の長さが1バイトで入り、その先から指定された長さ分のファイル名が入ります。
'さらに、ファイル名の直後からファイル本体が入ります。ファイル本体のサイズを示す情報は格納されていません。
'
'[UTF-16LE簡易圧縮テキストについて]
'コードポイント0x0000,0x0002〜0x00FFについては、上位1バイトを取り除き下位1バイトのデータとして追記します。
'(例: コードポイント0x0032 "2" -> バイト列0x32)
'コードポイント0x0001,0x0100〜については、先頭に0x01を付加して3バイトのデータとして追記します。
'(例: コードポイント0x306D "ね" -> バイト列0x01, 0x6D, 0x30)
'TXTリソースはASCII範囲内の文字の割合が多いと思われますので、これで転送量を抑えられると思います。
'逆に、ASCII範囲外の文字が多い場合には逆効果です。ご注意下さい。
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
'Ver.02: メッセージ表示部分の処理の最適化を行いました。
'
'[以下 プログラム本体]


'設定ここから
FNAME_TXT="" '入力ファイル名
FNAME_OUT="" '出力ファイル名
FNAME_HEAD="" 'イメージファイルのヘッダに格納するファイル名 (空欄なら入力ファイル名を使う)
LANG=GETLANG$() '言語設定 / Language Settings
CONST #MODE_COMP_TXT=#TRUE '簡易圧縮モード (TRUEなら簡易圧縮を行う)
'設定ここまで

DIM IMAGE%[0]
CONST #TXT2PIGAIMG_VER="02"

PRINT "TXT2PIGAIMG Ver."+#TXT2PIGAIMG_VER
PRINT

'設定内容を確認
IF FNAME_TXT=="" THEN
 '入力ファイル名未指定
 PRINT GETMESSAGE$(0)
 END 
ENDIF
IF FNAME_OUT=="" THEN
 '出力ファイル名未指定
 PRINT GETMESSAGE$(1)
 END
ENDIF
IF LEN(FNAME_TXT)>255 THEN
 '入力ファイル名が長すぎる
 PRINT GETMESSAGE$(2)
 END
ENDIF
IF LEN(FNAME_OUT)>255 THEN
 '出力ファイル名が長すぎる
 PRINT GETMESSAGE$(3)
 END
ENDIF
IF FNAME_HEAD=="" THEN
 'ヘッダ用ファイル名未指定(元のファイル名を使う)
 PRINT GETMESSAGE$(4)
 FNAME_HEAD=FNAME_TXT
ELSEIF LEN(FNAME_HEAD)>255 THEN
 'ヘッダ用ファイル名が長すぎる
 PRINT GETMESSAGE$(5)
 END
ELSE
 'ヘッダ用ファイル名の指定を表示
 PRINT GETMESSAGER$(14,FNAME_HEAD)
ENDIF
IF !CHKFILENAME(FNAME_HEAD) THEN
 'ヘッダ用ファイル名に使用できない文字が含まれている
 PRINT GETMESSAGE$(16)
 END
ENDIF

'入力ファイルの存在確認
IF !CHKFILE("TXT:"+FNAME_TXT) THEN
 PRINT GETMESSAGE$(17)
 END
ENDIF
'入力ファイル読込
PRINT GETMESSAGER$(10,FNAME_TXT);
IN_DATA$=LOADV("TXT:"+FNAME_TXT)
IF RESULT() THEN
 PRINT " ";GETMESSAGE$(7)
ELSE
 PRINT " ";GETMESSAGE$(8)
 PRINT GETMESSAGE$(15)
 END
ENDIF
'イメージファイル生成
'イメージファイル生成:header-filetype
IF #MODE_COMP_TXT THEN HEAD_DATA$="CTXT" ELSE HEAD_DATA$="RTXT"
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
IF #MODE_COMP_TXT THEN PUSH IMAGE%,1
PUSH IMAGE%,255:PUSH IMAGE%,254 'BOM(UTF-16LE)
IF #MODE_COMP_TXT THEN
 FOR I%=0 TO LAST(IN_DATA$)
  LOCATE 0,
  PRINT GETMESSAGE$(11);" (";I%+1;"/";LEN(IN_DATA$);")";
  TEXT_CP=ASC(MID$(IN_DATA$,I%,1))
  '簡易圧縮したUTFー16LE
  IF TEXT_CP>65535 THEN
   'サロゲートペアを使用する文字 (たぶん無いとは思うけど一応)
   PRINT
   PRINT GETMESSAGE$(6)
   END
  ELSEIF (TEXT_CP>255)||(TEXT_CP==1) THEN
   'コードポイントが0x0100以上, またはコードポイントが0x0001
   '先頭に0x01を付加したうえで2byteで文字を表す(合計3byte)。
   PUSH IMAGE%,1
   PUSH IMAGE%,TEXT_CP MOD 256
   PUSH IMAGE%,TEXT_CP DIV 256
  ELSE
   'それ以外(コードポイント0x0000, 0x0002〜0x00FF)
   'コードポイント下2桁の1byteで文字を表す。
   'TXTリソースはASCII範囲内の文字がメインなことが多いからそこそこ減るかな…?
   '(UTF-8変換を作るのが面倒でこうなったとか言えない)
   PUSH IMAGE%,TEXT_CP MOD 256
  ENDIF
 NEXT
ELSE
 FOR I%=0 TO LAST(IN_DATA$)
  LOCATE 0,
  PRINT GETMESSAGE$(12);" (";I%+1;"/";LEN(IN_DATA$);")";
  '普通のUTFー16LE
  TEXT_CP=ASC(MID$(IN_DATA$,I%,1))
  IF TEXT_CP>65535 THEN
   'サロゲートペアを使用する文字 (たぶん無いとは思うけど一応)
   PRINT
   PRINT GETMESSAGE$(6)
   END
  ELSE
   PUSH IMAGE%,TEXT_CP MOD 256
   PUSH IMAGE%,TEXT_CP DIV 256
  ENDIF
 NEXT
ENDIF
PRINT " ";GETMESSAGE$(7)
'イメージファイルの保存
PRINT GETMESSAGER$(18,STR$(LEN(IMAGE%)))
PRINT GETMESSAGER$(13,FNAME_OUT);" ";
SAVEV "DAT:"+FNAME_OUT,IMAGE%
CASE RESULT()
 WHEN  1:PRINT GETMESSAGE$(7)
 WHEN  0:PRINT GETMESSAGE$(8)
 WHEN -1:PRINT GETMESSAGE$(9)
ENDCASE
END


DEF GETMESSAGE$(MNO%)
 CONST #MSTRING_6_JA="エラー: サロゲートペアを使用する文字が検出されました。作者までご連絡下さい。"
 CONST #MSTRING_6_EN="Error: Unsupported character detected. Please contact the author of this program."
 LANG$=VAR("LANG")
 CASE LANG$
  WHEN "ja":'日本語(Japanese)
   CASE MNO%
    WHEN    0:MSTRING$="エラー: 入力ファイル名が指定されていません。"
    WHEN    1:MSTRING$="エラー: 出力ファイル名が指定されていません。"
    WHEN    2:MSTRING$="エラー: 入力ファイル名が長過ぎます。"
    WHEN    3:MSTRING$="エラー: 出力ファイル名が長過ぎます。"
    WHEN    4:MSTRING$="情報: ヘッダ用ファイル名が指定されていません。入力ファイル名を使用します。"
    WHEN    5:MSTRING$="エラー: ヘッダ用ファイル名が長過ぎます。"
    WHEN    6:MSTRING$=#MSTRING_6_JA+CHR$(10)+#MSTRING_6_EN
    WHEN    7:MSTRING$="完了。"
    WHEN    8:MSTRING$="失敗。"
    WHEN    9:MSTRING$="キャンセル。"
    WHEN   10:MSTRING$="TXTリソース「%A」をロードしています..."
    WHEN   11:MSTRING$="TXTリソースを簡易圧縮UTF-16LE形式のテープイメージに変換しています..."
    WHEN   12:MSTRING$="TXTリソースをUTF-16LE形式のテープイメージに変換しています..."
    WHEN   13:MSTRING$="テープイメージを「%A」としてセーブしています..."
    WHEN   14:MSTRING$="情報: ヘッダ用ファイル名が「%A」に指定されています。"
    WHEN   15:MSTRING$="エラー: 入力ファイルのロードに失敗しました。"
    WHEN   16:MSTRING$="エラー: ヘッダ用ファイル名に使用できない文字が含まれています。"
    WHEN   17:MSTRING$="エラー: 入力ファイルが存在しません。"
    WHEN   18:MSTRING$="ファイルサイズ: %A バイト"
    OTHERWISE:MSTRING$="[不正なメッセージ番号です]"
   ENDCASE
  WHEN "en":'English
   CASE MNO%
    WHEN    0:MSTRING$="Error: Input file name not specified."
    WHEN    1:MSTRING$="Error: Output image file name not specified."
    WHEN    2:MSTRING$="Error: Input file name too long."
    WHEN    3:MSTRING$="Error: Output image file name too long."
    WHEN    4:MSTRING$="Notice: File name for header not specified. input file name will be used instead."
    WHEN    5:MSTRING$="Error: File name for header too long."
    WHEN    6:MSTRING$=#MSTRING_6_EN+CHR$(10)+#MSTRING_6_JA
    WHEN    7:MSTRING$="Done."
    WHEN    8:MSTRING$="Failed."
    WHEN    9:MSTRING$="Cancelled."
    WHEN   10:MSTRING$="Loading TXT resource "+CHR$(34)+"%A"+CHR$(34)+"..."
    WHEN   11:MSTRING$="Converting raw text to compressed text tape image..."
    WHEN   12:MSTRING$="Converting raw text to raw text tape image..."
    WHEN   13:MSTRING$="Saving tape image file as "+CHR$(34)+"%A"+CHR$(34)+"..."
    WHEN   14:MSTRING$="Notice: File name for header is specified as "+CHR$(34)+"%A"+CHR$(34)+"."
    WHEN   15:MSTRING$="Error: Loading of input file failed."
    WHEN   16:MSTRING$="Error: Invalid character found in file name for header."
    WHEN   17:MSTRING$="Error: Input file not found."
    WHEN   18:MSTRING$="File size: %A bytes"
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

