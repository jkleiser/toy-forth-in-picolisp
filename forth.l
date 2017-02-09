#!/usr/bin/picolisp /usr/lib/picolisp/lib.l

# The paths above assumes a "global installation" of PicoLisp.

(de wordMsgSym (Token)
	(intern (pack "_" Token"_")) )

(setq *BlockMap '((: . +DefineWord) (do . +DoLoop) (if . +IfElseThen)))

(class +WordBlock)
# parent tempStack

(dm T (Parent)
	(=: parent Parent)
	(=: tempStack NIL) )

(dm handleToken> (Token)
	(if (get *BlockMap (intern Token))
		(new (list @) This)	# creating and returning new child
		(push (:: tempStack) (if (format Token) @ (wordMsgSym Token)))
		NIL ) )

(dm getRevTempStack> ()
	(when (reverse (: tempStack))
		#(println @)
		(=: tempStack NIL)
		@ ) )

(dm pushOnTempStack> (Child)
	(push (:: tempStack) Child) )

### end of class +WordBlock


(class +Forth +WordBlock)
# true false paused dStack rStack wordBlock

(dm T ()
	(super NIL)
	(=: true -1)
	(=: false 0)
	(=: paused NIL)
	(=: dStack NIL)	# data stack
	(=: rStack NIL)	# return stack, aka loop control stack
	(=: wordBlock This) )

(dm bool> (Truth)
	(if Truth (: true) (: false)) )

(dm popDataBool> ()
	(n0 (popDStack> This)) )

(dm popDStack> ()
	(or (pop (:: dStack)) (prog (prinl "Stack underflow!") NIL)) )

(dm pushRStack> (N)
	(push (:: rStack) N) )

(dm popRStack> ()
	(pop (:: rStack)) )

(dm indexLtLimit> ()
	(< (car (: rStack)) (cadr (: rStack))) )

(dm incIndex> ()
	(push (:: rStack) (inc (pop (:: rStack)))) )

(dm prompt> ()
	(let (Level 0  WB (: wordBlock))
		(until (= WB This)
			(inc 'Level)
			(setq WB (; WB parent)) )
		(pack (or (gt0 Level) "-") "> ") ) )

(dm applyToken> (Token)
	(case Token
		("pause" (=: paused 'paused))
		("bye" (bye))
		(T (ifn (= (: wordBlock) This)
				# wordBlock is some uncompleted child
				(let WB (: wordBlock)
					(when (handleToken> (: wordBlock) Token)
						(=: wordBlock @)
						# wordBlock WB has been completed
						# Execute WB if it was the immediate child of the +Forth object
						(when (= @ This)
							(execute> WB This) ) ) )
				# wordBlock is the +Forth object itself
				#(prinl "wordBlock is This: " (= (: wordBlock) This))
				(if (format Token)
					(push (:: dStack) @)
					(let MsgSym (wordMsgSym Token)
						(if (method MsgSym This)
							(send MsgSym This)
							# Prepare new wordBlock child if Token is found in *BlockMap ...
							(if (get *BlockMap (intern Token))
								(=: wordBlock (new (list @) This))
								(prinl "*** Undefined word: " Token) ) ) ) ) ) ) ) )

(dm executeBlock> (Block)
	#(prin "* executeBlock> Block: ") (println Block)
	(for Elem Block
		(if (num? Elem)
			(push (:: dStack) @)
			(if (isa '+WordBlock Elem)
				(execute> Elem This)
				(if (method Elem This)
					(send Elem This)
					(prinl "*** Undefined word: " Elem) ) ) ) ) )

(dm _drop_ ()
	(pop (:: dStack)) )

(dm _dup_ ()
	(when (car (: dStack)) (push (:: dStack) @)) )

(dm _over_ ()
	(when (cadr (: dStack)) (push (:: dStack) @)) )

(dm _swap_ ()
	(when (cadr (: dStack)) (=: dStack (cons @ (car (: dStack)) (tail -2 (: dStack))))) )

(dm _1+_ ()
	(when (pop (:: dStack)) (push (:: dStack) (inc @))) )

(dm _1-_ ()
	(when (pop (:: dStack)) (push (:: dStack) (dec @))) )

(dm _+_ ()
	(when (cadr (: dStack)) (=: dStack (cons (+ @ (car (: dStack))) (tail -2 (: dStack))))) )

(dm _*_ ()
	(when (cadr (: dStack)) (=: dStack (cons (* @ (car (: dStack))) (tail -2 (: dStack))))) )

(dm _<_ ()
	(when (cadr (: dStack)) (=: dStack (cons
		(bool> This (< @ (car (: dStack)))) (tail -2 (: dStack)) ) ) ) )

(dm _>_ ()
	(when (cadr (: dStack)) (=: dStack (cons
		(bool> This (> @ (car (: dStack)))) (tail -2 (: dStack)) ) ) ) )

(dm _i_ ()
	(if (car (: rStack))
		(push (:: dStack) @)
		(prinl "Loop control stack empty!") ) )

(dm _.s_ ()
	(println (or (reverse (: dStack)) "empty")) )

(dm _t_ ()		# just for testing
	(prin "tempStack: ") (println (: tempStack)) )

### end of class +Forth


(class +DefineWord +WordBlock)
# newWord body

(dm T (Parent)
	(super Parent)
	(prinl "+DefineWord")
	(=: newWord NIL)
	(=: body NIL) )

(dm handleToken> (Token)
	(let Block NIL
		(ifn (= ";" Token)
			(ifn (: newWord)
				(=: newWord Token)
				# newWord already set, collect body tokens ...
				(setq Block (super Token)) )	# Block may now become a new child
			# Got the closing ";"
			(=: body (getRevTempStack> This))
			(setq Block (: parent))		# subsequent tokens will go to parent
			(pushOnTempStack> Block This) )	# pushing This onto parent's token stack
		Block ) )

(dm execute> (F)
	(ifn (and (: newWord) (: body))
		(prinl "Ignoring empty DefineWord object")
		(push F (cons (wordMsgSym (: newWord))
			(list () (list 'executeBlock> (lit F) (lit (: body)))) ) )
		(prin "Done defining " (: newWord) " as ") (println (: body)) ) )

### end of class +DefineWord


(class +DoLoop +WordBlock)
# body

(dm T (Parent)
	(super Parent)
	(=: body NIL) )

(dm handleToken> (Token)
	(let Block NIL
		(ifn (= "loop" Token)
			(setq Block (super Token))		# Block may now become a new child
			# Got the closing "loop"
			(=: body (getRevTempStack> This))
			(setq Block (: parent))		# subsequent tokens will go to parent
			(pushOnTempStack> Block This) )	# pushing This onto parent's token stack
		Block ) )

(dm execute> (F)
	(let Index (popDStack> F)
		(pushRStack> F (popDStack> F))	# limit
		(pushRStack> F Index) )
	(while (indexLtLimit> F)
		(executeBlock> F (: body))
		(incIndex> F) )
	(popRStack> F)
	(popRStack> F) )

### end of class +DoLoop


(class +IfElseThen +WordBlock)
# trueBranch falseBranch gotElse

(dm T (Parent)
	(super Parent)
	(=: trueBranch NIL)
	(=: falseBranch NIL)
	(=: gotElse NIL) )

(dm handleToken> (Token)
	(let Block NIL
		(case Token
			("else"
				(=: trueBranch (getRevTempStack> This))
				(=: gotElse T) )
			("then"
				(if (: gotElse)
					(=: falseBranch (getRevTempStack> This))
					(=: trueBranch (getRevTempStack> This)) )
				(setq Block (: parent))		# subsequent tokens will go to parent
				(pushOnTempStack> Block This) )	# pushing This onto parent's token stack
			(T (setq Block (super Token))) )		# Block may now become a new child
		Block ) )

(dm execute> (F)
	(executeBlock> F (if (popDataBool> F) (: trueBranch) (: falseBranch))) )

### end of class +IfElseThen


(de doLine (Forth LineChars)
	(let Tokens (mapcar pack (split LineChars " "))
		(for Token Tokens
			(unless (or (sp? Token) (get F 'paused))
				#(println "doLine: " Forth Token)
				(applyToken> Forth Token) ) ) ) )

(de forthRepl (F)
	(setq *CurrentForth F)
	(put F 'paused NIL)
	(in NIL
		(until (get F 'paused)
			(prin (prompt> F))
			(doLine F (line)) ) ) )

(de emuForthReplHandler (Line)
	(doLine *CurrentForth (chop Line))
	(ifn (get *CurrentForth 'paused)
		"> "
		(off *ReplHandler)
		": " ) )

(de activateEmuForthRepl (F)
	(setq *CurrentForth F)
	(setq *ReplHandler emuForthReplHandler)
	(emulog "Activated " F)
	NIL )

(de resume ()
	(if *EMUENV
		(activateEmuForthRepl *CurrentForth)
		(forthRepl *CurrentForth) ) )

(setq *F1 (new '(+Forth))
		*F2 (new '(+Forth)) )

(if *EMUENV
	(activateEmuForthRepl *F1)
	# Normal PicoLisp ...
	(prinl (pack "-> "
		(forthRepl *F1) ) ) )
