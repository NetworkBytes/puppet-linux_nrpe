#!/bin/bash
#
# CPU load monitor plugin for Nagios
# Written by Thomas Sluyter (nagios@kilala.nl)
# By request of KPN-IS, i-Provide, the Netherlands
# Last Modified: 09-01-2013 - John Bencic, Added performance data
#
# Usage: ./check_load2
#
# Description:
#   Ethan's original version of the check_load script is very flexible.
# It allows you to specifically set WARN and CRIT levels regarding
# the CPU load of the system you're monitoring.
#   However: flexibility is not always a good thing. Say for example that
# you want to monitor the CPU load across a few hundred of systems having
# various CPU configurations. You -could- define host groups for single, dual
# quad (and so on) processor systems and assign unique check_load command
# definitions to each group.
#   Or you could write a script which checks the amount of active CPUs and
# then makes an educated guess at the WARN and CRIT levels for the system.
# In most cases this should really be enough.
#
# Limitations:
# This script should work properly on all implementations of Linux, Solaris
# and Mac OS X.
#
# Output:
# Depending on the levels defined at the top of the script,
# the script returns an OK, WARN or CRIT to Nagios based on CPU load.
#
# Other notes:
#   If you ever run into problems with the script, set the DEBUG variable
# to 1. I'll need the output the script generates to do troubleshooting.
# See below for details.
#   I realise that all the debugging commands strewn throughout the script
# may make things a little harder to read. But in the end I'm sure it was
# well worth adding them. It makes troubleshooting so much easier. :3
#

# You may have to change this, depending on where you installed your
# Nagios plugins
PATH="/usr/bin:/usr/sbin:/bin:/sbin"
LIBEXEC="/usr/lib64/nagios/plugins"
. $LIBEXEC/utils.sh


### DEBUGGING SETUP ###
# Cause you never know when you'll need to squash a bug or two
DEBUG="0"


### REQUISITE NAGIOS COMMAND LINE STUFF ###

print_usage() {
        echo "Usage: $PROGNAME"
        echo "Usage: $PROGNAME --help"
}

print_help() {
        echo ""
        print_usage
        echo ""
        echo "Semi-intelligent CPU load monitor plugin for Nagios"
        echo ""
        echo "This plugin not developped by the Nagios Plugin group."
        echo "Please do not e-mail them for support on this plugin, since"
        echo "they won't know what you're talking about :P"
        echo ""
        echo "For contact info, read the plugin itself..."
}

while test -n "$1"
do
        case "$1" in
          --help) print_help; exit $STATE_OK;;
          -h) print_help; exit $STATE_OK;;
          *) print_usage; exit $STATE_UNKNOWN;;
        esac
done


### SETTING UP THE WARN AND CRIT FACTORS ###
# Please be aware that these are -factors- and not real load average values.
# The numbers below will be multiplied by the amount of processors to come
# to the desired WARN and CRIT levels. Feel free to adjust these factors, if
# you feel the need to tweak them.

WARN_1min="2.00"
WARN_5min="1.50"
WARN_15min="1.50"
[ $DEBUG -gt 0 ] && echo "Factors: warning factors are at $WARN_1min, $WARN_5min, $WARN_15min."

CRIT_1min="3.00"
CRIT_5min="2.00"
CRIT_15min="2.00"
[ $DEBUG -gt 0 ] && echo "Factors: critical factors are at $CRIT_1min, $CRIT_5min, $CRIT_15min."


### DEFINING SUBROUTINES ###

function gather_procs_linux()
{
    NUMPROCS=`cat /proc/cpuinfo | grep ^processor | wc -l`
    [ $DEBUG -gt 0 ] && echo "Numprocs: Number of processors detected is $NUMPROCS."
}

function gather_procs_sunos()
{
    NUMPROCS=`/usr/bin/mpstat | grep -v CPU | wc -l`
    [ $DEBUG -gt 0 ] && echo "Numprocs: Number of processors detected is $NUMPROCS."
}

function gather_procs_darwin()
{
    NUMPROCS=`/usr/bin/hostinfo | grep "Default processor set" | awk '{print $8}'`
    [ $DEBUG -gt 0 ] && echo "Numprocs: Number of processors detected is $NUMPROCS."
}

function gather_load_linux()
{
    REAL_1min=`cat /proc/loadavg | awk '{print $1}'`
    REAL_5min=`cat /proc/loadavg | awk '{print $2}'`
    REAL_15min=`cat /proc/loadavg | awk '{print $3}'`
    [ $DEBUG -gt 0 ] && echo "Gather_load: Detected load averages are $REAL_1min, $REAL_5min, $REAL_15min."
}

function gather_load_sunos()
{
    REAL_1min=`w | grep "load average" | awk -F, '{print $4}' | awk '{print $3}'`
    REAL_5min=`w | grep "load average" | awk -F, '{print $5}'`
    REAL_15min=`w | grep "load average" | awk -F, '{print $6}'`
    [ $DEBUG -gt 0 ] && echo "Gather_load: Detected load averages are $REAL_1min, $REAL_5min, $REAL_15min."
}

function gather_load_darwin()
{
    REAL_1min=`sysctl -n vm.loadavg | awk '{print $1}'`
    REAL_5min=`sysctl -n vm.loadavg | awk '{print $2}'`
    REAL_15min=`sysctl -n vm.loadavg | awk '{print $3}'`
    [ $DEBUG -gt 0 ] && echo "Gather_load: Detected load averages are $REAL_1min, $REAL_5min, $REAL_15min."
}

function check_load()
{
    WARN="0"; CRIT="0"

    [ `echo "if(($NUMPROCS * $WARN_1min)  > $REAL_1min)  0; if(($NUMPROCS * $WARN_1min)  <= $REAL_1min)  1" | bc` -gt 0 ] && let WARN=$WARN+1
    [ `echo "if(($NUMPROCS * $WARN_5min)  > $REAL_5min)  0; if(($NUMPROCS * $WARN_5min)  <= $REAL_5min)  1" | bc` -gt 0 ] && let WARN=$WARN+1
    [ `echo "if(($NUMPROCS * $WARN_15min) > $REAL_15min) 0; if(($NUMPROCS * $WARN_15min) <= $REAL_15min) 1" | bc` -gt 0 ] && let WARN=$WARN+1
    [ $DEBUG -gt 0 ] && echo "Check_load: warning levels are `echo "$NUMPROCS * $WARN_1min"|bc`, `echo "$NUMPROCS * $WARN_5min"|bc`, `echo "$NUMPROCS * $WARN_15min"|bc`,"

    [ `echo "if(($NUMPROCS * $CRIT_1min)  > $REAL_1min)  0; if(($NUMPROCS * $CRIT_1min)  <= $REAL_1min)  1" | bc` -gt 0 ] && let CRIT=$CRIT+1
    [ `echo "if(($NUMPROCS * $CRIT_5min)  > $REAL_5min)  0; if(($NUMPROCS * $CRIT_5min)  <= $REAL_5min)  1" | bc` -gt 0 ] && let CRIT=$CRIT+1
    [ `echo "if(($NUMPROCS * $CRIT_15min) > $REAL_15min) 0; if(($NUMPROCS * $CRIT_15min) <= $REAL_15min) 1" | bc` -gt 0 ] && let CRIT=$CRIT+1
    [ $DEBUG -gt 0 ] && echo "Check_load: critical levels are `echo "$NUMPROCS * $CRIT_1min"|bc`, `echo "$NUMPROCS * $CRIT_5min"|bc`, `echo "$NUMPROCS * $CRIT_15min"|bc`,"

    echo "load averages are at $REAL_1min, $REAL_5min, $REAL_15min| \
1min=$REAL_1min, \
5min=$REAL_5min, \
15min=$REAL_15min, \
PerProc1min=$(echo "scale=2; ($REAL_1min/$NUMPROCS)*100" | bc) \
PerProc5min=$(echo "scale=2; ($REAL_5min/$NUMPROCS)*100" | bc) \
PerProc15min=$(echo "scale=2; ($REAL_15min/$NUMPROCS)*100" | bc)"

echo "Number of Procs: $NUMPROCS"



#    if [ $CRIT -gt 0 ]; then
#      exit $STATE_CRITICAL
#    fi

#    if [ $WARN -gt 0 ]; then
#      exit $STATE_WARNING
#    fi

    # we should be ok
    exit $STATE_OK
}

### FINALLY, THE MAIN ROUTINE ###

NUMPROCS="0"

case `uname` in
            Linux) gather_procs_linux; gather_load_linux; check_load;;
            Darwin) gather_procs_darwin; gather_load_darwin; check_load;;
            SunOS) gather_procs_sunos; gather_load_sunos; check_load;;
            *) echo "OS not supported by this check."; exit 1;;
esac

exit $STATE_UNKNOWN



