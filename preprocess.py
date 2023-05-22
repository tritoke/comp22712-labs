#!/usr/bin/env python
"""
MIT License

Copyright (c) 2021 Sam Leonard

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

import sys
import re

INCLUDE_REGEX = re.compile(r"INCLUDE\s+(\S+)")
WHITESPACE_ONLY_REGEX = re.compile(r"^\s*$")


def main():
    if len(sys.argv) == 3:
        input_file = sys.argv[1]
        output_file = sys.argv[2]

        output = process(input_file)

        try:
            open(output_file, "x").close()
        except:
            print("The output file already exists, are you sure you want to overwrite it? (y/N)" )
            choice = input()
            if choice.lower() != "y":
                sys.exit(0)
            else:
                print("Continuing")

        with open(output_file, "w") as f:
            f.writelines([line + "\n" for line in output])
    else:
        print("USAGE: {sys.argv[0]} <INPUT> <OUTPUT>")
        sys.exit(0)


def process(fname):
    output = []
    with open(fname) as f:
        lines = f.read().splitlines()

    for line in lines:
        match = INCLUDE_REGEX.search(line)
        if match is not None:
            # if there is more text in the line than include... then keep it
            removed = INCLUDE_REGEX.sub("", line)
            if removed != "":
                # make sure that its not just whitespace
                if WHITESPACE_ONLY_REGEX.search(removed) is None:
                    output.append(removed)

            inner_include = match.group(1)
            if inner_include is not None:
                # add a comment to show this file was included
                output.append(f"; {' '+inner_include+' ':#^50}")
                # process the included file
                output.extend(process(inner_include))
        else:
            output.append(line)

    return output


if __name__ == "__main__":
    main()
