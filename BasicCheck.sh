#! /bin/bash

DIRPATH=$1
PROG=$2

# After the check compilation passed successfully,
# check with valgring if the program has memory
# leak with valgrind passed successfully.
#Checks with helgrind that our program does not
# have synchronisation errors.
helgrind-check(){
  valgrind --error-exitcode=1 --tool=helgrind $DIRPTH/$PROG > sync-err.txt 2>&1
  grep -q "ERROR SUMMARY: 0 errors" sync-err.txt
  if [ $? -eq 0 ]
  then
    rm sync-err.txt
    echo "    Compilation    Memory leaks    thread race"
    echo "       PASS            PASS            PASS"
    exit 0
  else
    echo "    Compilation    Memory leaks    thread race"
    echo "       PASS            PASS            FAIL"
    rm sync-err.txt
    exit 1
  fi
}

# After the check compilation passed successfully,
# checks with valgring if the program has memory
# leak with valgrind.
# The idea taken from: https://stackoverflow.com/questions/8355979/how-to-redirect-valgrinds-output-to-a-file ,
# https://unix.stackexchange.com/questions/7704/what-is-the-meaning-of-in-a-shell-script
valgrind-check(){
  valgrind --error-exitcode=1 --leak-check=full -v ./$PROG > memory-leak.txt 2>&1
  grep -q "no leaks are possible" memory-leak.txt
  if [ $? -eq 0 ]
  then
    rm memory-leak.txt
    helgrind-check
  else
    rm memory-leak.txt

    # If memory leak fail check thread race, if thread race pass,
    # return 2 (010) else return 3 (011)

    valgrind --error-exitcode=1 --tool=helgrind $DIRPTH/$PROG > sync-err.txt 2>&1
    grep -q "ERROR SUMMARY: 0 errors" sync-err.txt
    if [ $? -eq 0 ]
    then
      rm sync-err.txt
      echo "    Compilation    Memory leaks    thread race"
      echo "       PASS            FAIL            PASS"
      exit 2
    else
      echo "    Compilation    Memory leaks    thread race"
      echo "       PASS            FAIL            FAIL"
      rm sync-err.txt
      exit 3
    fi

  fi
}

# If the path that recives is a directory check
# existence Makefile - if exist run it.
check-makefile(){
  if [ -e "$DIRPATH/./Makefile" ]
  then
    cd "$DIRPATH"
    make > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
      valgrind-check
    else
      echo "    Compilation    Memory leaks    thread race"
      echo "       FAIL            FAIL            FAIL"
      exit 7
    fi

  else
    echo "Makefile does not exist!!"
    exit 7
  fi
}

# The program starts here and checks if the path
# the recives its a directory or not.
if [ -d "$DIRPATH" ]
then
  check-makefile
else
  echo "$DIRPATH does not path directory!!"
  exit 7
fi
