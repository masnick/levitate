LEVITATE: Match strings in CSV files with Levenshtein distances
===============================================================

Ever have two sets of strings that you want to match? Levitate to the
rescue!

Consider set A:

    ANIMAL
    cat
    dog
    mouse

And set b:

    ANIMAL
    catt
    dug
    doog
    dog
    hog
    mouse
    bird

Levitate will let you compare the two based on
[Levenshtein distances](http://en.wikipedia.org/wiki/Levenshtein_distance):

    $ ./levitate.rb --file_a samples/a.csv --file_b samples/b.csv --match ANIMAL --threshold 0.5
    No stratification:
    +----------+----------+
    | *ANIMAL* | DISTANCE |
    +----------+----------+
    | cat      |          |
    | catt     | 0.25     |
    +----------+----------+
    +----------+----------+
    | *ANIMAL* | DISTANCE |
    +----------+----------+
    | dog      |          |
    | dog      | 0.0      |
    | doog     | 0.25     |
    | dug      | 0.333    |
    | hog      | 0.333    |
    +----------+----------+
    +----------+----------+
    | *ANIMAL* | DISTANCE |
    +----------+----------+
    | mouse    |          |
    | mouse    | 0.0      |
    +----------+----------+

Prerequisites
-------------

- Ruby v1.8.7
- rubygems
- the bundler gem


If you have Ruby v1.9.x, you'll need to use a Ruby version manager to
get v1.8.7 up on your computer. I suggest [RVM](https://rvm.beginrescueend.com/)
for Mac and Linux and [pik](https://github.com/vertiginous/pik/) for
Windows.

On Windows, you would do the following in the git bash:

    #
    # If you don't have pik yet:
    #
    $ mkdir /c/bin
    $ gem install pik
    $ echo "[[ -s \$USERPROFILE/.pik/.pikrc ]] && source \$USERPROFILE/.pik/.pikrc" >> ~/.bashrc
    # Now add `c:\bin` to your path under System Properties > Environment Variables
    # Close and re-open your git bash

    #
    # Once you have pik:
    #
    $ cd /c/Users/your_username
    $ pik install ruby 1.8.7
    $ gem install bundler

Usage
-----

    $ git clone git://github.com/masnick/levitate.git

    # Make sure you got those rubygems...
    $ bundle

    # See the syntax
    $ ./levitate.rb help compare

      NAME:

        compare

      DESCRIPTION:

        No description.

      SYNOPSIS:

        ./levitate.rb --file_a /pth/to/a.csv --file_b /pth/to/b.csv --match matchvar [--stratify \
            stratvar1,stratvar2,etc --threshold 0.25]

      OPTIONS:
            
        --file_a String 
            Path to CSV file A
            
        --file_b String 
            Path to CSV file B
            
        --match STRING 
            Column name for matching
            
        --stratify STRING 
            Optional column name(s) for stratification, separated with commas (no spaces)
            
        --threshold FLOAT 
            Threshold, between 0 and 1. 0 is perfect match.
            
        --output STRING 
            Output type: pretty or csv

Storing your output
-------------------

Levitate prints to `STDOUT` by default. You can use the `>` operator
to store the output in a more useful place. For example:

    $ ./levitate.rb --file_a samples/a.csv --file_b samples/b.csv --match ANIMAL --threshold 0.5 > ~/lev.txt

will store the sample output in your home folder in a file called
`lev.txt`. You can check this by then typing:

    $ cat ~/lev.txt

to print the contents of this file in your command prompt.

Copying
-------

Levitate is licensed under the MIT license:

    Copyright (c) 2011 Duke University

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

Authors
-------

Levitate was created by [Max Masnick](http://duke.edu/~mfm11).


