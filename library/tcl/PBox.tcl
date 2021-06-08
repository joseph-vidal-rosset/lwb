if { [llength [namespace children [namespace current] PBox]] == 0} {

    source [file join [file dirname [info script]] Utilities.tcl]

    namespace eval PBox {
	variable color color
	variable rotate yes
	variable colormap
	variable scale no
	variable canvas
	variable printCmd
	variable printToFile no
	variable filename proof_wish.ps
	variable frame
	
	proc CreateLocalVars {} {
	    uplevel variable color
	    uplevel variable rotate
	    uplevel variable colormap
	    uplevel variable scale
	    uplevel variable canvas
	    uplevel variable printCmd
	    uplevel variable printToFile
	    uplevel variable filename
	    uplevel variable frame
	}


	proc  PBox {iframe icanvas {iprintCmd {lpr}}} {
	    CreateLocalVars

	    set frame $iframe
	    set canvas $icanvas
	    set printCmd $iprintCmd

	    if [winfo exists $frame] {
		wm deiconify $frame
		grab $frame
		raise $frame
		return
	    }

	    toplevel $frame
	    bind $frame <Return> [namespace current]::ok
	    grab $frame

	    wm resizable $frame 0 0

	    pack [frame $frame.options -bd 5 -relief groove] \
		    -side top -fill x -expand 1

	    pack [label $frame.options.title -text "Postscript Options"] \
		    -side top -fill x -expand 1 -anchor center

	    pack [frame $frame.options.selections -bd 5] \
		    -side top -fill x -expand 1

	    pack [frame $frame.options.selections.color -bd 5] \
		    -side left -fill both -expand 1

	    pack [label $frame.options.selections.color.title \
		    -text "Color Mode"] \
		    [radiobutton $frame.options.selections.color.color \
		    -text "Color" \
		    -bd 3 \
		    -variable [namespace current]::color \
		    -value color] \
		    [radiobutton $frame.options.selections.color.gray \
		    -text "Gray-Scale" \
		    -bd 3 \
		    -variable [namespace current]::color \
		    -value gray] \
		    [radiobutton $frame.options.selections.color.mono \
		    -text "Black & White" \
		    -bd 3 \
		    -variable [namespace current]::color \
		    -value mono] \
		    -side top -anchor w
	    
	    # orientation frame
	    pack [frame $frame.options.selections.rotate -bd 5] \
		    -side left -fill both -expand 1
	    pack [label $frame.options.selections.rotate.title \
		    -text "Orientation"] \
		    [radiobutton $frame.options.selections.rotate.no \
		    -text "Portrait" \
		    -bd 3 \
		    -variable [namespace current]::rotate \
		    -value no] \
		    [radiobutton $frame.options.selections.rotate.yes \
		    -text "Landscape" \
		    -bd 3 \
		    -variable [namespace current]::rotate \
		    -value yes] \
		    -side top -anchor w

	    # scale frame in options frame
	    pack [frame $frame.options.scale -bd 5] \
		    -side top -fill x -expand 1
	    pack [checkbutton $frame.options.scale.yes \
		    -text "Scale to fill 1 Page" \
		    -bd 3 \
		    -variable [namespace current]::scale \
		    -onvalue yes \
		    -offvalue no] \
		    -side top -anchor c

	    pack [frame $frame.print -bd 5 -relief groove]\
		    -side top -fill x -expand 1
	    pack [frame $frame.print.cmd] \
		    -side top -fill x -expand 1
	    pack [radiobutton $frame.print.cmd.printer \
		    -text "Print Command:" \
		    -bd 3 \
		    -variable [namespace current]::printToFile \
		    -disabledforeground #777777\
		    -value no] \
		    -side left
	    pack [entry $frame.print.cmd.entry\
		    -textvariable [namespace current]::printCmd]\
		    -side left -fill x -expand 1

	    # print to file frame
	    pack [frame $frame.print.tofile] \
		    -side top -fill x -expand 1
	    pack [radiobutton $frame.print.tofile.file \
		    -text "Print to File:" \
		    -bd 3 \
		    -variable [namespace current]::printToFile \
		    -value yes \
		    -takefocus 1] \
		    -side left
	    pack [entry $frame.print.tofile.entry\
		    -textvariable [namespace current]::filename ]\
		    -side left -fill x -expand 1

	    pack [frame $frame.buttons -bd 5 -takefocus 1] \
		    -side top -fill x -expand 1
	    pack [button $frame.buttons.ok \
		    -text "OK" \
		    -width 6 \
		    -command "[namespace current]::ok" \
		    -highlightbackground black] \
		    [button $frame.buttons.cancel \
		    -text "Cancel" \
		    -width 6 \
		    -command "[namespace current]::cancel"] \
		    -side left -expand 1

	    trace variable [namespace current]::printToFile w \
		    [namespace current]::printToFileChanged
	    printToFileChanged
	}

	proc printToFileChanged {args} {
	    CreateLocalVars
	    if {"$printToFile" == "yes"} {
		$frame.print.cmd.entry config\
			-state disabled\
			-foreground #777777

		$frame.print.tofile.entry config\
			-state normal\
			-foreground black
	    } else {
		$frame.print.cmd.entry config\
			-state normal\
			-foreground black
		
		$frame.print.tofile.entry config\
			-state disabled\
			-foreground #777777
	    }
	}

	proc print {fd} {
	    CreateLocalVars

	    # try to fit on a page
	    scan [$canvas bbox all] "%d %d %d %d" x1 y1 x2 y2

	    set cmd [list $canvas postscript \
		    -colormode $color \
		    -x $x1 \
		    -y $y1 \
		    -width [expr $x2-$x1] \
		    -height [expr $y2-$y1] \
		    -rotate $rotate]

	    if {"$scale" == "yes"} {
		if {"$rotate" == "yes"} {
		    lappend cmd -pagewidth 29c -pageheight 20c
		} else {
		    lappend cmd -pagewidth 20c -pageheight 29c
		}
	    }

	    puts $fd [eval $cmd]
	}

	proc ok {} {
	    CreateLocalVars
	    if {"$printToFile" == "yes"} {
		if {"$filename" == ""} {
		    [namespace parent]::Util::Error "You must specify a file name!"
		    return
		}
		if ![[namespace parent]::Util::CheckWritable $filename] return
		if {[file exists $filename] && \
			![[namespace parent]::Util::YesNo "Overwrite existing file?"] } {
		    return
		}
		set fd [open $filename w]
	    } else {
		if {"$printCmd" == ""} {
		    [namespace parent]::Util::Error "You must specify a print command!"
		    return
		}
		if [catch {set fd [open "|$printCmd" w]}] {
		    bgerror "Error executing print command!"
		    return
		}
	    }
	    wm withdraw $frame
	    grab release $frame
	    print $fd
            close $fd
	}

	proc cancel {} {
	    CreateLocalVars
	    grab release $frame
	    wm withdraw $frame
	}
    }
}