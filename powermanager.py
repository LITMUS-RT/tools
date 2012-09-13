#!/usr/bin/env python

from __future__ import print_function

import sys
import argparse
import os.path
import urllib2

from operator import methodcaller
from time import sleep


"""Manages the power for the IP Power 9258.

You are meant to create symlinks to this file for each port.

"""

class PowerManagerException(RuntimeError):
    def __init__(self, reason):
        super(PowerManagerException, self).__init__()
        self.reason = reason

class PowerManager(object):
    """Manages the power for a single port of the IP Power 9258."""

    def __init__(self, host, username, password, port):
        self.host = host
        self.username = username
        self.password = password
        self.port = port

        """Set-up urllib2"""
        basic_handler = urllib2.HTTPBasicAuthHandler()
        basic_handler.add_password(realm='IP9258',
                uri='http://{}/'.format(self.host),
                user=self.username,
                passwd=self.password)
        opener = urllib2.build_opener(basic_handler)
        urllib2.install_opener(opener)

    def __call_url(self, full_url):
        try:
            url_res = urllib2.urlopen(full_url)
            txt = url_res.read()
            url_res.close()
            return txt
        except urllib2.URLError as e:
            raise PowerManagerException('Error opening URL: {}'.format(
                e.reason))

    def get_state(self):
        full_url = 'http://{}/Set.cmd?CMD=GetPower'.format(self.host)
        return self.__call_url(full_url)

    def __call_url_power(self, port_value):
        port_state = '{}={}'.format(self.port, port_value)
        full_url = 'http://{}/Set.cmd?CMD=SetPower+{}'.format(self.host,
                port_state)
        txt = self.__call_url(full_url)
        if -1 == txt.find(port_state):
            """Response should be the port_state we wanted, plus HTML."""
            raise PowerManagerException('Bad response: {}'.format(txt))

    def power_on(self):
        print("Power on.")
        self.__call_url_power('1')

    def power_off(self):
        print("Power off.")
        self.__call_url_power('0')

    def power_cycle(self):
        self.power_off()
        sleep(1)
        self.power_on()

    @classmethod
    def dispatch_action(cls, power_manager, action):
        ACTION_CALLBACKS = {'get': methodcaller('get_state'),
                'on': methodcaller('power_on'),
                'off': methodcaller('power_off'),
                'cycle': methodcaller('power_cycle')}
        actions = ACTION_CALLBACKS.keys()
        try:
            action_method = ACTION_CALLBACKS[action]
        except KeyError:
            raise ValueError('Invalid action: {}'.format(action))
        ret = action_method(power_manager)
        if ret is not None:
            print(ret)


def parse_args():
    p = argparse.ArgumentParser(description='Control power.')
    p.add_argument('action', help='get|on|off|cycle')
    return p.parse_args(sys.argv[1:])

def find_port():
    """Finds port to use based on script name.
    
    Assumes the script is named <SOMETHING>-power.py, where the part before the
    dash is a dict key.
    
    """
    POWER_PORTS = { 'pound': 'p61', 'pandaboard': 'p62' }

    script_name = os.path.basename(sys.argv[0])
    dash_pos = script_name.find('-')
    if -1 == dash_pos:
        raise ValueError('No dash found in script name: {}'.format(script_name))
    port_key = script_name[:dash_pos]
    try:
        return (port_key, POWER_PORTS[port_key])
    except KeyError:
        raise KeyError('Port key not found in dict: {}'.format(port_key))

def read_password():
    fname = os.path.expanduser('~/.poundpower')
    with open(fname) as f:
        password = f.read().strip()
    return password

def main():
    HOST = 'pound-pwr.cs.unc.edu'
    USERNAME = 'admin'

    try:
        password = read_password()
    except IOError as e:
        print('Error reading password file: {}'.format(e), file=sys.stderr)
        sys.exit(1)

    args = parse_args()

    machine, port = find_port()
    print('Operating on port {} machine {}.'.format(port, machine))
    mgr = PowerManager(HOST, USERNAME, password, port)
    try:
        PowerManager.dispatch_action(mgr, args.action)
    except PowerManagerException as e:
        print('Exception: {}'.format(e.reason), file=sys.stderr)
        sys.exit(1)
    sys.exit(0)

if __name__ == '__main__':
    main()
