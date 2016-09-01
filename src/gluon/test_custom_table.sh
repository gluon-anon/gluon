#!/bin/sh
export INPUT_TO_TEST=`dirname $0`/../../images/androidprogressive.jpg
if [ $# -eq 0 ]; then
    echo "Using default file $INPUT_TO_TEST"
else
    export INPUT_TO_TEST=$1
fi
export GLUON_COMPRESSION_MODEL_OUT="`mktemp /tmp/temp.XXXXXX`"
export TEST_MODEL="`mktemp /tmp/temp.XXXXXX`"
export COMPRESSED_GLUON="`mktemp /tmp/temp.XXXXXX`"
export ORIGINAL="`mktemp /tmp/temp.XXXXXX`"
if [ $# -lt 2 ]; then
    ./gluon -allowprogressive - < "$INPUT_TO_TEST" > "$COMPRESSED_GLUON"
    cp "$GLUON_COMPRESSION_MODEL_OUT" "$TEST_MODEL"
else
    for test_item in "$@"; do
        if [ "$test_item" != "$INPUT_TO_TEST" ]; then
            ./gluon -allowprogressive - < "$test_item" > "$COMPRESSED_GLUON"
            cp "$GLUON_COMPRESSION_MODEL_OUT" "$TEST_MODEL"
            export GLUON_COMPRESSION_MODEL="$TEST_MODEL"
        else
            echo "Ignoring $test_item when training model"
        fi
    done
fi
GLUON_COMPRESSION_MODEL="$TEST_MODEL" ./gluon -decode -allowprogressive - < "$INPUT_TO_TEST" > "$COMPRESSED_GLUON"
GLUON_COMPRESSION_MODEL="$TEST_MODEL" ./gluon -recode -allowprogressive - < "$COMPRESSED_GLUON" > "$ORIGINAL"
md5sum "$ORIGINAL" "$INPUT_TO_TEST" 2> /dev/null || md5 "$ORIGINAL" "$INPUT_TO_TEST"
if diff -q "$ORIGINAL" "$INPUT_TO_TEST" ; then
    rm -- "$GLUON_COMPRESSION_MODEL_OUT"
    rm -- "$TEST_MODEL"
    rm -- "$COMPRESSED_GLUON"
    rm -- "$ORIGINAL"
    unset GLUON_COMPRESSION_MODEL_OUT
    unset TEST_MODEL
    unset COMPRESSED_GLUON
    unset ORIGINAL
    exit 0
fi
echo compression_model "$GLUON_COMPRESSION_MODEL_OUT"
echo test_model "$TEST_MODEL"
echo compressed_gluon "$COMPRESSED_GLUON"
echo roundtrip "$ORIGINAL"
unset GLUON_COMPRESSION_MODEL_OUT
unset TEST_MODEL
unset COMPRESSED_GLUON
unset ORIGINAL
exit 1
