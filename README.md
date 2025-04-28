# get_next_line Tester

## What is it?

This is my custom tester for the 42 school project 'get_next_line'. get_next_line (or gnl) is a function that is designed to read files or standard input and will return each line separated by newlines (\n) every time it is called.

## What does it test?

The tester will check how gnl handles small files, large files, files with long lines, files with short lines, and empty files. It will perform each of these tests with different buffer sizes as well as with no predefined buffer size. It will also check for memory leaks.

## How to run it

Clone the repo into your gnl directory and move the tesh.sh file next to your gnl files. The tester will compile everything it needs internally and clean up all files generated during the test with the exception of the trace. 

> [!NOTE]
> This tester is not a definitive guide on the functionality of philosophers. This is only my own personal tests. There may be edge cases that are not considered here. This tester should be used as a tool and not a replacement for a full evaluation. 