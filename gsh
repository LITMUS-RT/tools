#!/usr/bin/env python
#
# Copyright (c) 2008, Bjoern B. Brandenburg <bbb [at] cs.unc.edu>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the copyright holder nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS  PROVIDED BY THE COPYRIGHT HOLDERS  AND CONTRIBUTORS "AS IS"
# AND ANY  EXPRESS OR  IMPLIED WARRANTIES, INCLUDING,  BUT NOT LIMITED  TO, THE
# IMPLIED WARRANTIES  OF MERCHANTABILITY AND  FITNESS FOR A  PARTICULAR PURPOSE
# ARE  DISCLAIMED. IN NO  EVENT SHALL  THE COPYRIGHT  OWNER OR  CONTRIBUTORS BE
# LIABLE  FOR   ANY  DIRECT,  INDIRECT,  INCIDENTAL,   SPECIAL,  EXEMPLARY,  OR
# CONSEQUENTIAL  DAMAGES  (INCLUDING,  BUT   NOT  LIMITED  TO,  PROCUREMENT  OF
# SUBSTITUTE  GOODS OR SERVICES;  LOSS OF  USE, DATA,  OR PROFITS;  OR BUSINESS
# INTERRUPTION)  HOWEVER CAUSED  AND ON  ANY  THEORY OF  LIABILITY, WHETHER  IN
# CONTRACT,  STRICT  LIABILITY, OR  TORT  (INCLUDING  NEGLIGENCE OR  OTHERWISE)
# ARISING IN ANY  WAY OUT OF THE USE  OF THIS SOFTWARE, EVEN IF  ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

import sys
import os
import readline

HISTFILE   = '.gsh_history'

EGREP      = 'grep'
STD_ARGS   = ['-n', '--color', '-P']

VERSION    = "V0.1"
HELP       = """
Enter a regular expression to display lines that match the entered expression. 
Enter ^D or ^C at the prompt to terminate gsh. If a search produces too many 
results, then you can enter ^C to abort the search and return to the search
prompt.

For example, enter 'foo' to display lines containing the string 'foo'.
"""
COLS = 80

class HistFile(object):
	def __init__(self, file):
		self.histfile = os.path.join(os.environ["HOME"], file)
		try:
			readline.read_history_file(self.histfile)
		except IOError:
			pass
		
	def store(self):
		try:
			readline.write_history_file(self.histfile)
		except IOError:
			pass

def ulc(str):
	ul(str, (COLS - len(str)) / 2)

def ul(str, offset = 0):
	print "%s%s" % (' ' * offset, str)
	print "%s%s" % (' ' * offset, '=' * len(str))

def grep(pattern, files):
	args = [EGREP]
	args.append(pattern)
	args.extend(STD_ARGS)
	args.extend(files)
	args.append('/dev/null')
	return os.spawnvp(os.P_WAIT, EGREP, args)

def main(args):
	files = list(args)
	del files[0]
	if files == []:
		files = ["-R", "."]
	history = HistFile(HISTFILE)
	try:
		ulc("Simple Grep Shell %s" % VERSION)
		print HELP
		while True:
			pattern = raw_input('>> ')
			if pattern != '':
				try:
					grep(pattern, files)
				except KeyboardInterrupt:
					pass
	except (EOFError, KeyboardInterrupt):
		print 'Bye.'
	history.store()
	
if __name__ == '__main__':
	main(sys.argv)

