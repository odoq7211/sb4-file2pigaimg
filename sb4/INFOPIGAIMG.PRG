'//////////////////////
'/ INFOPIGAIMG Ver.02 /
'//////////////////////
'
'[はじめに]
'この度はプログラムをダウンロードして頂き、ありがとうございます。
'INFOPIGAIMGは、TXT2PIGAIMG, GRP2PIGAIMGで生成したテープイメージを読み込み、ヘッダ情報を表示するツールです。
'
'[使い方]
'プログラムを実行するとファイル名入力ダイアログが開きますので、ヘッダ情報を表示したいテープイメージのファイル名を入力して下さい。
'テープイメージをロードして、ヘッダ情報を表示します。
'
'[GitHubリポジトリについて]
'このプログラムや、生成したテープイメージをデコードするためのPHPスクリプト、PCへのデータ転送の詳細な手順などを
'以下のGitHubリポジトリに保存してあります。
' https://github.com/odoq7211/sb4-file2pigaimg
'
'[不具合報告等]
'以下のうちどれかまでお願いします。
'Twitter: @odoq7211 @a_bkns
'Discord: mtar3_01#8897
'GitHub: odoq7211/sb4-file2pigaimg
'
'[更新履歴]
'Ver.01: 初版公開
'Ver.02: グラフィックのBPP数値から色空間を推定する機能を追加しました。
'[以下 プログラム本体]


'設定ここから
LANG=GETLANG$() '言語設定 / Language Settings
'設定ここまで

DIM IMAGE%[0]
CONST #INFOPIGAIMG_VER="02"

PRINT "INFOPIGAIMG Ver."+#INFOPIGAIMG_VER
PRINT


'入力ファイル名の入力
PRINT GETMESSAGE$(2);
FNAME_IMG=DIALOG("",GETMESSAGE$(1))
CASE RESULT()
 WHEN  1:
  PRINT " ";GETMESSAGE$(7)
 WHEN  0:
  PRINT " ";GETMESSAGE$(8)
  END
 WHEN -1:
  PRINT " ";GETMESSAGE$(9)
  END
ENDCASE
'入力ファイルの存在確認
IF !CHKFILE("DAT:"+FNAME_IMG) THEN
 PRINT GETMESSAGE$(3)
 END
ENDIF
'入力ファイル読込
PRINT GETMESSAGER$(0,FNAME_IMG);
IMAGE%=LOADV("DAT:"+FNAME_IMG)
IF RESULT() THEN
 PRINT " ";GETMESSAGE$(7)
ELSE
 PRINT " ";GETMESSAGE$(8)
 PRINT GETMESSAGE$(4)
 END
ENDIF
'入力ファイルがテープイメージかどうか
IF DIM(IMAGE%)!=1 THEN
 PRINT GETMESSAGE$(16)
 END
ENDIF
'入力ファイルのヘッダ確認
FILETYPE_DATA$=""
FOR I%=0 TO 3
 INC FILETYPE_DATA$,CHR$(IMAGE%[I%])
NEXT
CASE FILETYPE_DATA$
 WHEN "CTXT":FILETYPE_NUM%=11
 WHEN "RTXT":FILETYPE_NUM%=12
 WHEN "CGRP":FILETYPE_NUM%=13
 WHEN "RGRP":FILETYPE_NUM%=14
 OTHERWISE  :FILETYPE_NUM%=-1
ENDCASE
IF FILETYPE_NUM%==-1 THEN
 PRINT GETMESSAGE$(15)
 END
ENDIF
FILENAME_SIZE%=IMAGE%[16]
FILENAME_STR$=""
FOR I%=0 TO FILENAME_SIZE%-1
 INC FILENAME_STR$,CHR$(IMAGE%[17+I%])
NEXT
IF RIGHT$(FILETYPE_DATA$,3)=="GRP" THEN
 GRPBODY_OFFSET%=17+FILENAME_SIZE%
 W_SIZE_HEX$="&H"
 H_SIZE_HEX$="&H"
 CASE LEFT$(FILETYPE_DATA$,1)
  WHEN "C":
   FOR I%=3 TO 0 STEP -1
    INC W_SIZE_HEX$,HEX$(IMAGE%[GRPBODY_OFFSET%+I%],2)
   NEXT
   FOR I%=7 TO 4 STEP -1
    INC H_SIZE_HEX$,HEX$(IMAGE%[GRPBODY_OFFSET%+I%],2)
   NEXT
   W_SIZE%=VAL(W_SIZE_HEX$)
   H_SIZE%=VAL(H_SIZE_HEX$)
   BPP%=IMAGE%[GRPBODY_OFFSET%+8]
  WHEN "R":
   FOR I%=21 TO 18 STEP -1
    INC W_SIZE_HEX$,HEX$(IMAGE%[GRPBODY_OFFSET%+I%],2)
   NEXT
   FOR I%=25 TO 22 STEP -1
    INC H_SIZE_HEX$,HEX$(IMAGE%[GRPBODY_OFFSET%+I%],2)
   NEXT
   W_SIZE%=VAL(W_SIZE_HEX$)
   H_SIZE%=VAL(H_SIZE_HEX$)
   BPP%=IMAGE%[GRPBODY_OFFSET%+28]
 ENDCASE
ENDIF
'情報表示
PRINT
PRINT "[";GETMESSAGE$(18);" ";FNAME_IMG;"]"
PRINT GETMESSAGER$(5,STR$(LEN(IMAGE%)))
PRINT GETMESSAGE$(10);" ";GETMESSAGE$(FILETYPE_NUM%)
PRINT GETMESSAGER$(6,STR$(LEN(IMAGE%)-(FILENAME_SIZE%+17)))
PRINT GETMESSAGE$(17);" ";FILENAME_STR$
IF RIGHT$(FILETYPE_DATA$,3)=="GRP" THEN
 PRINT GETMESSAGE$(19);" ";W_SIZE%;"x";H_SIZE%;" ";BPP%;"bpp(";BPPINFO$(BPP%);")"
ENDIF

END

DEF GETMESSAGE$(MNO%)
 LANG$=VAR("LANG")
 CASE LANG$
  WHEN "ja":'日本語(Japanese)
   CASE MNO%
    WHEN    0:MSTRING$="テープイメージ「%A」をロードしています..."
    WHEN    1:MSTRING$="ヘッダ情報を表示したいテープイメージのファイル名を入力して下さい。"
    WHEN    2:MSTRING$="入力ファイル名の入力を待機しています..."
    WHEN    3:MSTRING$="エラー: 入力ファイルが存在しません。"
    WHEN    4:MSTRING$="エラー: 入力ファイルのロードに失敗しました。"
    WHEN    5:MSTRING$="テープイメージのファイルサイズ: %A バイト"
    WHEN    6:MSTRING$="データのファイルサイズ: %A バイト"
    WHEN    7:MSTRING$="完了。"
    WHEN    8:MSTRING$="失敗。"
    WHEN    9:MSTRING$="キャンセル。"
    WHEN   10:MSTRING$="ファイル種別:"
    WHEN   11:MSTRING$="UTF-16LE簡易圧縮テキスト"
    WHEN   12:MSTRING$="UTF-16LEテキスト"
    WHEN   13:MSTRING$="簡易圧縮グラフィック形式"
    WHEN   14:MSTRING$="BMP形式"
    WHEN   15:MSTRING$="エラー: ファイル種別が不明です。"
    WHEN   16:MSTRING$="エラー: テープイメージではありません。"
    WHEN   17:MSTRING$="データのファイル名:"
    WHEN   18:MSTRING$="テープイメージ情報:"
    WHEN   19:MSTRING$="画像ヘッダ情報:"
    OTHERWISE:MSTRING$="[不正なメッセージ番号です]"
   ENDCASE
  WHEN "en":'English
   CASE MNO%
    WHEN    0:MSTRING$="Loading tape image "+CHR$(34)+"%A"+CHR$(34)+"..."
    WHEN    1:MSTRING$="Please enter image file name to load."
    WHEN    2:MSTRING$="Waiting for entering file name to load..."
    WHEN    3:MSTRING$="Error: Input file not found."
    WHEN    4:MSTRING$="Error: Loading of input file failed."
    WHEN    5:MSTRING$="File size of tape image: %A bytes"
    WHEN    6:MSTRING$="File size of data: %A bytes"
    WHEN    7:MSTRING$="Done."
    WHEN    8:MSTRING$="Failed."
    WHEN    9:MSTRING$="Cancelled."
    WHEN   10:MSTRING$="File type:"
    WHEN   11:MSTRING$="Compressed UTF-16LE text"
    WHEN   12:MSTRING$="Raw UTF-16LE text"
    WHEN   13:MSTRING$="Compressed graphic format"
    WHEN   14:MSTRING$="BMP format"
    WHEN   15:MSTRING$="Error: Unknown file type."
    WHEN   16:MSTRING$="Error: This file is not tape image."
    WHEN   17:MSTRING$="Filename of data:"
    WHEN   18:MSTRING$="Information of tape image:"
    WHEN   19:MSTRING$="Graphic header info:"
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

DEF BPPINFO$(BPP%)
 CASE BPP%
  WHEN   24:RET$="RGB888"
  WHEN   32:RET$="ARGB"
  OTHERWISE:RET$="Unknown"
 ENDCASE
 RETURN RET$
END

