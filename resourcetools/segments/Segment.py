# Copyright (c) 2023 NVIDIA CORPORATION & AFFILIATES. ALL RIGHTS RESERVED.
#
# This software is available to you under a choice of one of two
# licenses.  You may choose to be licensed under the terms of the GNU
# General Public License (GPL) Version 2, available from the file
# COPYING in the main directory of this source tree, or the
# OpenIB.org BSD license below:
#
#     Redistribution and use in source and binary forms, with or
#     without modification, are permitted provided that the following
#     conditions are met:
#
#      - Redistributions of source code must retain the above
#        copyright notice, this list of conditions and the following
#        disclaimer.
#
#      - Redistributions in binary form must reproduce the above
#        copyright notice, this list of conditions and the following
#        disclaimer in the documentation and/or other materials
#        provided with the distribution.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#######################################################
#
# Segment.py
# Python implementation of the Class Segment
# Generated by Enterprise Architect
# Created on:      14-Aug-2019 10:11:57 AM
# Original author: talve
#
#######################################################
from abc import ABC, abstractmethod
import struct
import sys


def unpack_segment_header(raw_data, offset):
    short_1, short_2 = Segment.segment_header_struct.unpack_from(raw_data, offset)
    length_dw, segment_type = (short_1, short_2) if sys.byteorder == "big" else (short_2, short_1)
    return length_dw, segment_type


class Segment(ABC):
    """this class is responsible for holding segment data according to its type.
    """

    segment_header_struct = struct.Struct('HH')

    def __init__(self, data):
        """initialize the class by setting the class data.
        """
        self.size = 0
        self._parsed_data = []  # list of strings representing lines of parsed data
        self._messages = []  # list of strings representing errors/warning/notices
        self.raw_data = data

    def get_size(self):
        return self.size

    def get_data(self, byte_order=sys.byteorder):
        """get the segment data.
        """
        if byte_order == sys.byteorder:
            return self.raw_data
        else:
            ints = [int.from_bytes(self.raw_data[i:i + 4], sys.byteorder) for i in range(0, len(self.raw_data), 4)]
            reversed_data = bytearray()
            for number in ints:
                reversed_data.extend(number.to_bytes(4, byte_order))
            return reversed_data

    def get_type(self):
        """get the segment type.
        """
        return self._segment_type_id

    def unpack_segment_header(self):
        return unpack_segment_header(self.raw_data, 0)

    def add_parsed_data(self, parsed_line):
        self._parsed_data.append(parsed_line)

    def get_parsed_data(self):
        """get dictionary of parsed segment data.
        """
        return self._parsed_data

    def add_message(self, message):
        self._messages.append(message)

    def get_messages(self):
        """get dictionary of parsed segment data.
        """
        return self._messages

    # TODO: check if function below necesarry
    def additional_title_info(self):
        """return index1 and index2 if exists in the segment.
        """
        return ""