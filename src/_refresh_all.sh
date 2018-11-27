#!/bin/sh
curl --connect-timeout 1 -m 1 -o /dev/null -s -w %{http_code} http://localhost:45678/ngxshared/refresh_all &