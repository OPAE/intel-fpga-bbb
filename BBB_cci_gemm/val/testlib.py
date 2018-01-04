#!/usr/bin/python
#################
#
# testlib.py - regression test library
#
# all reusable code goes here
#
#    Copyright (C) 2013-2015 Intel Corporation All Rights Reserved.
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Library General Public
#    License as published by the Free Software Foundation; either
#    version 2 of the License.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Library General Public License for more details.
#
#    You should have received a copy of the GNU Library General Public
#    License along with this program.  If not, see
#    <http://www.gnu.org/licenses/>.
#

import subprocess, signal
import sys, unittest,  os, os.path
from random import choice, randrange, randint
import threading
from subprocess import PIPE
from time import time

"""
Variable and function definitions for timing
"""
TIMELOG = "times.log"
global LOG_TIMING
LOG_TIMING = None

global failures
failures = 0

def logger(command, time,  echo=False):
    if LOG_TIMING:
        if echo:
            print(command, time)
    log = open(TIMELOG, 'a')
    log.write(str(command) + ' : ' +  str(time) + '\n')
    log.close

def subprocess_setup():
    # Python installs a SIGPIPE handler by default. This is usually not what 
   # non-Python subprocesses expect.
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)


class TimedOutException(Exception):
    def __init__(self, value="Timed Out"):
        self.value = value

    def __str__(self):
        return repr(self.value)


# return a string from a list
def listless(myList, mySep):
        return mySep.join(str(x) for x in myList)

def rint(myList):
    if len(myList) <> 2: return -1 # only want 3 numbers, max
    mStart = myList[0]
    mStop = myList[1]
    return randint(mStart, mStop)

# return random beginning and ending values
def begin_end(start, stop, step):
    begin = 1
    end = 0
    while (begin >= end):
        begin = randrange(start, stop, step)
        end = randrange(start, stop, step)
    return begin, end

# Flip a coin
def cointoss():
    return(randint(0, 1))

# Find executable
def which(program):
    import os

    def is_exe(fpath):
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            path = path.strip('"')
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file

    return None

def get_csr(csr):
    args = []
    prog = which('csr')
    if not prog:
        prog = './csr'
    args = [prog,'read','%s' % csr]
    rc,result = cmd(args, 10).run()
    # handle errors
    if rc:
        print "Command: %s  returned error %s and %s output" % (listless([prog, args], ','), rc, result)
        exit(rc)
    # result looks like:
    #  CSR Rd32 0x208 ( 520) PCIE_FEATURE_HDR_QPI_CORE == 0x0f420003 ( 255983619)
    csr_vals = result
    print csr_vals
#    csr_vals = result.split()[result.split().index('==') + 1]
    return csr_vals

# Read temperature
def get_temp():
    # first, see if it is even enabled
    if (int(get_csr(0x454),16) &1):
        return (int(get_csr(0x458),16) & ~(1<<7)) # return 7-bit temp

# Determine capcm size
def get_capcm():
    result = []
    capcm_vals = {}
    capcm_en = '0x208'
    capcm_sz = '0x40c'
    size = 0
    # See if capcm is enabled (csr 0x208 [1:1] )
    if (int(get_csr(capcm_en),16) & 2):
        res = bin(int(get_csr(capcm_sz),16)).replace('0b','')
        # Python reads bitfield as a string (right>left).
        # 0x0000afaf in binary (bits 15:13 & 7:5 specifically)
        # Formula is Tot_mem = 2^([7:5]-1) + 2^([15:13]-1).  Don't worry if one controller.
        size = 2**(int(res[0:3], 2) -1) + 2**(int(res[8:11], 2) -1)
    return size


# Root Me!
def require_root():
    if os.geteuid() != 0:
        print >>sys.stderr, "This series of tests should be run with root privileges (e.g. via sudo)."
        sys.exit(255)


class cmd(object):
    def __init__(self, cmd, timeout = None ,stdin = None, stdout = PIPE,
                 stderr = PIPE):
        # command object attributes for running subprocess
        self.cmd = cmd
        self.stdin = stdin
        self.stdout = stdout
        self.stderr = stderr
        # timeout for the process if desired
        self.timeout = timeout
        # save seed for psuedorandom number - future feature
        self.time = None
        # subprocess that was executed by Popen
        self.process = None
        # maintain env
        self.env = os.environ.copy()
        # return values and out/err 
        self.output = None
        self.errors = None
        self.returncode = 0

    def run(self):
        def target():
            ts = time()
            self.process = subprocess.Popen(self.cmd, stdout = self.stdout, env=self.env, stderr = self.stderr, close_fds=True, preexec_fn=subprocess_setup)
            self.output, self.errors = self.process.communicate()
            self.returncode = self.process.returncode
            te = time()
            self.time = te-ts

        # create and start a new thread for subprocess
        thread = threading.Thread(target=target)
        thread.start()
        thread.join(self.timeout)
        # if the thread is still alive after the timeout, terminate.
        if thread.is_alive():
            print '\nTerminating process - Timeout of %d seconds reached.' % self.timeout
            self.process.terminate()
            thread.join()
            # overwrite return code for overly long process.
            self.returncode = 127
        #log time to complete subprocess function call.
        logger((self.cmd[0] + self.cmd[1]).strip(), self.time)
        return [self.returncode, str(self.output) + str(self.errors)]

class TestlibCase(unittest.TestCase):
    def __init__(self, *args):
        '''This is called for each TestCase test instance, which isn't much better
           than SetUp.'''
        unittest.TestCase.__init__(self, *args)

    def _testlib_shell_cmd(self,args, timeout, stdin=None, stdout=subprocess.PIPE, stderr=subprocess.STDOUT):
        argstr = "'" + "', '".join(args).strip() + "'"
        rc, out = cmd(args, timeout).run()
        report = 'Command: ' + argstr + '\nOutput:\n' + out
        return rc, report, out

    def assertShellExitEquals(self, expected, args, timeout, logging=False,  stdin=None, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, msg=""):
        global LOG_TIMING
        LOG_TIMING = logging
        '''Test a shell command matches a specific exit code'''
        rc, report, out = self._testlib_shell_cmd(args, stdin=stdin, stdout=stdout, stderr=stderr, timeout = timeout)
        result = 'Exit code: received %d, expected %d\n' % (rc, expected)
        self.assertEquals(expected, rc, msg + result + report)
