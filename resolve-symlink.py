#!/usr/bin/env python

import os
import sys
import shutil

def resolve_symlinks(links):
    for f in links:
        try:
            target = os.readlink(f)
            if target[0] != '/':
                # make absolute
                target = os.path.join(os.path.dirname(f), target)
            os.unlink(f)
            shutil.move(target, f)
        except OSError, err:
            print "Failed: %s (%s)" % (f, err)


if __name__ == '__main__':
    resolve_symlinks(sys.argv[1:])
