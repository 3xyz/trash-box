#!/bin/bash

DEBUG=1

# Color tags
gray='\033[1;30m'
IRed='\033[0;91m'         
blue='\033[34m'
cyan='\033[0;36m'
orange='\e[00;33m'
red='\033[31m'
green='\033[0;32m'
bold='\033[1m'
n='\033[0m'

# Check if two input files are provided
if [ $# -ne 2 ]; then
  echo "Usage: $0 <ips_file> <domains_file>"
  exit 1
fi

ips_file=$1
domains_file=$2


# Function to check if a domain can be accessed via an IP address
check_domain_access() {
  local ip=$1
  local domain=$2

  # Make an HTTP request to the domain via the IP address
  status_code=$(curl -o /dev/null -s -w "%{http_code}" -H "Host: $domain" "$ip" -m 5)
  
  if [ "$status_code" == "000" ]; then
    return 0
  elif [[ "$status_code" =~ ^2.* ]]; then
    status_code="${green}${bold}$status_code${n}"
  elif [[ "$status_code" =~ ^3.* ]]; then
    status_code="${orange}${bold}$status_code${n}"
  else
    status_code="${cyan}${bold}$status_code${n}"
  fi
  
  if (( $DEBUG == 1 )); then
    html_response=$(curl -s -H "Host: $domain" "$ip" )
    title=$(echo "$html_response" | grep -o '<title>.*</title>' | sed 's/<title>\(.*\)<\/title>/\1/')
    if ! [ -z "$title" ]; then 
      echo -e "[$status_code] $ip\tHost: $domain ${orange}(Title: $title)${n}"
    else
      echo -e "[$status_code] $ip\tHost: $domain"
    fi
  fi

  # Check if the status code is 200 (OK)
  if [ "$status_code" = "200" ]; then
    html_response=$(curl -s -H "Host: $domain" "$ip" )
    title=$(echo "$html_response" | grep -o '<title>.*</title>' | sed 's/<title>\(.*\)<\/title>/\1/')
    echo "Domain $domain is accessible via IP $ip (Status Code: $status_code) ${orange}(Title: $title)${n}"
  fi
}

echo -e "${bold}Running httprobe for ips"
ips_with_prefix=$(cat $ips_file | httprobe)

echo -e "${bold}Checking bypass"
# Loop through each IP and domain in the input files
while read -r ip; do
  while read -r domain; do
    check_domain_access "$ip" "$domain"
  done < "$domains_file"
done <<< "$ips_with_prefix"
