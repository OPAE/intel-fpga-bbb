#!/usr/bin/python
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License version 2,
#    as published by the Free Software Foundation.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

import testlib, subprocess, os, getopt, sys
import unittest, argparse, pdb, csv
from random import choice, randrange
from unittest.runner import TextTestResult
TextTestResult.getDescription = lambda _, test: str(test.shortDescription())

########################
## USER MODIFIED AREA ##
########################

## Set your program name
prog_name = 'gemm'
prog = testlib.which(prog_name) or testlib.which('../sw/sample/' + prog_name) or exit('Error: ' + prog_name + ' not found')

## Choose to enable DEBUG
DEBUG = 0 

## Log Timing?
logTiming = False

## Test parameters
basedoc = 'GEMM'


###################################
## DO NOT MODIFY BELOW THIS LINE ##
###################################


# Define the test class - this is the heart of the program
class InitFPGATest(testlib.TestlibCase):
    '''Main Test'''
    def setUp(self):
        '''Set up prior to each test_* function'''
        # Prepare for per-test teardowns
        self.teardowns = []

    def tearDown(self):
        '''Clean up after each test_* function'''
        # Handle per-test teardowns
        global failures
        #failures = self.currentResult.failures
        for func in self.teardowns:
            func()

    def runner(self, params, timeout=None):
        '''Run each test'''
        if DEBUG:
            print "\nCmd: %s" % testlib.listless(params, ' ')
        self.assertShellExitEquals(0, params, timeout, logging=logTiming)

# Function to add a tests to the stack
def _add_test(name, doc, param, time=None):
    def test_method(self):
        self.runner(params=param, timeout=time)
    setattr(InitFPGATest, 'test_' + name, test_method)
    test_method.__name__ = 'test_' + name
    test_method.__doc__ = doc


# Function to remove tests from the stack
def _remove_test(cls):
    for name in list(vars(cls)):
        if name.startswith("test_") and callable(getattr(cls, name)):
            delattr(cls, name)

def build_tests(tests):
    for test in tests:
        test()
    res = unittest.main(verbosity=2, exit=False, catchbreak=True, argv=['']).result
    _remove_test(InitFPGATest)
    return res

def parse_interleave(inter_str):
    # Check string starts with [
    if not inter_str[1] == '[':
        print "Expected '[' got %s" % inter_str[1]
        sys.exit(1)
   
    # Check string ends with ] 
    if not inter_str[-1] == ']':
        print "Expected '[' got %s" % inter_str[-1]
        sys.exit(1)

    out_list = []
    # Now split over the spaces...
    val_list = inter_str[2:-1].split(" ")
   
    for val in val_list:
        # First check to see if it is a digit
        if val.isdigit():
            # If it is a digit then add it to the out_list
            out_list.append(int(val))
        else:
            # If it isn't a digit then we need to check if it is a range
            if '-' in val:
                # this is a range now we need to check that both the start and end values are digits
                val_nums = val.split("-")
                num_check = all([x.isdigit() for x in val_nums])
                if not num_check:
                    print "Expected all digits got %s" % val_nums
                    sys.exit(1)
                else:
                    for x in xrange(int(val_nums[0]), int(val_nums[1])+1):
                        out_list.append(x)

            else:
                print "Expected Range (e.g 4-16) got %s" % val
                sys.exit(1)
    return out_list

def main(argv):
    gmode = "FP32"
    inputfile = ''
    try:
        opts, args = getopt.getopt(argv, "h:g:i:", ["ifile=","ofile="])
    except getopt.GetoptError:
        print 'validate.py file: -g <mode> -i <inputfile>'
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print 'validate.py -g <mode> file: -i <inputfile>'
            print " This is a helper file for running validation"
            print " Input a file to perform validation across"
            print " The file must follow this format:"
            print "    <A_ROWS>, <B_COLS>, <COMMON>, <A_INTERLAVE>, <B_INTERLEAVE>, <F_INTERLEAVE>, <CHECK_MODE>"
            print ""
            print " INTERLEAVE can be specified as a range, examples are:"
            print "    320, 512, 128, [8-16], [16-32], [2-4], Exact"
            print "    320, 512, 128, [4 7 8-16], [16-18 20 23-26], [2], MKL"
            print " NOTE: do NOT use ',' in the ranges, use a ' '(space)"
            print ""
            print " CHECK_MODE must be one of the following options:"
            print "    None  : The results of the calculation are not checked"
            print "    Exact : The results of the calculation are checked for an exact match"
            print "    MKL   : The results of the calculation are checked against the MKL calculations"
            print " NOTE: The MKL check mode requires the gemm executable to be compiled with MKL enabled"
            print ""
            print "   -g   GEMM Mode: FP32 | FXD8      (default: FP32)" 
            print "   -i   Desired input file          (default: N/A - REQUIRED)" 
            print ""
            print " There are currently a few conditions on A_INTERLEAVE, B_INTERLEAVE and F_INTERLEAVE:"
            print "    1. A_INTELREAVE and B_INTLEREAVE must be less than or equal to 32"
            print "    2. 50 < A_INTELREAVE*B_INTLEREAVE <= 1024"
            print "    3. F_INTERLEAVE must be even"
            print " The script will handle all of those case silently, the exact test case will be printed for each run."
            print ""
            sys.exit()
        elif opt in ("-g"):
            if arg in ("FP32"):
              gmode = "FP32"
            elif arg in ("FXD8"):
              gmode = "FXD8"
        elif opt in ("-i", "--ifile"):
            inputfile = arg

    cases = []

    # Check if the File Exists
    if not os.path.exists(inputfile):
        print "File doesn't exist..."
        sys.exit(1)

    # Figure out Mode
    print "GEMM Mode : ", gmode
    print "Input file: ", inputfile
    with open(inputfile, "r+") as csvfile:
        matrix_reader = csv.reader(csvfile, delimiter=",")
        for row in matrix_reader:
            cases.append([row[0], row[1], row[2], row[3], row[4], row[5], row[6]])


    # This is where we will generate the test cases.
    # We are going to generate a list of tuples that we just iterate through.
    # Each tuple is going to contain a single test case.
    # tuple format: (A_ROW, B_COL, COMMON, A_INTER, B_INTER, F_INTER, CHECK_MODE)
    # ie, input file: <320, 512, 128, [8 9], 32, 16, Exact> will become 2 tuples:
    #    1. 320, 512, 128, 8, 32, 16, Exact
    #    2. 320, 512, 128, 9, 32, 16, Exact

    tests = []

    for conf in cases:
        a_interleave = parse_interleave(conf[3])
        b_interleave = parse_interleave(conf[4])
        f_interleave = parse_interleave(conf[5])

        # For now we only want to even numbers of f_interleave
        f_interleave = [x for x in f_interleave if (x%2 == 0)]

        # Now we generate the tests
        for a_inter in a_interleave:
            for b_inter in b_interleave:
                for f_inter in f_interleave:
                    # A few conditions to check...
                    min_check = a_inter * b_inter > 50
                    max_check = a_inter * b_inter < 1025
                    a_check = (a_inter > 1) and (a_inter < 33)
                    b_check = (b_inter > 1) and (b_inter < 33)
                    f_check = (f_inter > 0) and (f_inter < 17)
                    if (min_check and max_check and a_check and b_check and f_check):
                        tests.append((conf[0], conf[1], conf[2], a_inter, b_inter, f_inter, conf[6])) 

    print "Tests: ", len(tests)
    print "------------------------------------------"
    print ""

    def run_test_list():
        test_num = 1
        for test in tests:
            cmdline0 = "%s" % (gmode) 
            cmdline1 = " %s" % (test[0]) 
            cmdline2 = " %s" % (test[1]) 
            cmdline3 = " %s" % (test[2]) 
            cmdline4 = " %s" % (test[3]) 
            cmdline5 = " %s" % (test[4]) 
            cmdline6 = " %s" % (test[5]) 
            cmdline7 = " %s" % (test[6]) 
            cmdline8 = "--is-hw"
            fullcmd = "./gemm " + cmdline0 + cmdline1 + cmdline2 + cmdline3 + cmdline4 + cmdline5 + cmdline6 + cmdline7 + " " + cmdline8
            name = "sys_gemm_%03d" % test_num
            doc = "%s Test(%s):\t%s" % (basedoc, fullcmd, test_num)
            _add_test(name, doc, [prog, cmdline0, cmdline1, cmdline2, cmdline3, cmdline4, cmdline5, cmdline6, cmdline7, cmdline8])
            test_num += 1
    return build_tests([run_test_list])

if __name__ == '__main__':
    main(sys.argv[1:])
