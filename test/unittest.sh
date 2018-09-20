#!/bin/bash
echo "--------- Starting test $1 ---------"

CMD=$(<test/"$1"-cmd.txt)
RETURN=$(perl /opt/fhem/fhem.pl 7072 "$CMD")

echo "- Diff:"
diff <( grep -v -f "test/$1-excl.txt"  -x <(echo "$RETURN")) <( grep -v -f "test/$1-excl.txt" -x "test/$1-res.txt") || {
    echo "- changes detected"
    echo "- return was:"
    echo "$RETURN"    
    echo "- FHEM Log has the following"
    cat /opt/fhem/log/fhem-*.log
    echo "--------- End of test $1: error ---------"
    exit 1
}
echo "- no changes detected"

grep "PERL WARNING" /opt/fhem/log/fhem-*.log | grep duino > /dev/null && {
    echo "PERL WARNING in Log:"
    grep "PERL WARNING" /opt/fhem/log/fhem-*.log
    echo "--------- End Test $1: error ---------"
    exit 1    
}
echo "--------- Test $1: OK ---------"
exit 0