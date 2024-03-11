import json
import csv
import sys

###########################################################################
# Author: 	    Quentin Hélion
# Date:   	    11/03/2024
# Description: 	This script does check if csv value is on json or vice versa
# Requirments:  json, csv, sys
# Usage:        json-csv.py <JSON> <CSV>
###########################################################################


def compare_json_to_csv(jsonFile, csvFile, csv_delimiter=';'):
    # Read JSON data
    with open(jsonFile, 'r') as json_file:
        json_data = json.load(json_file)

    
    # Read CSV data with specified delimiter
    csv_data = []
    with open(csvFile, 'r') as csv_file:
        csv_reader = csv.DictReader(csv_file, delimiter=csv_delimiter)
        for row in csv_reader:
            csv_data.append(row)

    for djson in json_data:
        buffer = 0
        for dcsv in csv_data:
            if dcsv["name"] == djson["name"]:
                print(dcsv["name"], " found")
                buffer = 1
        if not buffer:
            print(djson["name"], " not found")


def compare_csv_to_json(jsonFile, csvFile, csv_delimiter=';'):
    # Read JSON data
    with open(jsonFile, 'r') as json_file:
        json_data = json.load(json_file)

    
    # Read CSV data with specified delimiter
    csv_data = []
    with open(csvFile, 'r') as csv_file:
        csv_reader = csv.DictReader(csv_file, delimiter=csv_delimiter)
        for row in csv_reader:
            csv_data.append(row)

    for dcsv in csv_data:
        buffer = 0
        for djson in json_data:
            if dcsv["name"] == djson["name"]:
                print(dcsv["name"], " found")
                buffer = 1
        if not buffer:
            print(djson["name"], " not found")
        buffer = 0  
   

def main():
    if len(sys.argv) != 3:
        print("Usage: python script.py <json_file_path> <csv_file_path>")
        sys.exit(1)

    json_file_path = sys.argv[1]
    csv_file_path = sys.argv[2]

    print("===== JSON TO CSV ====")
    compare_json_to_csv(json_file_path, csv_file_path)

    print("===== CSV TO JSON ====")
    compare_csv_to_json(json_file_path, csv_file_path)

if __name__ == "__main__":
    main()
