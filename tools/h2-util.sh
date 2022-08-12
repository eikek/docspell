#!/usr/bin/env bash
#
# Create and restore dumps from h2 databases.
#
# H2 dumps should be created using the same (or compatible) version of
# h2 that is used to run the db.
#
# Docspell 0.38.0 and earlier uses H2 1.4.x. From Docspell 0.39.0
# onwards it's 2.1.x.
#
# Set the H2 version via an environment variable 'H2_VERSION'.
# Additionally a user and password are required, set these via env
# variables H2_USER and H2_PASSWORD. (or modify this script)
#
# Creating/restoring a dump requires to specify the database file. H2
# appends suffixes like '.mv.db' and '.trace.db', but here the base
# file is required. So if you see a file 'mydb.mv.db', specify here
# 'mydb' only or a complete JDBC url.
#
# The target file or target db must not exist.
#
# The dump file contains (H2 specific) SQL that recreates the
# database. It can be modified if necessary. This SQL script can then
# be used to restore the database even to a newer version of H2.

set -e

h2_user=${H2_USER:-"sa"}
h2_password=${H2_PASSWORD:-""}
h2_version=${H2_VERSION:-"1.4.200"}
#h2_version="2.1.214"

h2_jar_url="https://search.maven.org/remotecontent?filepath=com/h2database/h2/$h2_version/h2-$h2_version.jar"
h2_jdbc_opts=";MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE"

tempdir=$(mktemp -d "h2-util.XXXXX")
trap "rm -rf $tempdir" EXIT


prepare() {
    echo "Prepare for h2 version: $h2_version"
    curl -sSL -o $tempdir/h2.jar "$h2_jar_url"
}

create_dump() {
    src_db_file="$1"
    target_file="$2"

    jdbc_url=""
    if [[ "$src_db_file" =~ jdbc:h2:.* ]]; then
        jdbc_url="$src_db_file"
    elif [ -r "$src_db_file.mv.db" ]; then
        jdbc_url="jdbc:h2://$(realpath "$src_db_file")$h2_jdbc_opts"
    else
        echo "Invalid database. Either specify the file or a full JDBC url."
        echo "Usage: $0 dump <db-file|jdbc_url> <target-file>"
        exit 1
    fi

    if [ -z "$target_file" ]; then
        echo "No target file given"
        echo "Usage: $0 dump <db-file|jdbc_url> <target-file>"
        exit 1
    fi
    if [ -r "$target_file" ]; then
        echo "The target file '$target_file' already exists!"
        echo "Usage: $0 dump <db-file|jdbc_url> <target-file>"
        exit 1
    fi

    echo "Creating a dump: $jdbc_url -> $target_file"
    prepare
    java -cp "$tempdir/h2.jar" org.h2.tools.Script \
         -url "$jdbc_url" \
         -user "$h2_user" \
         -password "$h2_password" \
         -script "$target_file"
}

restore_dump() {
    backup_file="$1"
    target_db_file="$2"

    jdbc_url=""
    if [[ "$target_db_file" =~ jdbc:h2:.* ]]; then
        jdbc_url="$target_db_file"
    elif ! [ -r "$target_db_file.mv.db" ]; then
        jdbc_url="jdbc:h2://$(realpath "$target_db_file")$h2_jdbc_opts"
    else
        echo "Invalid database or it does already exist. Either specify the file or a full JDBC url."
        echo "Usage: $0 restore <dump-file> <db-file|jdbc_url>"
        exit 1
    fi

    if [ -z "$backup_file" ]; then
        echo "No dump file given"
        echo "Usage: $0 restore <dump-file> <db-file|jdbc_url>"
        exit 1
    fi
    if ! [ -r "$backup_file" ]; then
        echo "The dump file '$backup_file' doesn't exists!"
        echo "Usage: $0 dump <db-file|jdbc_url> <target-file>"
        exit 1
    fi

    echo "Restore a dump: $backup_file -> $jdbc_url"
    prepare
    java -cp "$tempdir/h2.jar" org.h2.tools.RunScript \
         -url "$jdbc_url" \
         -user "$h2_user" \
         -password "$h2_password" \
         -script "$backup_file" \
         -options FROM_1X
}

case "$1" in
    dump)
        shift
        create_dump "$@"
        ;;

    restore)
        echo "Restoring from a file"
        shift
        restore_dump "$@"
        ;;

    *)
        echo "Invalid command. One of: dump, restore"
        exit 1
esac
