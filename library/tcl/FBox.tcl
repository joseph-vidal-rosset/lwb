if { [llength [namespace children [namespace current] FBox]] == 0} {
    
    source [file join [file dirname [info script]] Utilities.tcl]
    
    namespace eval FBox {
	
	variable family
	variable size
	variable weight
	variable slant
	variable font {}

	variable sizeList {6 8 9 10 11 12 14 16 18 20 24 28 36}

	variable sizes;			      # maps family to list of sizes

	variable frame
	variable weightFrame
	variable slantFrame
	variable sizeMenu

	variable ok
	variable checkSizes  0
	variable checkWeight 1
	variable checkSlant  1
	
	
	proc createLocalVars {} {
	    uplevel variable family
	    uplevel variable size
	    uplevel variable weight
	    uplevel variable slant
	    uplevel variable font
	    
	    uplevel variable sizeList
	    
	    uplevel variable sizes; 	      # maps family to list of sizes

	    uplevel variable frame
	    uplevel variable weightFrame
	    uplevel variable slantFrame
	    uplevel variable sizeMenu
	    uplevel variable ok
	    uplevel variable checkSizes
	    uplevel variable checkWeight
	    uplevel variable checkSlant
	}
	
	proc FBox {f {infont {}}} {
	    createLocalVars
	    if [winfo exists $f] {
		if {$infont != {}} {copyFont $infont}
		wm deiconify $f
		grab $frame
		raise $f
	    } else {
		set frame $f
		wm withdraw [toplevel $frame]
		grab $frame
		if {$font == ""} {
		    set font fbox_font
		    font create fbox_font
		    setFontAttr
		}
		calcSizes $family
		createGUI
		if {$infont != {}} {copyFont $infont}
		newFamily
		wm deiconify $frame
		raise $frame
	    }
	    bind $frame <Destroy> "destroy %W; set [namespace current]::ok 0"
	    tkwait variable [namespace current]::ok
	    grab release $frame
	    return [expr {$ok ? $font : ""}]
	}

	proc copyFont {infont} {
	    createLocalVars
	    [namespace parent]::Util::CopyFont $infont $font
	    setFontAttr
	}

	proc setFontAttr {} {
	    createLocalVars
	    foreach x {slant weight size family} {
		set $x [font actual $font -$x]
	    }
	}

	proc calcSizes {fam} {
	    createLocalVars
	    if $checkSizes {
		set sizes($fam) {}
		set tmpfont [font create]
		foreach s $sizeList {
		    set valid 0
		    foreach w {normal bold} {
			foreach sl {roman italic} {
			    font configure $tmpfont\
				    -family $fam\
				    -size $s\
				    -weight $w\
				    -slant  $sl
			    
			    if { $s   == [font actual $tmpfont -size  ] } {
				set valid 1
			    }
			    if $valid break
			}
			if $valid break
		    }
		    if $valid {
			lappend sizes($fam) $s
		    }
		}
		font delete $tmpfont
	    } else {
		set sizes($fam) $sizeList
	    }
	}

	proc newFamily {args} {
	    createLocalVars
	    [namespace parent]::Util::BusyOn $frame
	    if {[lsearch -exact [array names sizes] $family] == -1} {
		calcSizes $family
	    }
	    if $checkSizes {
		set slist $sizes($family)
		if {[lsearch -exact $slist $size] == -1} {
		    if {$size < [lindex $slist 0]} {
			set size [lindex $slist 0]
		    } elseif {$size > [lindex $slist end]} {
			set size [lindex $slist end]
		    } else {
			foreach s $slist {
			    if {$s <= $size} {
				set inf $s
			    }
			    if {$s >= $size} {
				if {[expr $size - $inf] <= [expr $s - $size]} {
				    set size $inf
				} else {
				    set size $s
				}
			    }
			}
		    }
		} else {
		    # needed to verify slant and weight
		    set size [set size]
		}
		updateSizeOptionMenu $slist
	    } else {
		# needed to verify slant and weight
		set size [set size]
	    }
	    font configure $font -family $family
	    [namespace parent]::Util::BusyOff $frame
	}


	proc updateSizeOptionMenu {slist} {
	    createLocalVars
	    set m $sizeMenu
	    set last [$m index last]
	    for {set i 0} {[expr $i <= $last]} {incr i} {
		set msize [$m entrycget $i -label]
		if {[lsearch -exact $slist $msize] == -1} {
		    $m entryconfigure $i -state disabled
		} else {
		    $m entryconfigure $i -state normal
		}		
	    }
	}

	proc newSize {args} {
	    createLocalVars
	    [namespace parent]::Util::BusyOn $frame
	    if $checkWeight {
		set tmpfont [font create -family $family -size $size]
		$weightFrame.bold configure -state normal
		foreach w {normal bold} {
		    font configure $tmpfont -weight $w
		    if { $w != [font actual $tmpfont -weight] } {
			$weightFrame.bold configure -state disabled
			if {$w == $weight} {
			    toggleWeight
			}
		    }
		}
		set weight [set weight]
		font delete $tmpfont
	    }
	    font configure $font -size $size
	    [namespace parent]::Util::BusyOff $frame
	}

	proc newWeight {args} {
	    createLocalVars
	    [namespace parent]::Util::BusyOn $frame
	    if $checkSlant {
		set tmpfont [font create -family $family -size $size -weight $weight]
		$slantFrame.italic configure -state normal
		foreach sl {roman italic} {
		    font configure $tmpfont -slant $sl
		    if { $sl != [font actual $tmpfont -slant] } {
			$slantFrame.italic configure -state disabled
			if {$sl == $slant} toggleSlant
		    }
		}
		font delete $tmpfont
	    }
	    font configure $font -weight $weight
	    [namespace parent]::Util::BusyOff $frame
	}

	proc newSlant {args} {
	    createLocalVars
	    font configure $font -slant $slant
	}

	proc toggleSlant {} {
	    createLocalVars
	    if {$slant == "roman"} {
		set slant italic
	    } else {
		set slant roman
	    }
	}

	proc toggleWeight {} {
	    createLocalVars
	    if {$weight == "normal"} {
		set weight bold
	    } else {
		set weight normal
	    }
	}

	proc createGUI {} {
	    createLocalVars
	    wm title $frame {Font browser}
	    wm resizable $frame 0 0
	    set bd 3
	    set fontFrame [frame $frame.font -bd $bd]
	    pack $fontFrame -side top -fill x -expand 0

	    eval tk_optionMenu $fontFrame.family [namespace current]::family [lsort [font families]]
	    pack $fontFrame.family -side left -fill x -expand 1
	    set sizeMenu [eval tk_optionMenu $fontFrame.size [namespace current]::size $sizes($family)]
	    pack $fontFrame.size -side left -fill x -expand 0

	    set styleFrame [frame $frame.style -bd $bd]
	    pack $styleFrame -side top -fill x -expand 0

	    set weightFrame [frame $styleFrame.weight]
	    pack $weightFrame -side left -fill x -expand 1
	    pack [checkbutton $weightFrame.bold\
		    -variable [namespace current]::weight\
		    -offvalue normal\
		    -onvalue bold\
		    -text Bold\
		    -anchor w]\
		    -side top\
		    -fill x\
		    -expand 1

	    set slantFrame [frame $styleFrame.slant]
	    pack $slantFrame -side left -fill x -expand 1
	    pack [checkbutton $slantFrame.italic\
		    -variable [namespace current]::slant\
		    -offvalue roman\
		    -onvalue italic\
		    -text Italic\
		    -anchor w]\
		    -side top\
		    -fill x\
		    -expand 1

	    
	    frame $frame.txt -bd $bd
	    set text [[namespace parent]::Util::h_scrolled_text $frame.txt\
		    -height 3\
		    -width 10\
		    -wrap none\
		    -font $font]
	    pack $frame.txt -side top -fill both -expand 1

	    $text insert end "THE QUICK BOWN FOX JUMPS OVER THE LAZY DOG.\n"
	    $text insert end "the quick bown fox jumps over the lazy dog.\n"
	    $text insert end "0123456789"
		
	    trace variable [namespace current]::family w [namespace current]::newFamily
	    trace variable [namespace current]::size   w [namespace current]::newSize
	    trace variable [namespace current]::weight w [namespace current]::newWeight
	    trace variable [namespace current]::slant  w [namespace current]::newSlant
	    
	    pack [frame $frame.btn -bd $bd] \
		    -side top -fill x -expand 0
	    pack [button $frame.btn.quit\
		    -text OK\
		    -command "set [namespace current]::ok 1; wm withdraw $frame"\
		    -width 6]\
		    [button $frame.btn.cancel\
		    -text Cancel\
		    -command "set [namespace current]::ok 0; wm withdraw $frame"\
		    -width 6]\
		    -side left -expand 1
	}
    }
}