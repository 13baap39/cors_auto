#!/bin/bash

# Default values
input_file=""
output_file=""
threads=10
url=""

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -i|--input)
      input_file="$2"
      shift
      ;;
    -o|--output)
      output_file="$2"
      shift
      ;;
    -t|--threads)
      threads="$2"
      shift
      ;;
    -u|--url)
      url="$2"
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  -i, --input   : Input file with a list of URLs/domains (e.g., -i /path/to/urls.txt)"
      echo "  -o, --output  : Output file to save results (e.g., -o /path/to/output.txt)"
      echo "  -t, --threads : Number of threads (e.g., -t 5) (default is 10)"
      echo "  -u, --url     : Single URL to check for CORS vulnerability (e.g., -u https://example.com)"
      echo "  -h, --help    : Display this help message"
      exit 0
      ;;
    *)
      echo "Error: Unrecognized option: $1"
      echo "Please use -h or --help for usage information."
      exit 1
      ;;
  esac
  shift
done

# Check if both input file and single URL are provided
if [ -n "$input_file" ] && [ -n "$url" ]; then
  echo "Error: Please provide either an input file or a single URL, not both."
  exit 1
fi

# Check if at least one of input file or single URL is provided
if [ -z "$input_file" ] && [ -z "$url" ]; then
  echo "Error: Please provide an input file or a single URL."
  exit 1
fi

if [ -n "$input_file" ] && [ ! -f "$input_file" ]; then
  if [ -d "$input_file" ]; then
    echo "Error: Input file is a directory. Please provide a file."
  else
    echo "Error: Input file not found."
  fi
  exit 1
fi

if [ -n "$url" ] && [ ! -z "$input_file" ]; then
  echo "Error: Please provide either an input file or a single URL, not both."
  exit 1
fi

if [ -n "$url" ]; then
  target=$(curl -sIL -H "Origin: https://evil.com" -X GET "$url")
  if grep -q "Access-Control-Allow-Origin: https://evil.com" <<< "$target"; then
    echo -e "[vuln TO CORS] $url\n$target\n"
  else
    echo "No CORS vulnerability found on $url."
  fi
  exit 0
fi

site="https://evil.com"

while read -r line; do
  target=$(curl -sIL -H "Origin: $site" -X GET "$line")

  if grep -q "Access-Control-Allow-Origin: $site" <<< "$target"; then
    echo -e "[vuln TO CORS] $line\n$target\n" >> "${output_file:-/dev/stdout}"
  fi
done < "${input_file:-/dev/null}"

echo "CORS scan completed."
if [ -n "$output_file" ]; then
  echo "Results saved to: $output_file"
fi
