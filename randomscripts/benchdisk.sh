#!/usr/bin/env bash

if [ $# != 1 ]; then
  echo "Usage: $0 scratch_path"
  exit 1
fi
scratch_dir=$(mktemp -d $1/benchdisk.XXXXXX)


let onek=1024
let onemeg=1024*1024
let onegig=1024*1024*1024

num_smalltest=5
num_largetest=2


timed_call () {
  local cmd="$@"
  time_taken=$(
  (
    time (
      eval $cmd;
    )
  ) 2>&1 | awk '/^real/ {print $2}' | sed -e 's/s$//' | awk -Fm '{print $1*60+$2}');
  echo $time_taken;
}


compute_real_size () {
  local blocks=$1;
  local blocksize=$2;
  let size=$blocks*$blocksize;
  echo $size;
}


compute_speed () {
  local time_taken=$1;
  local size=$2;
  speed=$(python -c "rate=str(1.0*$size/$time_taken/(1024*1024))[:7]; print(\"%s MB/s\" % rate);");
  echo $speed;
}


bench_disk_write () {
  local size=$1;
  local blocksize=$2;
  local path=$3
  let blocks=$size/$blocksize
  if [ $blocks == 0 ]; then
    echo "Invalid size / blocksize passed to bench_disk_write."
    exit 1
  fi
  local real_size=$(compute_real_size $blocks $blocksize);
  dd if=/dev/zero of=/dev/null bs=$onemeg count=$((32*$onegig/$onemeg)) >/dev/null 2>/dev/null
  local time_taken=$(timed_call "dd if=/dev/zero of=$path bs=$blocksize count=$blocks && sync");
  speed=$(compute_speed $time_taken $real_size);
  echo "$speed (bs=$blocksize,count=$blocks,realsize=$real_size,t=$time_taken)";
}


bench_disk_read () {
  local size=$1;
  local blocksize=$2;
  local path=$3
  let blocks=$size/$blocksize
  if [ $blocks == 0 ]; then
    echo "Invalid size / blocksize passed to bench_disk_read."
    exit 1
  fi
  local real_size=$(compute_real_size $blocks $blocksize);
  if [ $size -gt $onemeg ]; then
    let blocks_to_write=$size/$onemeg;
  else
    let blocks_to_write=$size/$onek;
  fi
  dd if=/dev/zero of=$path bs=$onemeg count=$blocks_to_write >/dev/null 2>/dev/null;
  sync;
  dd if=/dev/zero of=/dev/null bs=$onegig count=32 >/dev/null 2>/dev/null
  local time_taken=$(timed_call "dd if=$path of=/dev/null bs=$blocksize count=$blocks");
  speed=$(compute_speed $time_taken $real_size);
  echo "$speed (bs=$blocksize,count=$blocks,realsize=$real_size,t=$time_taken)";
}


runtest () {
  local filename=$1
  local times=$2
  local command="$3 $4 $5"
  for n in `seq 1 $times`; do
    eval $command $filename
    rm $filename
  done
  echo
}


echo "Benchmarking access to path $scratch_dir."
echo

echo "TEST: write 16M w/ 1M blocks:"
runtest "$scratch_dir/write-zeros-16M-1M" $num_smalltest bench_disk_write $(($onemeg*16)) $onemeg

echo "TEST: write 16M w/ 128K blocks:"
runtest "$scratch_dir/write-zeros-16M-128K" $num_smalltest bench_disk_write $(($onemeg*16)) $(($onek*128))

echo "TEST: write 16M w/ 16K blocks:"
runtest "$scratch_dir/write-zeros-16M-16K" $num_smalltest bench_disk_write $(($onemeg*16)) $(($onek*16))

echo "TEST: write 16K w/ 1K blocks:"
runtest "$scratch_dir/write-zeros-16K-1K" $num_smalltest bench_disk_write $(($onek*16)) $(($onek))

echo "TEST: read 16M w/ 1M blocks:"
runtest "$scratch_dir/read-zeros-16M-1M" $num_smalltest bench_disk_read $(($onemeg*16)) $onemeg

echo "TEST: read 16M w/ 128K blocks:"
runtest "$scratch_dir/read-zeros-16M-128K" $num_smalltest bench_disk_read $(($onemeg*16)) $(($onek*128))

echo "TEST: read 16M w/ 16K blocks:"
runtest "$scratch_dir/read-zeros-16M-16K" $num_smalltest bench_disk_read $(($onemeg*16)) $(($onek*16))

echo "TEST: read 16K w/ 1K blocks:"
runtest "$scratch_dir/read-zeros-16K-1K" $num_smalltest bench_disk_read $(($onek*16)) $(($onek))

echo "TEST: write 1G w/ 1M blocks:"
runtest "$scratch_dir/write-zeros-1G-1M" $num_largetest bench_disk_write $onegig $onemeg

echo "TEST: write 1G w/ 16M blocks:"
runtest "$scratch_dir/write-zeros-1G-16M" $num_largetest bench_disk_write $onegig $((onemeg*16))

echo "TEST: write 8G w/ 16M blocks:"
runtest "$scratch_dir/write-zeros-8G-16M" $num_largetest bench_disk_write $((onegig*8)) $((onemeg*16))

echo "TEST: write 16G w/ 16M blocks:"
runtest "$scratch_dir/write-zeros-16G-16M" $num_largetest bench_disk_write $((onegig*16)) $((onemeg*16))

echo "TEST: read 1G w/ 1M blocks:"
runtest "$scratch_dir/read-zeros-1G-1M" $num_largetest bench_disk_read $onegig $onemeg

echo "TEST: read 1G w/ 16M blocks:"
runtest "$scratch_dir/read-zeros-1G-16M" $num_largetest bench_disk_read $onegig $((onemeg*16))

echo "TEST: read 8G w/ 16M blocks:"
runtest "$scratch_dir/read-zeros-8G-16M" $num_largetest bench_disk_read $((onegig*8)) $((onemeg*16))

echo "TEST: read 16G w/ 16M blocks:"
runtest "$scratch_dir/read-zeros-16G-16M" $num_largetest bench_disk_read $((onegig*16)) $((onemeg*16))

rm -rf $scratch_dir
