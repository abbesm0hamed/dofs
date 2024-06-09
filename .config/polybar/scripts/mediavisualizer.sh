#!/bin/bash
export LANG=C.UTF-8

bar="▁▂▃▄▅▆▇█"
dict="s/;//g;"

# creating "dictionary" to replace char with bar
i=0
while [ $i -lt ${#bar} ]; do
  dict="${dict}s/$i/${bar:$i:1}/g;"
  i=$((i = i + 1))
done

base_directory="$HOME/.cache/polybar_cava"
if [[ ! -d "$base_directory" ]]; then
  mkdir -p "$base_directory"
fi

#create unique pipe
pipe="$base_directory/cava.fifo"
i=1
while [ -p $pipe ]; do
  pipe="$base_directory/cava_$i.fifo"
  i=$((i + 1))
done

mkfifo $pipe

# write cava config
config_file="$base_directory/polybar_cava_config"
echo "
[general]
bars = 10
autosens = 1
overshoot = 20
sensitivity = 100
lower_cutoff_freq = 50
higher_cutoff_freq = 10000
[output]
method = raw
raw_target = $pipe
data_format = ascii
ascii_max_range = 7
style = stereo
[smoothing]
integral = 70
monstercat = 1
waves = 0
gravity = 100
ignore = 0
[eq]
1 = 2 # bass
2 = 2
3 = 1 # midtone
4 = 1
5 = 0.5 # treble
" >$config_file

# run cava in the background
cava -p $config_file &

# reading data from fifo
while read -r cmd; do
  echo $cmd | sed $dict
done <$pipe
