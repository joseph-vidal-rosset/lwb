#!../../bin/lwbproof_wish -f
# -*- mode: tcl; -*-

###############################################################################
#
# Stuff concerning the window manager
#

# set the application name so that resources are read from the correct 
# database
tk appname lwbproof_wish

wm title . "LWBproof_wish"
wm minsize . 1 1
wm maxsize . [expr [winfo screenwidth .]-20] [expr [winfo screenheight .]-20]

###############################################################################
#
# sourcing necessary files
#

source [file join [file dirname [info script]] Proof.tcl]
source [file join [file dirname [info script]] Utilities.tcl]
source [file join [file dirname [info script]] PBox.tcl]
source [file join [file dirname [info script]] FBox.tcl]

###############################################################################
#
# Reading X resource databases
#

#
# Procedure to read a resource datafile
#
proc ReadXresource { file } {
  if [file exists $file] {
    if [catch {option readfile $file} err] {
      puts stderr "Error in $file: $err"
    }
  }
}

#
# Read the recource datafiles.
# If a file named .xlwb exists in the current as well as in the home
# directory only the one in the current directory is read.
#
option clear
if [file exists .xlwb] {
  ReadXresource .xlwb
} else {
  ReadXresource ~/.xlwb
}

###############################################################################
#
# Create the widgets used at startup and the global variables
#
# Global Variables:
#   proof:       IncrTcl object holding the proof
#   proofcanvas: canvas widget in proof object
#   printdialog: IncrTcl widget for printing
#   sfcolor:     variable used in the menu "Options"
#   layout:      variable used in the menu "Options"
#   status:      label widget showing status like "resetting", "loading",...
#   infowindow:  frame widget for proof info
#   info:        text widget holding proof info
#   


# create proof array
::Proof::create proof .proof

# Canvas widget of proof
set proofcanvas [::Proof::proof_canvas proof]

# IncrTcl object for printing
set printdialog .printdialog

# path to toplevel widget for fontbox
set fontbox .fontbox

# menu of root window .
menu .menu -type menubar
. config -menu .menu

#
# Create File Menu
#

if [expr {"$tcl_platform(platform)" == "macintosh" } ] {
  set filetypes {
      {{Proof Wish Files} {*} {"PWTx"}}
      {{All Files}         *             }
  }
} else {
  set filetypes {
      {{Proof Wish Files} {.pwf} {"PWTx"}}
      {{All Files}         *             }
  }
}

set fileMenu [menu .menu.file -type normal -tearoff 0]
$fileMenu add command -label Save... -command {
    SaveProof [tk_getSaveFile \
	    -title "Save Proof" \
	    -filetypes $filetypes \
	    -defaultextension .pwf]
}
$fileMenu add command -label Load... -command {
    LoadProof [tk_getOpenFile \
	    -title "Load Proof" \
	    -filetypes $filetypes]
}
$fileMenu add command -label Print... -command {PrintProof}
$fileMenu add command -label Exit -command exit
.menu add cascade -label File -menu $fileMenu
unset fileMenu

#
# Global variables used in Options Menu
#
set sfcolor blue
Proof::highlight_sf proof $sfcolor
set layout premise_first
Proof::set_layout proof $layout

#
# Create and pack Options menu
#
set optionsMenu [menu .menu.options -type normal -tearoff 0]
$optionsMenu add checkbutton -label "Proof info"\
    -variable showinfo -offvalue off -onvalue on\
    -command {InfoDisplay $showinfo}
$optionsMenu add checkbutton -label "Axioms on top"\
    -variable layout -offvalue conclusion_first -onvalue premise_first\
    -command {::Proof::set_layout proof $layout}
$optionsMenu add checkbutton -label "Highlight side formulae"\
    -variable sfcolor -offvalue black -onvalue blue\
    -command {::Proof::highlight_sf proof $sfcolor}
$optionsMenu add command -label "Proof font..."\
    -command {ChangeFont}
.menu add cascade -label Options -menu $optionsMenu
unset optionsMenu


.menu add cascade -label Proof -menu $proof(popupmenu)

# Create and pack status label on bottom of mainwindow
set status [label .status -foreground red]
pack $status -side bottom -fill x -anchor w

# Pack proof widget
::Proof::pack proof -fill both -expand true

# finish packing and drawing
update idletasks

# Create frame widget holding info text and it's scale
set infowindow .info
set info [::Util::scrolled_text $infowindow -wrap none -width 40 -height 6]

###############################################################################
#
# Procedures
#

# Procedures used to change the shape of the cursor.
# These procedures have been moved to Util.tcl, the procedures here are still
# used by the LWB

proc busy_on {} {Util::BusyOn .}
proc busy_off {} {Util::BusyOff .}

# Writes given message into the status line
proc Status {msg} {
    global status
    $status config -text $msg
    update idletasks
}

# Save shown proof in given file.
# Returns the given filename if the proof was written, nothing otherwise.
proc SaveProof {filename} {
    global proof tcl_platform

    if {$filename == ""} return

    if ![Util::CheckWritable $filename] return

    busy_on
    Status "Saving $filename"
    ::Proof::save proof $filename
    if { "$tcl_platform(os)" == "MacOS" } {
        file attributes $filename -creator "PrWi" -type "PWTx"
    }
    Status ""
    busy_off
    return $filename
}

# Load shown proof in given file.
# Returns the given filename if the proof was written, nothing otherwise.
proc LoadProof {filename} {
    global proof

    if {$filename == ""} return

    if ![file readable $filename] {
	::Util::Error "You are not allowed to read \"$filename\"!"
	return
    }

    ::Proof::reset proof
    Status "Loading [file tail $filename]"
    busy_on
    if [catch {source $filename}] {
	Status ""
	busy_off
	bgerror "Error loading $filename"
    }
    create_subproofs
    Status ""
    busy_off
    return $filename
}

# Creates a dialog window for printing the shown proof.
proc PrintProof {} {
    global printdialog
    global proofcanvas
    if [winfo exists $printdialog] {
	wm deiconify $printdialog
	raise $printdialog
    } else {
	PBox::PBox $printdialog $proofcanvas
    }
}

proc ChangeFont {} {
    global proof fontbox
    set font [FBox::FBox $fontbox $proof(font)]
    if {"$font" != ""} {
	busy_on
	Status "Changing proof font"
	Proof::set_font proof $font
	Status ""
	busy_off
    }
}

# Writes the info in the proof widget to the info window.
proc UpdateInfo {} {
    global proof infowindow info

    if [winfo exists $infowindow] {
	$info config -state normal
	$info delete 1.0 end
	$info insert 1.0 $proof(infotext)
	$info config -state disabled
    }
}

# Hides or shows info window.
proc InfoDisplay {onoff} {
    global info infowindow status

    # only do something if argument is either "on" or "off
    if {$onoff != "on" && $onoff != "off"} return

    set h [winfo height .]
    set w [winfo width .]
    set x [winfo x .]
    set y [winfo y .]

    if {$onoff == "on"} {
	UpdateInfo
	set h [expr $h + [winfo reqheight $infowindow]]
	pack $infowindow -side bottom -fill both -expand 0 -before $status
    } else {
	set h [expr $h - [winfo height $infowindow]]
	pack forget $infowindow
    }
    wm geometry . ${w}x${h}+${x}+${y}
}

###############################################################################
#
# commands passed to proof widget
#

proc add_node {args} {
    global proof
    Status "node [lindex $args 1] added"
    set r [eval ::Proof::add_node proof $args]
    return r
}

proc add_rule {args} {
    global proof
    Status "adding rules"
    set r [eval ::Proof::add_rule proof $args]
    Status ""
    return r
}

proc reset_info {args} {
    global proof
    Status "resetting info"
    eval ::Proof::reset_info proof $args
    UpdateInfo
    Status ""
}

proc append_info {args} {
    global proof
    Status "appending info"
    eval ::Proof::append_info proof $args
    UpdateInfo
    Status ""
}

proc reset_proof {} {
    global proof
    Status "resetting proof"
    Proof::reset proof
    Status ""
}

proc redraw_proof {} {
    global proof
    Status "redrawing proof"
    Proof::redraw proof
    Status ""
}

proc create_subproofs {} {
    global proof
    Status "drawing"
    Proof::create_subproofs proof {}
    Status ""
}

# procedure used for the macintosh
# If the application receives an "open document" event, this function is called
# to handle the event.
proc tkOpenDocument {args} {
    raise .
    set file [lindex $args 0]
    LoadProof $file
    if [expr [string first "proof_wish_tmp.pwf" $file] >= 0] {
      file delete $file
    }
}

###############################################################################
#
# Actions performed if an argument is given
#

if {[llength $argv] != 0} {
# check if commands are read from standard input
# if not load proof of given file
    if {[lindex $argv 0] != "-"} {
	LoadProof [lindex $argv 0]
    }
}
