#!/usr/bin/env python

import json
import sys
import struct
import os
from os.path import expanduser
import subprocess

# The path to the ds.sh tool.
try:
    home = expanduser("~")
    with open(home + '/.config/docspell/ds.cmd', 'r') as file:
        DS_SH_CMD = file.read().replace('\n', '')
except:
    DS_SH_CMD="ds.sh"


# Read a message from stdin and decode it.
def get_message():
    raw_length = sys.stdin.read(4)
    if not raw_length:
        sys.exit(0)
    message_length = struct.unpack('=I', raw_length)[0]
    message = sys.stdin.read(message_length)
    return json.loads(message)


# Encode a message for transmission, given its content.
def encode_message(message_content):
    encoded_content = json.dumps(message_content)
    encoded_length = struct.pack('=I', len(encoded_content))
    return {'length': encoded_length, 'content': encoded_content}


# Send an encoded message to stdout.
def send_message(encoded_message):
    sys.stdout.write(encoded_message['length'])
    sys.stdout.write(encoded_message['content'])
    sys.stdout.flush()


while True:
    filename = get_message()
    FNULL = open(os.devnull, 'w')
    rc = subprocess.call(args=[DS_SH_CMD, filename], stdout=FNULL, stderr=FNULL, close_fds=True)
    os.remove(filename)
    if rc == 0:
        send_message(encode_message(rc))
    else:
        send_message(encode_message(rc))
