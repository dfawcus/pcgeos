COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1994.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI
FILE:		copenTitleGroup.asm

AUTHOR:		Steve Yegge, Sep 27, 1994

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/27/94		Initial revision

DESCRIPTION:

	Implementation of OLTitleGroupClass.

	$Id: copenTitleGroup.asm,v 1.1 97/04/07 10:53:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CommonUIClassStructures segment resource

	OLTitleGroupClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends


;---------------------------------------------------

GadgetBuild	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTitleGroupInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up various flags.

CALLED BY:	MSG_META_INITIALIZE

PASS:		*ds:si	= OLTitleGroupClass object
		ds:di	= OLTitleGroupClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLTitleGroupInitialize	method dynamic OLTitleGroupClass, 
					MSG_META_INITIALIZE
	;
	; call superclass directly to do stuff first
	;
	call	OLCtrlInitialize
	;
	;  Set up geometry flags.  We set expand-height-to-fit
	;  because this hints really means "expand height to fit
	;  suggested height passed by parent" which happens to be
	;  the title-bar height in our case.
	;
	call	GB_DerefVisSpecDI
	ornf	ds:[di].VCI_geoDimensionAttrs, \
	HJ_CENTER_CHILDREN_VERTICALLY shl offset VCGDA_HEIGHT_JUSTIFICATION \
		or mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT

	ornf	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX	

	ret
OLTitleGroupInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTitleGroupSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Spec build title group

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= OLTitleGroupClass object
		ds:di	= OLTitleGroupClass instance data
		ds:bx	= OLTitleGroupClass object (same as *ds:si)
		es 	= segment of OLTitleGroupClass
		ax	= message #
		bp	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLTitleGroupSpecBuild	method dynamic OLTitleGroupClass, 
					MSG_SPEC_BUILD
	call	VisCheckIfSpecBuilt
	jc	exit

	call	VisSpecBuildSetEnabledState	;set enabled state correctly
	
	;add ourself to the visual world

	mov	cx, ds:[LMBH_handle]		;cx:dx = ourself
	mov	dx, si

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	
	mov	bx, ds:[di].OLCI_visParent.handle	;bx:si = vis parent
	mov	si, ds:[di].OLCI_visParent.chunk

	mov	ax, MSG_VIS_ADD_CHILD
	mov	bp, CCO_LAST
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage

if (0)
	; At some point in the future, we may want to scan for geometry hints.
	;
	call	OLCtrlScanGeometryHints
endif

exit:
	ret
OLTitleGroupSpecBuild	endm

GadgetBuild	ends


CommonFunctional	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTitleGroupAddChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure children are ordered correctly.

CALLED BY:	MSG_VIS_ADD_CHILD

PASS:		*ds:si	= OLTitleGroupClass object
		ds:di	= OLTitleGroupClass instance data
		^lcx:dx = new child to add

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This routine is a total hack, and will need to be rewritten
   	if the other sys-icons (Maximize, minimize, restore) are
	ever put in the title-bar groups.

	This routine probably does the wrong thing if the primary
	help trigger needs to go in the left-group instead of the
 	right-group (no spuis need do this yet).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/ 6/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLTitleGroupAddChild	method dynamic OLTitleGroupClass, 
					MSG_VIS_ADD_CHILD
		.enter

if not _NO_PRIMARY_HELP_TRIGGER

	;
	;  If the child is a help trigger, add it last; otherwise
	;  add it first.
	;
		push	ds:[LMBH_handle], si	; save title group
		movdw	bxsi, cxdx
		call	MemDerefDS		; *ds:si = child ot add

		mov	bp, CCO_FIRST		; assume not help trigger
		mov	ax, ATTR_GEN_DEFAULT_MONIKER
		call	ObjVarFindData
		jnc	callSuper		; can't be help trigger

		cmp	{word}ds:[bx], GDMT_HELP_PRIMARY
		jne	callSuper
	;
	;  It's a help trigger (one would assume) => add last.
	;
		mov	bp, CCO_LAST		; put on far right
callSuper:
		pop	bx, si			; ^lbx:si = title group
		call	MemDerefDS		; *ds:si = title group

endif	; not _NO_PRIMARY_HELP_TRIGGER ----------------------------------------


		mov	ax, MSG_VIS_ADD_CHILD
		mov	di, offset OLTitleGroupClass
		call	ObjCallSuperNoLock	; preserves ^lcx:dx = child

; modifying passed CompChildFlags is faster

	;
	; update parent window header
	;
		mov	ax, MSG_OL_WIN_UPDATE_FOR_TITLE_GROUP
		call	VisCallParent
		.leave
		ret

OLTitleGroupAddChild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindAndMoveSlot0Child
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find HINT_SEEK_SLOT(0) and move to first child pos

CALLED BY:	OLTitleGroupAddChild via ObjCompProcessChildren
PASS:		*ds:si - child
		*es:di - composite
RETURN:		carry set if found, stops enumeration
		carry clear otherwise
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTGVisRemoveChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update parent window header

CALLED BY:	MSG_VIS_REMOVE_CHILD
PASS:		*ds:si	= OLTitleGroupClass object
		ds:di	= OLTitleGroupClass instance data
		ds:bx	= OLTitleGroupClass object (same as *ds:si)
		es 	= segment of OLTitleGroupClass
		ax	= message #
		^lcx:dx	= child
		bp	= dirty flag
RETURN:		^lcx:dx	= unchanged
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLTGVisRemoveChild	method dynamic OLTitleGroupClass, 
					MSG_VIS_REMOVE_CHILD
	.enter
	mov	di, offset OLTitleGroupClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_OL_WIN_UPDATE_FOR_TITLE_GROUP
	call	VisCallParent
	.leave
	ret
OLTGVisRemoveChild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTitleGroupVisDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Clear out our parent's reference of this object

PASS:		*ds:si	- OLTitleGroupClass object
		ds:di	- OLTitleGroupClass instance data
		es	- segment of OLTitleGroupClass

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This fixes a bug in which title bar group objects are
	destroyed without the parent knowing about it

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/24/95   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLTitleGroupVisDestroy	method	dynamic	OLTitleGroupClass, 
					MSG_VIS_DESTROY
		uses	ax,cx,dx,bp,es
		.enter

		mov	cx, ds:[LMBH_handle]
		mov	dx, si			; our optr

	;
	; See if our parent is OLWinClass.  If so, clear out either
	; the OLWI_titleBarLeftGroup or OLWI_titleBarRightGroup
	; instance field, as appropriate.
	;
		call	VisSwapLockParent
		push	bx			; child block

		segmov	es, <segment OLWinClass>, di
		mov	di, offset OLWinClass
		call	ObjIsObjectInClass
		jnc	done			; could this ever happen?

		mov	di, ds:[si]
		add	di, ds:[di].OLWin_offset

		mov	bx, offset OLWI_titleBarLeftGroup
		cmp	ds:[di][bx].handle, cx
		jne	tryRight
		cmp	ds:[di][bx].offset, dx
		je	found
tryRight:
		mov	bx, offset OLWI_titleBarRightGroup
		cmp	ds:[di][bx].handle, cx
		jne	done
		cmp	ds:[di][bx].offset, dx
		jne	done
found:
		clrdw	ds:[di][bx]

done:
		mov	si, dx
		pop	bx			; child block
		call	ObjSwapUnlock
		.leave
		mov	di, offset OLTitleGroupClass
		GOTO	ObjCallSuperNoLock
OLTitleGroupVisDestroy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTGVisUpdateGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update associated title bar since our geometry has changed

CALLED BY:	MSG_VIS_UPDATE_GEOMETRY
PASS:		*ds:si	= OLTitleGroupClass object
		ds:di	= OLTitleGroupClass instance data
		ds:bx	= OLTitleGroupClass object (same as *ds:si)
		es 	= segment of OLTitleGroupClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLTGVisUpdateGeometry	method dynamic OLTitleGroupClass, 
					MSG_VIS_UPDATE_GEOMETRY
	.enter
	push	ds:[di].VI_bounds.R_left, ds:[di].VI_bounds.R_right, \
			ds:[di].VI_bounds.R_top, ds:[di].VI_bounds.R_bottom
	mov	di, offset OLTitleGroupClass
	call	ObjCallSuperNoLock
	pop	ax, bx, cx, dx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ax, ds:[di].VI_bounds.R_left
	jne	updateWin
	cmp	bx, ds:[di].VI_bounds.R_right
	jne	updateWin
	cmp	cx, ds:[di].VI_bounds.R_top
	jne	updateWin
	cmp	dx, ds:[di].VI_bounds.R_bottom
	je	done
updateWin:
	call	VisFindParent
	mov	ax, MSG_OL_WIN_UPDATE_FOR_TITLE_GROUP
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
	mov	dl, VUM_NOW
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	.leave
	ret
OLTGVisUpdateGeometry	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTGVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw.

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si	= OLTitleGroupClass object
		ds:di	= OLTitleGroupClass instance data
		bp	= gstate

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Whatever happens in here should match OpenWinDrawHeaderTitle
	in each spui's winDraw.asm.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	Is there a way to have this thing never draw or invalidate
  	what's underneath it?  We really just want the children to
 	draw, which saves us the effort of having to re-draw the
	title-bar between the children (if they aren't butting up
	against each other).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CommonFunctional	ends

