# Universal Monitor

Single Board Computer 向けに多種の CPU に対応しているモニタプログラム Universal Monitor を導入する。
- 導入実績が豊富
- 十分な機能がある
- ソースが公開されている
  - MIT ライセンス
- 修正が容易

## 開発環境

- Ubuntu 24.04 LTS
- ROMライタ T48(TL866-3G)

## Reference

- [Universal Monitor](https://electrelic.com/electrelic/node/1317)
  - [ライセンス](https://electrelic.com/electrelic/node/1363)
  - [ビルド](https://electrelic.com/electrelic/node/1395)
    - [コンソールドライバ](https://electrelic.com/electrelic/node/1446)
    - [コンフィギュレーション](https://electrelic.com/electrelic/node/1447)
  - [操作方法](https://electrelic.com/electrelic/node/1319)
  - [ダウンロード](https://electrelic.com/electrelic/node/1318)
  - SVN
    - `svn checkout https://electrelic.com/svn/unimon/trunk unimon`
    - [ソース TarBall](https://electrelic.com/unimon/src/)
- [The Macroassembler AS](http://john.ccac.rwth-aachen.de:8000/as/)
  - [Download](http://john.ccac.rwth-aachen.de:8000/as/download.html)
  - [GitHub](https://github.com/Macroassembler-AS/asl-releases)

## ASL (MacroAssembler AS) 導入

多 CPU 対応のためアセンブラも多種対応のものが使用されている。  
記述時点で current は 1.42.build288 (らしい)。

```bash
## ソースコードをダウンロード、展開
$ wget http://john.ccac.rwth-aachen.de:8000/ftp/as/source/c_version/asl-current.tar.gz
$ tar xfvz asl-current.tar.gz
$ cd asl-current

## Version 確認
asl-current$ cat version.h
...
#define AS_VERSION_MAJOR 1
#define AS_VERSION_MINOR 42
#define AS_VERSION_BUILD 288
...

## ドキュメント用 LaTex 環境インストール
asl-current$ sudo apt install texlive-latex-base texlive-fonts-recommended texlive-fonts-extra texlive-latex-extra

## x86_64 linux 向け汎用Makefile.def をコピーして適用
asl-current$ ln -s ./Makefile.def-samples/Makefile.def-x86_64-unknown-linux ./Makefile.def

## ビルド
asl-current$ make
asl-current$ make docs

## インストール
### インストール先は /usr/local/ 以下
asl-current$ sudo make install
```

## ソースコード入手

記述時点で latest は 20250517 版。

```bash
## ソースコードをダウンロード、展開
$ wget https://electrelic.com/unimon/src/unimon-latest.tar.gz
$ tar xfvz unimon-latest.tar.gz
$ mv unimon-20250517 unimon
$ cd unimon
```

## 修正

SuperAKI80 にあわせ修正を行う

- コンフィギュレーション修正 z80/config/config.superaki80
  - config.aki80 がベース
    - CPUクロック 9.8304MHz で 9600bps になるように書かれている
    - シリアル入出力に SIOA を想定
    - TXCA,RXCA は CTC0 に接続されることを想定
  - 【修正点】SuperAKI80 では TXCA,RXCA は CTC3 に接続されている
```diff
--- z80/config/config.aki80     2022-07-30 23:30:12.000000000 +0900
+++ z80/config/config.superaki80        2025-06-02 16:25:50.542049180 +0900
@@ -1,6 +1,6 @@
 ;;; -*- asm -*-
 ;;;
-;;; Universal Monitor Z80 config file (for AKI-80)
+;;; Universal Monitor Z80 config file (for Super AKI-80)
 ;;;
 
 ;;;
@@ -74,13 +74,13 @@
 
 ;;; Zilog Z80 SIO
 
-USE_DEV_Z80SIO = 1
+USE_DEV_Z80SIO = 0
        IF USE_DEV_Z80SIO
 SIOAD: equ     18H             ; 
 SIOAC: equ     19H             ;
 SIOBD: equ     1AH             ; (Ch.B not supported)
 SIOBC: equ     1BH             ; (Ch.B not supported)
-USE_Z80CTC = 1                 ; Use Z80 CTC for baudrate generator
+USE_Z80CTC = 0                 ; Use Z80 CTC for baudrate generator
        IF USE_Z80CTC
 CTC0:  EQU     10H
 TC_V:  EQU     4               ; 9600bps @ 9.8304MHz
@@ -127,3 +127,23 @@
        IF USE_DEV_EMILY
 SMREG: EQU     0FF0H
        ENDIF
+
+;;; Zilog Z80 SIO
+
+USE_DEV_Z80SIO_CTC3 = 1
+       IF USE_DEV_Z80SIO_CTC3
+SIOAD: equ     18H             ; 
+SIOAC: equ     19H             ;
+SIOBD: equ     1AH             ; (Ch.B not supported)
+SIOBC: equ     1BH             ; (Ch.B not supported)
+USE_Z80CTC = 0         ; no use
+USE_Z80CTC3 = 1                ; Use Z80 CTC3 for baudrate generator
+       IF USE_Z80CTC3
+CTC0:  EQU     10H
+CTC1:  EQU     11H
+CTC2:  EQU     12H
+CTC3:  EQU     13H
+TC_V:  EQU     4               ; 9600bps @ 9.8304MHz
+       ENDIF                   ; USE_Z80CTC
+       ENDIF
+
```
- デバイスドライバ修正 z80/dev/dev_z80sio_ctc3.asm
  - dev_z80sio.asm がベース
  - 【修正点】シリアル用クロックを CTC0 ではなく CTC3 から供給する
```diff
--- z80/dev/dev_z80sio.asm      2021-10-09 13:33:40.000000000 +0900
+++ z80/dev/dev_z80sio_ctc3.asm 2025-06-02 16:20:50.079746778 +0900
@@ -17,7 +17,14 @@
        LD      A,TC_V
        OUT     (CTC0),A
        ENDIF                   ; USE_CTC
-
+
+       IF USE_Z80CTC3
+       LD      A,07H           ; Timer mode, 1/16, fall-edge, no ext trigger
+       OUT     (CTC3),A
+       LD      A,TC_V
+       OUT     (CTC3),A
+       ENDIF                   ; USE_CTC3
+
        ;; Ch.A WR1
        LD      A,01H
        OUT     (SIOAC),A
```
- 以上の設定を読み込むようメインコードを修正 unimon_z80.asm
```diff
--- a/z80/unimon_z80.asm
+++ b/z80/unimon_z80.asm
@@ -2023,6 +2023,10 @@ RNR:     DB      "R",00H
        INCLUDE "dev/dev_emily.asm"
        ENDIF
 
+       IF USE_DEV_Z80SIO_CTC3
+       INCLUDE "dev/dev_z80sio_ctc3.asm"
+       ENDIF
+
 ;;;
 ;;; RAM area
 ;;;
```

## ビルド

```bash
## Z80 向け
unimon/$ cd z80
## superaki80 用設定を適用
unimon/z80$ ln -s ./config/config.superaki80 ./config.inc
## ビルド
unimon/z80$ make

unimon/z80$ ls
Makefile  config  config.inc  dev  unimon_z80.asm  unimon_z80.hex  unimon_z80.lst
```

## EEPROM 書き込み

秋月モニタROMに代わり、EEPROM W27C512 を使う。

- [W27C512](../datasheets/W27C512.PDF)
  - 512kb(=64KB) EEPROM
    - 256kb の 27C256 の代わりに使用。つまり半分しか使用しない
    - SuperAKI80の回路図から 1 番ピン(A15)が HIGH 固定
  - 8000h〜FFFFh に 0000hから始まるつもりで書き込む必要がある
- ROMライタは T48(TL866-3G)
  - 書き込みアプリは公式からWindows向けのみ
  - Linux 用は以下から入手、deb パッケージ作成、インストール でOK
    - https://gitlab.com/DavidGriffith/minipro/

```bash
## hex ファイルの書き込み位置を変更
$ objcopy -I ihex -O ihex --change-address 0x8000 ./unimon_z80.hex ./unimon_superaki80-W27C512.hex

## ブランクチェック
$ minipro -p W27C512@DIP28 -b
Found T48 01.1.03 (0x103)
Warning: T48 support is experimental!
Device code: 34C12301
Serial code: 7UFBXWGJ1TW9190IDR9A8828
Chip ID: 0xDA08  OK
Reading Code...  0.30Sec  OK
Code memory section is blank.

## 書き込み
$ minipro -p W27C512@DIP28 -w ./unimon_superaki80-W27C512.hex
Found T48 01.1.03 (0x103)
Warning: T48 support is experimental!
Device code: 34C12301
Serial code: 7UFBXWGJ1TW9190IDR9A8828
Chip ID: 0xDA08  OK
Found Intel hex file.
Erasing... 0.30Sec OK
Writing Code...  30.99Sec  OK
Reading Code...  0.29Sec  OK
Verification OK
```

## 動作確認

W27C512 を秋月モニタROM の代わりに SuperAKI80 に搭載。

```text
Universal Monitor Z80
Z80
8000-FFFF
] r
A =00 BC =0000 DE =0000 HL =0000 F =00  IX=0000 IY=0000
A'=00 BC'=0000 DE'=0000 HL'=0000 F'=00  SP=0000 PC=0000 I=00 R=00
] d0100
0100 : ED 73 00 FF 31 10 FF F5 ED 5F 32 02 FF C5 01 FF : .s..1...._2.....
0110 : 00 ED 4C 78 B1 20 1A 3E C0 ED 39 3F ED 38 F4 32 : ..Lx. .>..9?.8.2
0120 : 03 FF E6 80 28 0B 3A 03 FF E6 7F ED 39 F4 C3 E8 : ....(.:.....9...
0130 : 09 31 00 00 11 00 80 21 01 80 7E 47 2F 77 BE 20 : .1.....!..~G/w. 
0140 : 09 1A BE 20 0A 70 1A BE 20 05 22 38 FF 18 09 70 : ... .p.. ."8...p
0150 : 23 7C B5 20 E5 22 38 FF AF 32 1B FF 01 FF 00 ED : #|. ."8..2......
0160 : 4C 78 B1 28 17 3E 40 CB 37 F2 D7 01 3E 7F ED 4F : Lx.(.>@.7...>..O
0170 : ED 5F FA 00 02 21 B1 0A AF C3 05 02 3E C0 ED 39 : ._...!......>..9
] 
```
