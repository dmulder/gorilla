
# PWGprogress - a component of Password Gorilla
#
# ----------------------------------------------------------------------
#
# See the gorilla.tcl file for Password Gorilla copyright, authorship, and
# license information.
#
# This module authored by Richard Ellis <rellis@dp100.com>
# Copyright 2011 Richard Ellis
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# A copy of the GNU General Public License can be found in the file
# LICENSE.txt located in the same directory as gorilla.tcl.
# ----------------------------------------------------------------------

# this makes use of several 8.5 features, so make sure we are running at
# least 8.5
package require Tcl 8.5

package provide gorillaprogress 1.0.0

# 
# This module provides for a generic framework for text based feedback
# progress bars (generally label widgets) for Password Gorilla.  This
# encapsulates all the code related to handling the progress bars into one
# location, in a private namespace, and thereby simplifies the remainder of
# the Password Gorilla codebase.
#

namespace eval ::gorilla::progress {

	# Indicates if the sub-system has been initialized and is ready.
	variable active 0

	# Holds the pathname of the widget to update.
	variable win ""

	# Holds the unformatted message string to display in the widget on
	# update.  This will be passed through [format] to insert the
	# numerical progress percentage.
	variable message ""

	# Used to limit the number of "update idletask" calls to one every
	# 250ms
	variable lastupdate 0

	namespace ensemble create

	namespace path { ::tcl::mathop ::tcl::mathfunc }

	namespace export init update finished

} ; # end namespace eval ::gorilla::progress

#
# ----------------------------------------------------------------------
#

proc ::gorilla::progress::init { config } {

	# Initializes the progress subsystem for use.  

	validate $config

	variable win     [ dict get $config widget  ]
	variable message [ dict get $config message ]

	variable active 1
	variable lastupdate [ clock milliseconds ]

	$win configure -text [ format $message 0 ]

	return GORILLA_OK

	#ruff
	#
	# config - a dictionary containing at least the following keys: 
	#
	#   widget { the widget pathname to update }
	#   message { the unsubstituted message to insert into the widget }
	#
	# The message entry must contain one, and only one, %d format
	# substitution marker.  This will be replaced by the percent
	# complete as given in calls to the ::gorilla::progress::update
	# subcommand.
	#
	# Note, init simply utilizes the passed message string unaltered,
	# msgcat translations are outside the scope of this module and are
	# expected to be handled by the code calling init, not by this
	# module.

} ; # end proc ::gorilla::progress::init

#
# ----------------------------------------------------------------------
#

proc ::gorilla::progress::validate { config } {

	# Validates the contents of the passed dictionary to make sure it
	# contains required elements, and that the elements make sense.

	# validate widget key

	if { ! [ dict exists $config widget ] } {
		error "Required 'widget' key missing from dictionary."
	}

	if { ! [ winfo exists [ dict get $config widget ] ] } {
		error "Widget path [ dict get $config widget ] does not exist."
	}

	# validate message key

	if { ! [ dict exists $config message ] } {
		error "Required 'message' key missing from dictionary."
	}

	if { -1 == [ set i [ string first "%d" [ dict get $config message ] ] ] } {
		error "Message string does not contain a '%d' substitution."
	} elseif { -1 != [ string first "%d" [ dict get $config message ] $i+1 ] } {
		error "Message string contains more than one '%d' substitution, only a single occurrence allowed."
	}

	return GORILLA_OK

} ; # end proc ::gorilla::progress::validate

#
# ----------------------------------------------------------------------
#

proc ::gorilla::progress::active? {} {

	# tests for progress subsystem being in active state.  If not forces
	# calling proc to unconditionally return.

	variable active
	if { ! $active } {
		return -code return
	}

} ; # end proc ::gorilla::progress::active?

#
# ----------------------------------------------------------------------
#

proc ::gorilla::progress::update { value } {

	# called to update the configured progress bar with a new value

	active?

	# limit update rate to once every 250ms

	variable lastupdate
	if { [ - [ clock milliseconds ] $lastupdate ] < 250 } {
		return
	}

	if { ! [ string is double -strict $value ] } {
		error "progress update called with non-numeric value '$value'"
	}

	variable win
	variable message

	# limit the value to the integer range 0 ... 100

	set value [ max 0 [ min [ int $value ] 100 ] ]

	$win configure -text [ format $message $value ]

	set lastupdate [ clock milliseconds ]
	update idletasks

	#ruff
	#
	# value - the new value, can be integer or floating point, will be
	#         truncated to an integer and limited to the range 0 ... 
	#         100.

} ; # end proc ::gorilla::progress::update

#
# ----------------------------------------------------------------------
#

proc ::gorilla::progress::finished {} {

	# Sets progress subsystem state to inactive and clears message text
	# from the configured widget.

	active?

	variable active 0
	variable win
	$win configure -text ""
	set win ""

	return GORILLA_OK

} ; # end proc ::gorilla::progress::finished