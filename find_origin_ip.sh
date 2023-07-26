#!/bin/bash


domain=$1

path="$(pwd)/origin_ip_for_${domain}"
mkdir -p $path

domains_file="${path}/subfinder_${domain}.txt"
echo "Running: subfinder -d $domain -o $domains_file"
subfinder -d "$domain" -o "$domains_file"
echo [INF] domains found - $(wc -l $domains_file)

domains_under_cdn_file="${path}/domains_under_cdn.txt"
echo "Running: cdncheck -cdn -i $domains_file -o $domains_under_cdn_file"
cdncheck -cdn -i "$domains_file" -o "$domains_under_cdn_file"

uncover_out=$(uncover -cs "$domain")
ips_file="${path}/ips.txt"
ips=$(echo $uncover_out | 
  grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | 
  sort -u > $ips_file)

ips_under_cdn_file="${path}/ips_under_cdn.txt"
ips_not_under_cdn_file="${path}/ips_not_under_cdn.txt"
ips_under_cdn=$(cat "$ips_file" | cdncheck -duc -cdn | sort -u > "$ips_under_cdn_file")
echo [INF] ips under cdn - $(wc -l $ips_under_cdn_file)
ips_not_under_cdn=$(comm -23 $ips_file $ips_under_cdn_file > $ips_not_under_cdn_file)
echo [INF] ips not under cdn - $(wc -l $ips_not_under_cdn_file)

check_bypass $domains_under_cdn_file $ips_not_under_cdn_file
