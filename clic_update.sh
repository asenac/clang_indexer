#!/bin/bash

SOURCE_PATH=$1
SOURCE_ABSOLUTE_PATH=`cd $SOURCE_PATH; pwd`

index_filename() {
    echo $1.i.gz | tr "/" "%"
}

add_to_index() {
    echo + $1
    clic_add index.db $(index_filename $1) \
        `[ -r ${SOURCE_PATH}/.clang_complete ] && cat ${SOURCE_PATH}/.clang_complete` $1
}

remove_from_index() {
    INDEX_FILENAME=$(index_filename $1)
    echo - $1
    clic_rm index.db $INDEX_FILENAME
    rm -f $INDEX_FILENAME
}


if [ ! -f index.db -o ! -f files.txt \
     -o ${SOURCE_PATH}/.clang_complete -nt index.db ]; then
    echo "Creating database"
    clic_clear index.db
    > files.txt
else
    echo "Updating database"
fi

find $SOURCE_ABSOLUTE_PATH\
    -name "*.cpp" -or\
    -name "*.hpp" -or\
    -name "*.cxx" -or\
    -name "*.hxx" -or\
    -name "*.ipp" -or\
    -name "*.cc" -or\
    -name "*.c" -or\
    -name "*.h"\
    | grep -v '/CMakeFiles/' \
    | sort > files2.txt

# Add added files
for i in `comm -23 files2.txt files.txt`; do
    add_to_index $i
done

# Remove removed files
for i in `comm -23 files.txt files2.txt`; do
    remove_from_index $i
done

# Update modified files
for i in `cat files.txt`; do
    if [ -f $i -a $i -nt files.txt ]; then
        remove_from_index $i
        add_to_index $i
    fi
done

mv files2.txt files.txt
