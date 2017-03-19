#!/bin/bash
echo " -- This script is going to execute the following list of `wc -l commands`:" >&2
cat commands >&2
echo " -- On the following `wc -l remote_hosts`:" >&2
cat remote_hosts >&2
echo " -- Please provide password:" >&2
read -s psw
if [[ $psw != "" ]]; then
{
  cat remote_hosts | while read -r host; do
  {
    echo "  -- connecting to $host --" >&2
    [ -f Log_${host}.txt ] && rm Log_${host}.txt
    cat commands | while read -r cmd; do
    {
      echo "   -- running: $cmd --" >&2
      /usr/bin/expect >> Log_${host}.txt -- <<EOF
      set timeout 10
      spawn ssh -t $host "$cmd"
      expect {
        timeout { send_error "    -- timeout : $host : $cmd\n"; send_user "Timeout!"; exit 9 }
        "*authenticity*established*(yes/no)?*" { send_error "    -- adding $host fingerprint\n"; send "yes\r"; exp_continue }
        "*assword:*" { send_error "    -- logging in.. to $host\n"; send "${psw}\r"; exp_continue }
        "*sudo*password*:*" { send_error "    -- asked for sudo password\n"; send "${psw}\r"; exp_continue }
        eof { send_error "    -- printing results\n"; puts $expect_out() }
      }
EOF
      if [[ $? == 9 ]]; then break; fi
    }
    done
  }
  done
}
else
{
  echo " -- Empty password / no execution" >&2
}
fi
