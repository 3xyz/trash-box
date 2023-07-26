#!/bin/bash

ffuf -x http://localhost:8080 -w $1:FUZZ -u FUZZ
