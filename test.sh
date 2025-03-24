#!/bin/bash
GREEN='\e[1;32m'
PURPLE='\e[1;35m'
RED='\e[1;31m'
WHITE='\e[1;37m'
RESET='\033[0m'
VALGRIND='valgrind --leak-check=full --show-leak-kinds=all --log-file=.julesmem.log'

# Function to run get_next_line with different files and buffer sizes

run_gnl()
{
	local program=$1
	local filename=$2
	local runtime=30
	shift
	> .julestestout
	> .julesmem.log
	> .julesvalcheck

	( ${VALGRIND} ./$program "test_files/$filename" 1> .julestestout 2> /dev/null ) &
	PID=$!
	SECONDS=0
	while ps -p $PID > /dev/null; do
		if [ $SECONDS -gt $runtime ]; then
			kill $PID
			echo -n "❌"
			echo -e "$filename: Program timed out\n" >> gnl_trace
			return 1
		fi
		sleep 1
	done
	wait $PID
	exit_code=$?
	grep --text "ERROR SUMMARY:" .julesmem.log  | sed 's/==[0-9]\+== //g' > .julesvalcheck
	if [ $exit_code -eq 139 ]; then
		echo -n "❌"
		echo -e "$filename: Segmentation Fault\n" >> gnl_trace
	elif ! diff .julestestout test_files/$filename > .julesdiff; then
		echo -n "❌"
		echo -e "$filename: File not completely read\n" >> gnl_trace
		cat .julesdiff >> gnl_trace
		echo "\n" >> gnl_trace
	elif grep -q "ERROR SUMMARY: [^0]" .julesvalcheck; then
		echo -n "❌"
		echo -e "$filename: Memory leak detected\n" >> gnl_trace
	else
		echo -n "✅"
	fi
}

run_gnlb()
{
	local program=$1
	local runtime=30
	shift
	> .julestestout
	> .julesmem.log
	> .julesvalcheck

	( ${VALGRIND} ./$program "test_files/space.txt" "test_files/alpha.txt" "test_files/longline.txt" "test_files/largefile.txt" 1> .julestestout 2> /dev/null ) &
	PID=$!
	SECONDS=0
	while ps -p $PID > /dev/null; do
		if [ $SECONDS -gt $runtime ]; then
			kill $PID
			echo -n "❌"
			echo -e "Multiple fds: Program timed out\n" >> gnl_trace
			return 1
		fi
		sleep 1
	done
	wait $PID
	exit_code=$?
	grep --text "ERROR SUMMARY:" .julesmem.log  | sed 's/==[0-9]\+== //g' > .julesvalcheck
	if [ $exit_code -eq 139 ]; then
		echo -n "❌"
		echo -e "Multiple fds: Segmentation Fault\n" >> gnl_trace
	elif ! diff .julestestout test_files/bonus.txt > .julesdiff; then
		echo -n "❌"
		echo -e "Multiple fds: Output incorrect\n" >> gnl_trace
		cat .julesdiff >> gnl_trace
		echo "\n" >> gnl_trace
	elif grep -q "ERROR SUMMARY: [^0]" .julesvalcheck; then
		echo -n "❌"
		echo -e "Multiple fds: Memory leak detected\n" >> gnl_trace
	else
		echo -n "✅"
	fi
}

# Check if the test files exist

TEST_FILES_DIR="./test_files"

if [ ! -d "$TEST_FILES_DIR" ]; then
	echo -e "${RED}Test files directory not found. Aborting test...${RESET}"
	exit 1
fi
required_files=(
	"empty.txt"
	"onlynl.txt"
	"space.txt"
	"alpha.txt"
	"longline.txt"
	"largefile.txt"
	"gnlmain.c"
	"gnlmain.c"
)
for file in "${required_files[@]}"; do
	if [ ! -f "$TEST_FILES_DIR/$file" ]; then
		echo -e "${RED}Required file $file not found. Aborting test...${RESET}"
		exit 1
	fi
done
if [ -f "$TEST_FILES_DIR/gnlmain.c" ] && [ -f get_next_line.c ] && [ -f get_next_line_utils.c ]&& [ -f get_next_line.h ]; then
	cc -Wall -Werror -Wextra -D BUFFER_SIZE=1 $TEST_FILES_DIR/gnlmain.c get_next_line_utils.c get_next_line.c -o gnl1
	cc -Wall -Werror -Wextra -D BUFFER_SIZE=42 $TEST_FILES_DIR/gnlmain.c get_next_line_utils.c get_next_line.c -o gnl2
	cc -Wall -Werror -Wextra -D BUFFER_SIZE=10000000 $TEST_FILES_DIR/gnlmain.c get_next_line_utils.c get_next_line.c -o gnl3
	cc -Wall -Werror -Wextra $TEST_FILES_DIR/gnlmain.c get_next_line_utils.c get_next_line.c -o gnl4
else
	echo -e "${RED}Compilation error: file missing. Aborting test...${RESET}"
	exit 1
fi
if [ ! -f "gnl1" ] || [ ! -f "gnl2" ] || [ ! -f "gnl3" ] || [ ! -f "gnl4" ]; then
	echo -e "${RED}Compilation failure: executable not found. Aborting test...${RESET}"
	exit 1
fi
if [ -f get_next_line_bonus.c ] && [ -f get_next_line_utils_bonus.c ]&& [ -f get_next_line_bonus.h ]; then
	cc -Wall -Werror -Wextra -D BUFFER_SIZE=1 $TEST_FILES_DIR/gnlmain.c get_next_line_utils_bonus.c get_next_line_bonus.c -o gnlb1
	cc -Wall -Werror -Wextra -D BUFFER_SIZE=42 $TEST_FILES_DIR/gnlmain.c get_next_line_utils_bonus.c get_next_line_bonus.c -o gnlb2
	cc -Wall -Werror -Wextra -D BUFFER_SIZE=10000000 $TEST_FILES_DIR/gnlmain.c get_next_line_utils_bonus.c get_next_line_bonus.c -o gnlb3
	cc -Wall -Werror -Wextra $TEST_FILES_DIR/gnlmain.c get_next_line_utils_bonus.c get_next_line_bonus.c -o gnlb4
	if [ ! -f "gnlb1" ] || [ ! -f "gnlb2" ] || [ ! -f "gnlb3" ] || [ ! -f "gnlb4" ]; then
		echo -e "${RED}Compilation failure: bonus executable not found. Aborting test...${RESET}"
		exit 1
	fi
fi

# If trace already exists, add seperator to denote new test run

if [ -f "gnl_trace" ]; then
	echo -e "\n============================================================\n" >> gnl_trace
fi
echo -e "----- TRACE BEGINS -----\n" >> gnl_trace

# Run tests with buffer size of 1

echo -e "${PURPLE}--- ${WHITE}BUFFER_SIZE=1${PURPLE} ---\n${RESET}"
echo -e "-- BUFFER_SIZE=1 --\n" >> gnl_trace

run_gnl gnl1 space.txt
run_gnl gnl1 alpha.txt
run_gnl gnl1 longline.txt
run_gnl gnl1 largefile.txt
run_gnl gnl1 empty.txt
run_gnl gnl1 onlynl.txt
echo -e "\n"

# Run tests with buffer size of 42

echo -e "${PURPLE}--- ${WHITE}BUFFER_SIZE=42${PURPLE} ---\n${RESET}"
echo -e "-- BUFFER_SIZE=42 --\n" >> gnl_trace

run_gnl gnl2 space.txt
run_gnl gnl2 alpha.txt
run_gnl gnl2 longline.txt
run_gnl gnl2 largefile.txt
run_gnl gnl2 empty.txt
run_gnl gnl2 onlynl.txt
echo -e "\n"

# Run tests with buffer size of 10000000

echo -e "${PURPLE}--- ${WHITE}BUFFER_SIZE=10000000${PURPLE} ---\n${RESET}"
echo -e "-- BUFFER_SIZE=10000000 --\n" >> gnl_trace

run_gnl gnl3 space.txt
run_gnl gnl3 alpha.txt
run_gnl gnl3 longline.txt
run_gnl gnl3 largefile.txt
run_gnl gnl3 empty.txt
run_gnl gnl3 onlynl.txt
echo -e "\n"

# Run tests with no buffer size specified

echo -e "${PURPLE}--- ${WHITE}BUFFER_SIZE not set${PURPLE} ---\n${RESET}"
echo -e "-- BUFFER_SIZE not set --\n" >> gnl_trace

run_gnl gnl4 space.txt
run_gnl gnl4 alpha.txt
run_gnl gnl4 longline.txt
run_gnl gnl4 largefile.txt
run_gnl gnl4 empty.txt
run_gnl gnl4 onlynl.txt
echo -e "\n"

if [ -f "gnlb1" ] || [ -f "gnlb2" ] || [ -f "gnlb3" ] || [ -f "gnlb4" ]; then
	echo -e "${PURPLE}==== ${WHITE}BONUS${PURPLE} ====\n${RESET}"
	echo -e "==== BONUS ====\n" >> gnl_trace
	# Run tests with buffer size of 1
	echo -e "${PURPLE}--- ${WHITE}BUFFER_SIZE=1${PURPLE} ---\n${RESET}"
	echo -e "-- BUFFER_SIZE=1 --\n" >> gnl_trace

	run_gnl gnlb1 space.txt
	run_gnl gnlb1 alpha.txt
	run_gnl gnlb1 longline.txt
	run_gnl gnlb1 largefile.txt
	run_gnl gnlb1 empty.txt
	run_gnl gnlb1 onlynl.txt
	run_gnlb gnlb1 
	echo -e "\n"

	# Run tests with buffer size of 42

	echo -e "${PURPLE}--- ${WHITE}BUFFER_SIZE=42${PURPLE} ---\n${RESET}"
	echo -e "-- BUFFER_SIZE=42 --\n" >> gnl_trace

	run_gnl gnl2 space.txt
	run_gnl gnl2 alpha.txt
	run_gnl gnl2 longline.txt
	run_gnl gnl2 largefile.txt
	run_gnl gnl2 empty.txt
	run_gnl gnl2 onlynl.txt
	run_gnlb gnlb2
	echo -e "\n"

	# Run tests with buffer size of 10000000

	echo -e "${PURPLE}--- ${WHITE}BUFFER_SIZE=10000000${PURPLE} ---\n${RESET}"
	echo -e "-- BUFFER_SIZE=10000000 --\n" >> gnl_trace

	run_gnl gnl3 space.txt
	run_gnl gnl3 alpha.txt
	run_gnl gnl3 longline.txt
	run_gnl gnl3 largefile.txt
	run_gnl gnl3 empty.txt
	run_gnl gnl3 onlynl.txt
	run_gnlb gnlb3
	echo -e "\n"

	# Run tests with no buffer size specified

	echo -e "${PURPLE}--- ${WHITE}BUFFER_SIZE not set${PURPLE} ---\n${RESET}"
	echo -e "-- BUFFER_SIZE not set --\n" >> gnl_trace

	run_gnl gnl4 space.txt
	run_gnl gnl4 alpha.txt
	run_gnl gnl4 longline.txt
	run_gnl gnl4 largefile.txt
	run_gnl gnl4 empty.txt
	run_gnl gnl4 onlynl.txt
	run_gnlb gnlb4
	echo -e "\n"
else
	echo -e "${PURPLE}--- ${WHITE}No bonus found. Ending test...${PURPLE} ---\n${RESET}"
fi
rm -rf .julestestout .julesmem.log .julesvalcheck .julesdiff gnl1 gnl2 gnl3 gnl4
echo -e "---- TRACE ENDS ----" >> gnl_trace
echo -e "${PURPLE}--- ${WHITE}Testing complete: gnl_trace created${PURPLE} ---\n${RESET}"

# Created by Jules Pierce @ Hive Helsinki 2025/03/21 - https://github.com/Jules478