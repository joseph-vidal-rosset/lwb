if { [llength [namespace children [namespace current] Util]] == 0} {

    namespace eval Util {

	proc scrolled_widget { frame type args } {
	    if ![winfo exists $frame] {
		frame $frame
	    }

	    eval {$type $frame.$type  -xscrollcommand [list $frame.hscroll set] \
		    -yscrollcommand [list $frame.vscroll set] } $args
	    
	    scrollbar $frame.hscroll -orient horizontal\
		    -command [list $frame.$type xview]
	    scrollbar $frame.vscroll -orient vertical\
		    -command [list $frame.$type yview]
	    
	    pack $frame.hscroll -side bottom -fill x
	    pack $frame.vscroll -side right -fill y
	    pack $frame.$type -side left -fill both -expand true
	    return $frame.$type
	}

	proc scrolled_canvas { frame args } {
	    return [eval scrolled_widget $frame canvas $args]
	}

	proc scrolled_text { frame args } {
	    return [eval scrolled_widget $frame text $args]
	}

	proc h_scrolled_widget { frame type args } {
	    if ![winfo exists $frame] {
		frame $frame
	    }

	    eval {$type $frame.$type  -xscrollcommand [list $frame.hscroll set]} $args
	    
	    scrollbar $frame.hscroll -orient horizontal\
		    -command [list $frame.$type xview]
	    
	    pack $frame.hscroll -side bottom -fill x
	    pack $frame.$type -side left -fill both -expand true
	    return $frame.$type
	}

	proc h_scrolled_canvas { frame args } {
	    return [eval h_scrolled_widget $frame canvas $args]
	}

	proc h_scrolled_text { frame args } {
	    return [eval h_scrolled_widget $frame text $args]
	}

	# process the argument list setting the local variable x
	# for each option -x to the given value. The local
	# var must already exist in the caller's stack frame

	proc GetArgs {arglist} {
	    set n [llength $arglist]
	    for {set i 0} {$i < $n} {incr i} {
		set opt [lindex $arglist $i]
		set var [string range $opt 1 end]
		set arg [lindex $arglist [incr i]]
		if {[uplevel [list info exists $var]]} {
		    uplevel [list set $var $arg]
		} else {
		    error "invalid option: \"$opt\""
		}
	    }
	}

	# Creates message widget to notify the user in case of an error.
	# Returns 0.
	proc Error {msg} {
	    tk_dialog .error Error $msg {} 0 Ok
	}
	
	# Yes/No selection message widget. 
	# Returns 0 if No, 1 if Yes is chosen.
	proc YesNo {msg} {
	    tk_dialog .yesno {} $msg {} 0 No Yes
	}

	proc CheckWritable {filename} {
	    set dir [file dirname $filename]
	    set name [file tail $filename]
	    
	    if {[file exists $filename] && ![file writable $filename]} {
		::Util::Error "You are not allowed to overwrite \"$filename\"!"
		return 0
	    }
	    if {![file exists $filename] && ![file writable $dir]} {
		::Util::Error "You have no write permission in \"$dir\"!"
		return 0
	    }
	    return 1
	}

	proc CopyFont {src copy} {
	    if {[lsearch [font names] $copy] == -1} {
		set cmd create
	    } else {
		set cmd configure
	    }
	    font $cmd $copy -family [font actual $src -family]\
		    -size [font actual $src -size]\
		    -weight [font actual $src -weight]\
		    -slant [font actual $src -slant]\
		    -underline [font actual $src -underline]\
		    -overstrike [font actual $src -overstrike]
	}

	proc BusyOn {window} {
	    $window config -cursor watch
	    update idletasks
	}

	proc BusyOff {window} {
	    $window config -cursor {}
	    update idletasks
	}

    }
}