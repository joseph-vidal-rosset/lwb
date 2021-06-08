if { [llength [namespace children [namespace current] Proof]] == 0} {

    namespace eval Proof {
	#___ proc create {proofArray frame} __________________________________

	proc create {proofArray frame} {
	    upvar $proofArray p

	    set p(p_frame) $frame;	      # frame widget in which the proof is shown
	    set p(p_canvas) [[namespace parent]::Util::scrolled_canvas $p(p_frame)]
					      # canvas widget in which the proof is drawn
	    set p(proof) $p(p_canvas).proof;  # path to proof widget
	    set p(popupmenu) $p(p_canvas).popupmenu
					      # path to popup menu
	    set p(r_frame) $p(p_frame).rule;  # frame widget that hold the rules
	    set p(r_canvas) {};		      # canvas widget in which the rules are drawn

	    set p(line_color) black;	      # default line color
	    set p(parentdistance) 5;	      # distance of node to its parent
	    set p(borderwidth) 5;	      # width of border around a node
	    set p(layout) premise_first;      # layout of proof
	    set p(sequent_pf_color) red;      # color for principal formulae
	    set p(sequent_sf_color) blue;     # color for side formulae
	    set p(sequent_nf_color) black;    # color for normal formulae
	    set p(selected_node) {};	      # label of currently selected node
	    set p(infotext) {};		      # information text of proof
	    set p(rule_ids) {};		      # list of rule ids
	    set p(r_color) black;	      # color of not selected rule
	    set p(r_sel_color) red;	      # color of selected rule
	    set p(r_gap) 20;		      # size of gap between rules
	    set p(r_maxheight) 0;	      # maximum height of a rule
	    set p(selected_rule) {};	      # label of currently selected rule

	    # name of global variable that maps each node label to a sequent command
	    set p(sequents) $p(proof).sequents
	    # name of global variable that maps each rule id to a list holding
	    # 1. premise, 2. conclusion, and 3. name of the rule 
	    set p(rules) $p(proof).rules
	    # name of global variable that maps each node label to a rule id
	    set p(node_rule_ids) $p(proof).node_rule_ids
	    # name of global variable that maps each node label to a list holding the labels of its sons
	    set p(node_sons) $p(proof).node_sons
	    # name of global variable that maps each node label to the node label of its father
	    set p(node_father) $p(proof).node_father

	    # font used for fomulae and rules
	    set p(font) proof_font
	    if {[option get $p(p_frame) font Proof] == ""} {
		[namespace parent]::Util::CopyFont\
			-adobe-helvetica-bold-r-*-*-*-120-*-*-*-*-*-* $p(font)
	    } else {
		[namespace parent]::Util::CopyFont\
			[option get $p(p_frame) font Proof] $p(font)
	    }
	    
	    # create proof widget
	    proof $p(proof) \
		    -parentdistance $p(parentdistance) \
		    -borderwidth $p(borderwidth) \
		    -layout $p(layout)

	    # create and set rectangle around selected sequent
	    set p(mark) [$p(p_canvas) create rectangle 0 0 0 0 -outline {}]
	    
	    # create popup menu
	    menu $p(popupmenu)
	    set busyon "[namespace parent]::Util::BusyOn $p(p_canvas)"
	    set busyoff "[namespace parent]::Util::BusyOff $p(p_canvas)"
	    $p(popupmenu) add command -label "hide conclusions"\
		    -command "$busyon;\
		    uplevel #0 [namespace current]::rm_parents $proofArray;\
		    $busyoff"
	    $p(popupmenu) add command -label "hide subproof(s)"\
		    -command "$busyon;\
		    uplevel #0 [namespace current]::rm_subproofs $proofArray;\
		    $busyoff"
	    $p(popupmenu) add command -label "show conclusion"\
		    -command "$busyon;\
		    uplevel #0 [namespace current]::add_parent $proofArray;\
		    $busyoff"
	    $p(popupmenu) add command -label "show premise(s)"\
		    -command "$busyon;\
		    uplevel #0 [namespace current]::add_sons $proofArray;\
		    $busyoff"
	    $p(popupmenu) add command -label "show subproof(s)"\
		    -command "$busyon;\
		    uplevel #0 [namespace current]::add_subproofs $proofArray;\
		    $busyoff"
	    $p(popupmenu) add command -label "redraw whole proof"\
		    -command "$busyon;\
		    uplevel #0 [namespace current]::redraw $proofArray;\
		    $busyoff"

	    # set default bindings for p_canvas
	    $p(p_canvas) bind sequent <1>\
		    "focus %W;\
		    uplevel #0 [namespace current]::select_deselect_node $proofArray"
	    $p(p_canvas) bind sequent <Double-1>\
		    "$busyon;\
		    focus %W;\
		    uplevel #0 [namespace current]::select_node $proofArray;\
		    uplevel #0 [namespace current]::toggle_subproofs $proofArray;\
		    $busyoff"
	    foreach event {<2> <Control-1>} {
		$p(p_canvas) bind sequent $event\
			"focus %W;\
			uplevel #0 [namespace current]::select_node $proofArray; \
			uplevel #0 [namespace current]::add_sons $proofArray"
	    }
	    foreach event {<Shift-2> <Control-Shift-1>} {
		$p(p_canvas) bind sequent $event\
			"focus %W;\
			uplevel #0 [namespace current]::select_node $proofArray;\
			uplevel #0 [namespace current]::add_parent $proofArray"
	    }
	    foreach event {<Double-2> <Control-Double-1>} {
		$p(p_canvas) bind sequent $event\
			"$busyon;\
			focus %W;\
			uplevel #0 [namespace current]::select_node $proofArray;\
			uplevel #0 [namespace current]::rm_parents $proofArray;\
			$busyoff"
	    }
	    $p(p_canvas) bind rule <1>\
		    "focus %W;\
		    uplevel #0 [namespace current]::show_rule $proofArray"
	    foreach event {<3> <Mod1-1>} {
		bind $p(p_canvas) $event\
			"focus %W;\
			tk_popup $p(popupmenu) %X %Y"
	    }
	    foreach event {<ButtonPress-2> <Control-ButtonPress-1>} {
		bind $p(p_canvas) $event\
			"$p(p_canvas) scan mark %x %y"
	    }
	    foreach event {<B2-Motion> <Control-B1-Motion>} {
		bind $p(p_canvas) $event\
			"$p(p_canvas) scan dragto %x %y"
	    }
	    unset busyon busyoff
	}

	#.....................................................................

	#___ proc center {proofArray} ________________________________________

	# center the proof in the scrolling area

	proc center {proofArray} {
	    create_local_vars proofArray
	    if {[$p(proof) cget -layout] == "premise_first"} {
		$p(p_canvas) yview moveto 1.0
	    } else {
		$p(p_canvas) yview moveto 0.0
	    }
	}

	#.....................................................................
	#___ proc add_node {proofArray parent node args} _____________________

	# Add the given node to the proof under the given parent node,
	# if not already there. 
	# This procedure does not add the given node to the proof widget.
	# Call create_subproofs to do this.
	#
	# optional args: -sequent  - sequent for node label
	#                -rule_id  - unique identification of id

	proc add_node {proofArray parent node args} {
	    set sequent {-nf {}}
	    set rule_id {}
	    [namespace parent]::Util::GetArgs $args
	    
	    create_local_vars proofArray
	    
	    # don't add the node if its already there
	    if [tag_exists $p(p_canvas) $node] {
		return
	    }
	    
	    set sequents($node) $sequent
	    set node_rule_ids($node) $rule_id
	    lappend node_sons($parent) $node
	    lappend node_father($node) $parent
	}

	#.....................................................................

	#___ proc son_count {proofArray node} ________________________________

	# returns number of sons the given node has

	proc son_count {proofArray node} {
	    create_local_vars proofArray
	    
	    set n [lsearch -exact [array names node_sons] $node]
	    # returns -1 if not found in names of array 'node_sons'
	    if {$n == -1} {
		return 0
	    } else {
		return [llength $node_sons($node)]
	    }
	}

	#.....................................................................
	#___ proc tag_exists {canvas tag} ____________________________________

	proc tag_exists {canvas tag} {
	    return [llength [$canvas find withtag $tag]]
	}

	#.....................................................................

	#___ proc create_subproofs {proofArray parent {wholeSubproof 1}} _____

	# create 

	proc create_subproofs {proofArray parent {wholeSubproof 1}} {
	    create_local_vars proofArray
	    if {[son_count p $parent] == 0} return
	    
	    foreach node $node_sons($parent) {
		if {$wholeSubproof} {
		    # don't add node if node is already there
		    if {![tag_exists $p(p_canvas) $node]} {
			if {"$sequents($node)" != ""} {
			    create_sequent p $node
			}
			if {"$node_rule_ids($node)" != {}} {
			    create_rule p $node
			}
			create_line p $node
			$p(proof) addlink $parent $node $node:rule $node:line -border 5
		    } else {
			if {![tag_exists $p(p_canvas) $node:line]} {
			    create_line p $node
			}
			if {![tag_exists $p(p_canvas) $node:rule]} {
			    create_rule p $node
			}
			if {[tag_exists $p(p_canvas) $node:contline]} {
			    $p(p_canvas) delete $node:contline
			    $p(proof) nodeconfigure $node
			}
		    }
		    create_subproofs p $node
		} else {
		    if {![tag_exists $p(p_canvas) $node]} {
			create_child p $parent $node
		    }
		}
	    }
	}

	#.....................................................................
	#___ proc create_child {proofArray parent child} _____________________

	proc create_child {proofArray parent child} {
	    
	    create_local_vars proofArray
	    
	    if {"$sequents($child)" != ""} {
		create_sequent p $child
	    }
	    
	    $p(proof) addlink $parent $child $child:rule $child:line -border 5
	    
	    if {[son_count p $child] != 0} {
		create_contline p $child
	    }
	}

	#.....................................................................
	#___ proc create_sequent {proofArray node} ___________________________

	proc create_sequent {proofArray node} {
	    create_local_vars proofArray
	    set sequent $sequents($node)
	    set l [llength $sequent]
	    set i 0
	    set withcomma 0
	    while {$i<[llength $sequent]} {
		set tag [lindex $sequent $i]
		incr i
		set text [lindex $sequent $i]
		switch -exact -- $tag {
		    -sf { 
			add_text p $node $text $p(sequent_sf_color) $withcomma sf
			set withcomma 1
		    }
		    -pf {
			add_text p $node $text $p(sequent_pf_color) $withcomma pf
			set withcomma 1
		    }
		    -delimiter {
			add_text p $node " $text " $p(sequent_nf_color) 0 nf
			set withcomma 0
		    }
		    -nf {
			add_text p $node $text $p(sequent_nf_color) $withcomma nf
			set withcomma 1
		    }
		    default {
			add_text p $node $text $p(sequent_nf_color) $withcomma nf
			set withcomma 1
			incr i -1
		    }
		}
		incr i
	    }
	}

	#.....................................................................
	#___ proc create_rule {proofArray node} ______________________________

	proc create_rule {proofArray node} {
	    
	    create_local_vars proofArray
	    
	    if {[son_count p $node] != 0} {
		set text [rulename p $node_rule_ids($node)]
		$p(p_canvas) create text 0 0\
			-text " $text"\
			-font $p(font)\
			-anchor nw\
			-tags [list $node_rule_ids($node) rule $node:rule]
	    }
	}

	#.....................................................................
	#___ proc create_line {proofArray node} ______________________________

	proc create_line {proofArray node} {

	    create_local_vars proofArray

	    if {[son_count p $node] != 0} {
		$p(p_canvas) create line 0 0 0 0 \
			-tag [list line $node:line] \
			-width 1 \
			-capstyle round \
			-fill $p(line_color)
	    }
	}

	#.....................................................................

	#___ proc add_text {proofArray node text color withcomma {type nf}} __

	proc add_text {proofArray node text color withcomma {type nf}} {

	    create_local_vars proofArray

	    set sequent $node:sequent
	    
	    if {[scan [$p(p_canvas) bbox $node] "%d %d %d %d" x1 y1 x2 y2] != 4} {
		set x2 0
		set y1 0
	    }
	    
	    if {$withcomma} {
		$p(p_canvas) create text [expr $x2] $y1 -text ", "\
			-fill $p(sequent_nf_color)\
			-font $p(font)\
			-anchor nw\
			-tags [list $node sequent $node:sequent sequent:nf]
	    }
	    
	    scan [$p(p_canvas) bbox $node] "%d %d %d %d" x1 y1 x2 y2
	    
	    $p(p_canvas) create text [expr $x2-2] $y1 -text $text\
		    -fill $color\
		    -font $p(font)\
		    -anchor nw\
		    -tags [list $node sequent $node:sequent sequent:$type]
	}


	#.....................................................................
	#___ proc select_deselect_node {proofArray} __________________________

	# select new node or deselect selected node

	proc select_deselect_node {proofArray} {

	    create_local_vars proofArray

	    set tag [get_current p]

	    if {"$tag" == [get_selected p]} {
		deselect_node p
	    } else {
		select_node p
	    }
	}

	#.....................................................................
	#___ proc select_node {proofArray {tag {}}} __________________________

	# select the current node's label

	proc select_node {proofArray {tag {}}} {

	    create_local_vars proofArray

	    if {$tag == {}} {
		set tag [get_current p]
	    }
	    
	    # reset tags of mark so that the bbox command doesn't return
	    # a too big box if the node was already selected
	    $p(p_canvas) itemconfig $p(mark) -tags {}
	    scan [$p(p_canvas) bbox $tag:sequent] "%d %d %d %d" x1 y1 x2 y2
	    $p(p_canvas) coords $p(mark) $x1 $y1 $x2 $y2
	    $p(p_canvas) itemconfig $p(mark) -tags $tag -outline $p(sequent_nf_color)
	    set p(selected_node) $tag
	}

	#.....................................................................
	#___ proc deselect_node {proofArray} _________________________________

	# de-select all node labels

	proc deselect_node {proofArray} {
	    create_local_vars proofArray
	    # hide mark
	    $p(p_canvas) itemconfig $p(mark) -tags {} -outline {}
	    set p(selected_node) {}
	}


	#.....................................................................
	#___ proc get_selected {proofArray} __________________________________

	# return the tag of the item currently selected

	proc get_selected {proofArray} {
	    create_local_vars proofArray
	    return $p(selected_node)
	}

	#.....................................................................
	#___ proc get_current {proofArray} ___________________________________

	# return the tag of the current item (the item under the mouse)

	proc get_current {proofArray} {
	    create_local_vars proofArray
	    return [lindex [$p(p_canvas) gettags current] 0]
	}

	#.....................................................................
	#___ proc create_contline {proofArray node} __________________________

	proc create_contline {proofArray node} {

	    create_local_vars proofArray
            
	    scan [$p(p_canvas) bbox $node:sequent] "%d %d %d %d" x1 y1 x2 y2
	    
	    if {"$p(layout)" == "conclusion_first"} {
		$p(p_canvas) create line $x1 $y2 $x2 $y2\
			-fill $p(sequent_pf_color)\
			-width 2\
			-tags [list $node contline $node:contline]
	    } else {
		$p(p_canvas) create line $x1 $y1 $x2 $y1\
			-fill $p(sequent_pf_color)\
			-width 2\
			-tags [list $node contline $node:contline]
	    }
	    $p(proof) nodeconfigure $node
	}

	#.....................................................................
	#___ proc toggle_subproofs {proofArray} ______________________________

	proc toggle_subproofs {proofArray} {
	    create_local_vars proofArray

	    set tag [get_selected p]
	    if {$tag == {}} return

	    if {[$p(proof) child $tag] == ""} {
		add_subproofs p
	    } else {
		rm_subproofs p
	    }
	}

	#.....................................................................
	#___ proc rm_subproofs {proofArray} __________________________________

	proc rm_subproofs {proofArray} {
	    create_local_vars proofArray

	    set tag [get_selected p]
	    if {$tag == {}} return

	    $p(proof) prune $tag
	    
	    if {[son_count p $tag] != 0} {
		create_contline p $tag
	    }
	    deselect_node p
	    $p(proof) nodeconfigure $tag
	    select_node p $tag

	    $p(proof) draw
	}

	#.....................................................................
	#___ proc rm_parents {proofArray} ____________________________________

	proc rm_parents {proofArray} {
	    create_local_vars proofArray

	    set tag [get_selected p]
	    if {$tag == {}} return

	    # if selected node is not at top of proof move it there and
	    # remove other top nodes
	    if {[lsearch [$p(proof) subnodes {}] $tag] == -1} {
		set topnodes [$p(proof) subnodes {}]
		$p(proof) movelink $tag {}
		foreach topnode $topnodes {
		    $p(proof) rmlink $topnode
		}
	    }
	    $p(proof) draw
	}

	#.....................................................................
	#___ proc redraw {proofArray} ________________________________________

	proc redraw {proofArray} {
	    create_local_vars proofArray
	    deselect_node p
	    $p(proof) prune {}
	    create_subproofs p {}
	    $p(proof) draw
	    redraw_rules p
	}

	#.....................................................................
	#___ proc add_parent {proofArray} ____________________________________

	proc add_parent {proofArray} {

	    create_local_vars proofArray

	    set tag [get_selected p]
	    if {$tag == {}} return

	    set parent $node_father($tag)
	    if {"$parent" != "{}"} {
		if {![tag_exists $p(p_canvas) $parent]} {
		    create_sequent p $parent
		    create_rule p $parent
		    create_line p $parent
		    $p(proof) addlink {} $parent $parent:rule $parent:line -border 5

		    # move visible child to right position and create other childs
		    foreach child $node_sons($parent) {
		        if {$child == $tag} {
			    $p(proof) movelink $child $parent
		        } else {
			    create_child p $parent $child
		        }
		    }
		}
		select_node p $parent
	    }
	    # $p(proof) draw
	    
	}

	#.....................................................................
	#___ proc add_sons {proofArray} ______________________________________

	proc add_sons {proofArray} {

	    create_local_vars proofArray

	    set tag [get_selected p]
	    if {$tag == {}} return
	    add_subproofs p 0
	    
	    if {[son_count p $tag] != 0} {
		# select first son that has a son
		foreach son $node_sons($tag) {
		    if {[son_count p $son] != 0} {
			select_node p $son
			return
		    }
		}
		
		# No son has a son -> select first son if present
		select_node p [lindex $node_sons($tag) 0]
	    }
	}

	#.....................................................................
	#___ proc add_subproofs {proofArray {wholeSubproof 1}} _______________

	proc add_subproofs {proofArray {wholeSubproof 1}} {

	    create_local_vars proofArray

	    set tag [get_selected p]
	    if {$tag == {}} return

	    if {![tag_exists $p(p_canvas) $tag:line]} {
		create_line p $tag
	    }
	    if {![tag_exists $p(p_canvas) $tag:rule]} {
		create_rule p $tag
	    }
	    if {[tag_exists $p(p_canvas) $tag:contline]} {
		$p(p_canvas) delete $tag:contline
	    }

	    deselect_node p
	    $p(proof) nodeconfigure $tag
	    select_node p $tag

	    create_subproofs p $tag $wholeSubproof
	    $p(proof) draw
	}


	#.....................................................................
	#___ proc reset {proofArray} _________________________________________

	# delete the proof and the arrays except the node {}

	proc reset {proofArray} {

	    create_local_vars proofArray

	    deselect_node p
	    $p(proof) prune {}
	    foreach i {node_sons node_father node_rule_ids} {
		if [info exists $i] {unset $i}
	    }
	    reset_info p
	    init_rule p
	}

	#.....................................................................
	#___ proc save {proofArray file} _____________________________________

	proc save {proofArray file} {

	    create_local_vars proofArray

	    set fileid [open $file w]
	    save_rules p $fileid
	    save_info p $fileid
	    foreach topnode [$p(proof) subnodes {}] {
		save_nodes p $topnode $fileid
	    }
	    close $fileid
	}

	#.....................................................................
	#___ proc save_rules {proofArray fileid} _____________________________

	proc save_rules {proofArray fileid} {

	    create_local_vars proofArray

	    foreach rule_id $p(rule_ids) {
		puts $fileid "add_rule $rules($rule_id) $rule_id"
	    }
	}

	#.....................................................................
	#___ proc save_nodes {proofArray node fileid} ________________________

	proc save_nodes {proofArray node fileid} {

	    create_local_vars proofArray

	    puts -nonewline $fileid "add_node $node_father($node) $node "
	    puts -nonewline $fileid "-sequent {$sequents($node)} "
	    puts $fileid "-rule_id {$node_rule_ids($node)}"
	    
	    flush $fileid

	    if [son_count p $node] {
		foreach son $node_sons($node) {
		    save_nodes p $son $fileid
		}
	    }
	}

	#.....................................................................
	#___ proc set_layout {proofArray ilayout} ____________________________

	proc set_layout {proofArray layout} {

	    create_local_vars proofArray

	    if {[lsearch [list conclusion_first premise_first] $layout] == -1} {
		puts stderr "Unknown layout mode. Valid modes are:"
		puts stderr "conclusion_first, premise_first"
		return
	    }

	    if {"$layout" == "$p(layout)"} {
		return
	    } else {
		# the 'layout' variable is changed toggle_layout
		toggle_layout p
	    }
	}

	#.....................................................................
	#___ proc toggle_layout {proofArray} _________________________________

	# Toggle the layout of the proof between conclusion_first and premise_first

	proc toggle_layout {proofArray} {

	    create_local_vars proofArray

	    # remove mark
	    set now_selected_node [get_selected p]
	    deselect_node p
	    
	    set contline_nodes [remove_contlines p]

	    if {[$p(proof) cget -layout] == "premise_first"} {
		$p(proof) config -layout conclusion_first
		set p(layout) conclusion_first
	    } else {
		$p(proof) config -layout premise_first
		set p(layout) premise_first
	    }
	    
	    # redraw removed contlines
	    foreach i $contline_nodes {
		create_contline p $i
	    }

	    # redraw mark
	    if {"$now_selected_node" != {} } {
		select_node p $now_selected_node
	    }

	    center p
	    
	    # toggle the layout of the rule_obj too.
	    if [winfo exists $p(r_canvas)] {
		foreach i $p(rule_ids) {
		    scan [$p(r_canvas) coords r:$i:premise] "%f %f" px py
		    scan [$p(r_canvas) coords r:$i:conclusion] "%f %f" cx cy
		    $p(r_canvas) coords r:$i:premise $cx $cy
		    $p(r_canvas) coords r:$i:conclusion $px $py
		}
	    }
	}

	#.....................................................................
	#___ proc remove_contlines {proofArray} ______________________________
	# remove the lines that are drawn when a subproof is hidden
	# and return a list the nodes where the line has been deleted

	proc remove_contlines {proofArray} {

	    create_local_vars proofArray

	    set contlines [$p(p_canvas) find withtag contline]
	    set contline_nodes ""
	    foreach i $contlines {
		set node [lindex [$p(p_canvas) gettags $i] 0]
		lappend contline_nodes $node
	    }
	    
	    eval "$p(p_canvas) delete $contlines"
	    return $contline_nodes
	}

	#.....................................................................
	#___ proc highlight_sf {proofArray color} ____________________________

	proc highlight_sf {proofArray color} {

	    create_local_vars proofArray

	    set p(sequent_sf_color) $color
	    $p(p_canvas) itemconfig sequent:sf -fill $p(sequent_sf_color)
	}


	#.....................................................................

	# procs concerning infotext ==========================================

	#___ proc reset_info {proofArray} ____________________________________

	proc reset_info {proofArray} {
	    create_local_vars proofArray
	    set p(infotext) ""
	}

	#.....................................................................
	#___ proc append_info {proofArray text} ______________________________

	proc append_info {proofArray text} {
	    create_local_vars proofArray
	    append p(infotext) $text
	}

	#.....................................................................
	#___ proc save_info {proofArray fileid} ______________________________

	proc save_info {proofArray fileid} {
	    create_local_vars proofArray
	    puts -nonewline $fileid "append_info {"
	    puts -nonewline $fileid $p(infotext)
	    puts $fileid "}"
	}

	#.....................................................................

	# procs concerning 'rulecmds_obj' ====================================

	#___ proc show_rule {proofArray} _____________________________________

	# show the rule the user has clicked on
	proc show_rule {proofArray} {
	    create_local_vars proofArray
	    regsub r: [get_current p] "" selected_rule
	    select_rule p $selected_rule
	}

	#.....................................................................
	#___ proc init_rule {proofArray} _____________________________________

	# call proc init in 'rulecmds_obj'
	proc init_rule {proofArray} {
	    create_local_vars proofArray
	    reset_r_frame p
	    set p(rule_ids) {}
	    if [info exists rules] {unset rules}
	}

	#.....................................................................

	#___ proc create_local_vars {proofArray} _____________________________

	proc create_local_vars {proofArray} {
	    uplevel upvar $$proofArray p
	    uplevel {upvar #0 $p(sequents) sequents}
	    uplevel {upvar #0 $p(rules) rules}
	    uplevel {upvar #0 $p(node_rule_ids) node_rule_ids}
	    uplevel {upvar #0 $p(node_sons) node_sons}
	    uplevel {upvar #0 $p(node_father) node_father}
	}

	#.....................................................................

	#___ proc create_r_frame {proofArray} ________________________________
	# create the rule widget and draw all rules stored in 'rules'

	proc create_r_frame {proofArray} {
	    create_local_vars proofArray
	    if [winfo exists $p(r_canvas)] {
		return
	    }
	    
	    if ![winfo exists $p(r_frame)] {
		wm withdraw [toplevel $p(r_frame)]
		wm title $p(r_frame) Rules
	    }
	    
	    set p(r_canvas) [[namespace parent]::Util::scrolled_canvas $p(r_frame)]

	    foreach event {<ButtonPress-2> <Control-ButtonPress-1>} {
		bind $p(r_canvas) $event\
			"$p(r_canvas) scan mark %x %y"
	    }
	    foreach event {<B2-Motion> <Control-B1-Motion>} {
		bind $p(r_canvas) $event\
			"$p(r_canvas) scan dragto %x %y"
	    }
	    foreach event {<Double-1>} {
		bind $p(r_canvas) $event\
		    "wm withdraw $p(r_frame)"
	    }
	    
	    draw_rules p
	}

	#.....................................................................
	#___ proc draw_rules {proofArray} ____________________________________
	# draw all rules
	proc draw_rules {proofArray} {
	    create_local_vars proofArray
	    foreach rule_id $p(rule_ids) {
		draw_rule p $rule_id
	    }
	}

	#.....................................................................
	#___ proc draw_rule {proofArray rule_id} _____________________________

	proc draw_rule {proofArray rule_id} {
	    create_local_vars proofArray

	    set premise [lindex $rules($rule_id) 0]
	    set conclusion [lindex $rules($rule_id) 1]
	    set rulename [lindex $rules($rule_id) 2]
	    set rule_id r:$rule_id;

	    if {$p(layout) == "conclusion_first"} {
		set label1 conclusion
		set label2 premise
	    } else {
		set label1 premise
		set label2 conclusion
	    }

	    if {[scan [$p(r_canvas) bbox all] "%d %d %d %d" x1 y1 x2 y2] != 4} {
		set y1 0
	    } else {
		set y1 [expr $y2 + $p(r_gap)]
	    }

	    $p(r_canvas) create text 0 $y1 -text [set [set label1]] -anchor n\
		    -fill $p(r_color) -tags [list $rule_id $rule_id:$label1]\
		    -font $p(font)

	    scan [$p(r_canvas) bbox $rule_id] "%d %d %d %d" x1 y1 x2 y2

	    set middle $y2

	    $p(r_canvas) create text 0 [expr $middle + 3] -text [set [set label2]]\
		    -anchor n -fill $p(r_color)\
		    -tags [list $rule_id $rule_id:$label2]\
		    -font $p(font)

	    scan [$p(r_canvas) bbox $rule_id] "%d %d %d %d" x1 y1 x2 y2

	    $p(r_canvas) create line $x1 $middle $x2 $middle -fill $p(r_color)\
		    -tags [list $rule_id $rule_id:line]

	    $p(r_canvas) create text $x2 $middle -text $rulename -fill $p(r_color)\
		    -anchor w -tags [list $rule_id $rule_id:rulename]\
		    -font $p(font)

	    $p(r_canvas) config -scrollregion [$p(r_canvas) bbox all]

	    scan [$p(r_canvas) bbox all] "%d %d %d %d" x1 y1 x2 y2
	    $p(r_canvas) config -width [expr $x2 - $x1]

	    scan [$p(r_canvas) bbox $rule_id] "%d %d %d %d" x1 y1 x2 y2
	    if {$p(r_maxheight) < [expr $y2 - $y1]} {
		set p(r_maxheight) [expr $y2 - $y1]
		$p(r_canvas) config -height $p(r_maxheight)
	    }

	    return $rule_id
	}

	#.....................................................................
	#___ proc add_rule {proofArray premise conclusion rulename rule_id} __

	# add rule and store it in 'rules' array
	proc add_rule {proofArray premise conclusion rulename rule_id} {
	    create_local_vars proofArray
	    
	    if {$premise == {} || $conclusion == {}} return

	    if [rule_exists p $rule_id] {
		puts stderr "Warning! Rule already exists, not added."
		return
	    }

	    create_r_frame p
	    
	    set rules($rule_id) [list $premise $conclusion $rulename]
	    lappend p(rule_ids) $rule_id
	    
	    draw_rule p $rule_id
	}

	#.....................................................................
	#___ proc delete_rule {proofArray rule_id} ___________________________

	# delete a rule
	proc delete_rule {proofArray rule_id} {
	    create_local_vars proofArray

	    if ![rule_exists p $rule_id] {
		puts stderr "No such rule to delete!"
		return
	    }
	    
	    # delete 'rule_id' from 'p(rule_ids)'
	    set index [lsearch -exact $p(rule_ids) $rule_id]
	    set p(rule_ids) [lreplace $p(rule_ids) $index $index]
	    
	    # delete rule from 'rules'
	    unset rules($rule_id)
	    
	    # redraw rules
	    reset_r_frame p
	    draw_rules p
	}

	#.....................................................................
	#___ proc select_rule {proofArray rule_id} ___________________________

	# select a rule
	proc select_rule {proofArray rule_id} {
	    create_local_vars proofArray
	    if ![rule_exists p $rule_id] return
	    
	    create_r_frame p
	    wm deiconify $p(r_frame)
	    raise $p(r_frame)
	    
	    $p(r_canvas) itemconfig r:$p(selected_rule) -fill $p(r_color)
	    set p(selected_rule) $rule_id
	    color_selected_rule p

	    scan [$p(r_canvas) bbox r:$rule_id] "%d %d %d %d" rx1 ry1 rx2 ry2
	    scan [$p(r_canvas) bbox all] "%d %d %d %d" x1 y1 x2 y2
	    
	    $p(r_canvas) config -height [expr $ry2 - $ry1]
	    $p(r_canvas) yview moveto [expr $ry1.0 / ($y2.0 - $y1.0)]
	}

	#.....................................................................
	#___ proc color_selected_rule {proofArray} ___________________________
	
	proc color_selected_rule {proofArray} {
	    create_local_vars proofArray
	    $p(r_canvas) itemconfig r:$p(selected_rule) -fill $p(r_sel_color)
	}

	#.....................................................................
	#___ proc redraw_rules {proofArray} __________________________________
	proc redraw_rules {proofArray} {
	    create_local_vars proofArray
	    if [winfo exists $p(r_canvas)] {
		$p(r_canvas) delete all
		draw_rules p
		color_selected_rule p
	    }
	}
	#.....................................................................
	#___ proc reset_r_frame {proofArray} _________________________________

	# clear canvas if it exists
	proc reset_r_frame {proofArray} {
	    create_local_vars proofArray
	    set p(selected_rule) {}
	    if [winfo exists $p(r_canvas)] {
		$p(r_canvas) delete all
	    }
	}

	#.....................................................................
	#___ proc rule_exists {proofArray rule_id} ___________________________

	proc rule_exists {proofArray rule_id} {
	    create_local_vars proofArray
	    return [llength [array names rules $rule_id]]
	}

	#.....................................................................
	#___ proc rulename {proofArray rule_id} ______________________________

	proc rulename {proofArray rule_id} {
	    create_local_vars proofArray
	    if [rule_exists p $rule_id] {
		return [lindex $rules($rule_id) 2]
	    } else {return ""}
	}

	#.....................................................................
	#___ proc proof_canvas {proofArray} __________________________________

	proc proof_canvas {proofArray} {
	    create_local_vars proofArray
	    return $p(p_canvas)
	}

	#.....................................................................
	#___ proc pack {proofArray args} _____________________________________

	proc pack {proofArray args} {
	    create_local_vars proofArray
	    uplevel pack $p(p_frame) $args
	}

	#.....................................................................
	#___ proc set_font {proofArray newfont} ______________________________

	proc set_font {proofArray newfont} {
	    create_local_vars proofArray
	    [namespace parent]::Util::CopyFont $newfont $p(font)
	    redraw p
	}
	
	#.....................................................................
    }
}
