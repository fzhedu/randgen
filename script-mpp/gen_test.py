#!/usr/bin/env python 
#!coding:utf-8

import os
import argparse
import subprocess

class TableGenerator:
    def __init__(self):
        self.__stdErrFile = "/tmp/stderr.txt"
        self.__workDir = os.getcwd()
        self.__randgenDir = "randgen-2.2.0"

    def create_database(self, args):
        print args.database
        sql = "drop database if exists {}; create database {};".format(
                args.database, args.database)

        command = ["mysql"]
        command = command + ["--connect-timeout", "1"]
        command = command + ["-h", args.host]
        command = command + ["-P", args.port]
        command = command + ["-u", args.user]
        if args.passwd != "":
            command = command + ["-p{}".format(args.passwd)]
        command = command + ["-e", sql]

        errFile = open(self.__stdErrFile, "w+")
        try:
            print command, errFile
            subprocess.check_call(command, stderr=errFile)
        except subprocess.CalledProcessError as e:
            errFile.close()
            errFile = open(self.__stdErrFile, "r")
            print("# ERROR:\n{}".format(errFile.read()))
            errFile.close()
            return False

        errFile.close()
        return True

    def gen_table_data(self, args):
        dsn = "dbi:mysql:host={}:port={}:user={}:password={}:database={}".format(
                args.host, args.port, args.user, args.passwd, args.database)

        grammarFile = os.path.abspath(args.table)
        print("# TABLE GRAMMAR FILE: {}".format(grammarFile))

        command = ["perl", "gentest.pl"]
        command = command + ["--dsn",  dsn]
        command = command + ["--gendata", grammarFile]
        command = command + ["--grammar", grammarFile]

        os.chdir(self.__randgenDir)
        errFile = open(self.__stdErrFile, "w+")
        try:
            print command
            subprocess.check_call(command, stderr=errFile)
        except subprocess.CalledProcessError as e:
            errFile.close()
            errFile = open(self.__stdErrFile, "r")
            print("# ERROR:\n{}".format(errFile.read()))
            errFile.close()
            return False

        errFile.close()
        return True

    def dump_database(self, args):
        command = ["mysqldump"]
        command = command + ["-h", args.host]
        command = command + ["-P", args.port]
        command = command + ["-u", args.user]
        if args.passwd != "":
            command = command + ["-p{}".format(args.passwd)]
        command = command + ["--databases", args.database]
        command = command + ["--extended-insert=FALSE"]
        command = command + ["--skip-comments"]

        tableFile = "{}/{}.test".format(self.__workDir, args.database)
        outFile = open(tableFile, "w+")
        errFile = open(self.__stdErrFile, "w+")
        try:
            subprocess.check_call(command, stdout=outFile, stderr=errFile)
        except subprocess.CalledProcessError as e:
            errFile.close()
            errFile = open(self.__stdErrFile, "r")
            print("# ERROR:\n{}".format(errFile.read()))
            outFile.close()
            errFile.close()
            return False

        outFile.close()
        errFile.close()
        return True

    def gen_queries(self, args):
        dsn = "dbi:mysql:host={}:port={}:user={}:password={}:database={}".format(
                args.host, args.port, args.user, args.passwd, args.database)
        tableFile = "{}/{}.test".format(self.__workDir, args.database)
        os.chdir(self.__workDir)
        grammarFile = os.path.abspath(args.query)
        print("# QUERY GRAMMAR FILE: {}".format(grammarFile))

        command = ["/usr/bin/perl", "gensql.pl"]
        command = command + ["--dsn",  dsn]
        command = command + ["--grammar", grammarFile]
        command = command + ["--queries", str(args.count)]
        print command

        os.chdir(self.__randgenDir)
        outFile = open(tableFile, "a")
        errFile = open(self.__stdErrFile, "w+")
        try:
            subprocess.check_call(command, stderr=errFile, stdout=outFile)
        except subprocess.CalledProcessError as e:
            errFile.close()
            errFile = open(self.__stdErrFile, "r")
            print("# ERROR:\n{}".format(errFile.read()))
            outFile.close()
            errFile.close()
            return False

        outFile.close()
        errFile.close()
        return True
        return command


def parse_args():
    parser = argparse.ArgumentParser(description="Create table and load data into it.")
    parser.add_argument("--host", dest="host", help="Server address. DEFAULT: 127.0.0.1", default="127.0.0.1")
    parser.add_argument("--port", dest="port", help="Server port. DEFAULT: 3306", default="3306")
    parser.add_argument("--user", dest="user", help="User for login. DEFAULT: root", default="root")
    parser.add_argument("--passwd", dest="passwd", help="Passwd for the user. DEFAULT: ''", default="")
    parser.add_argument("--database", dest="database", help="Database to use. DEFAULT: randgen_test", default="randgen_test")
    parser.add_argument("--count", dest="count", type=int, help="Number of queries to generate. DEFAULT: 100", default=100)
    parser.add_argument("table", help="The table grammar file")
    parser.add_argument("query", help="The query grammar file")
    args = parser.parse_args()
    return args

def main():
    args = parse_args()
    generator = TableGenerator()

    if not generator.create_database(args):
        return

    if not generator.gen_table_data(args):
        return

    if not generator.dump_database(args):
        return

    if not generator.gen_queries(args):
        return

    print("# DONE!")

if __name__ == "__main__":
    main()
