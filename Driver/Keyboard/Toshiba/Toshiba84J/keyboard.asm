COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
FILE:		keyboard.asm

AUTHOR:		Toru Terauchi, Nov 19, 1993

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	11/19/93	Initial revision

DESCRIPTION:
	Manager file for keyboard driver

	$Id: keyboard.asm,v 1.1 97/04/18 11:47:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include keyboardGeode.def
include keyboardConstant.def

idata	segment
;
; number of accentables
;
_NUM_ACCENTABLES	equ	KBD_NUM_ACCENTABLES
include	kmapToshiba84J.def
idata	ends

include keyboardVariable.def

include keyboardHotkey.asm
include keyboardInit.asm
include keyboardProcess.asm
include keyboardUtils.asm


KbdExtendedInfoSeg	segment	lmem LMEM_TYPE_GENERAL

DriverExtendedInfoTable <
	{},
	length kbdNameTable,
	offset kbdNameTable,
	0
>

kbdNameTable	lptr.char	kbdStr
		lptr.char	0

LocalDefString kbdStr <"Toshiba 84J Keyboard",0>

KbdExtendedInfoSeg	ends

end
