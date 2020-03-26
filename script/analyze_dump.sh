#!/bin/bash
read -p "last output file: " output
read -p "last dump file: " dump

echo "total files in ${output}: "
ls -l ${output} | grep "^-" | wc -l
echo "-------------------------"
grep -Li "< ERROR" ${dump}/*
echo "+++++++++++++++++++++++++"
grep -Li "> ERROR" ${dump}/*
