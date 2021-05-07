#!/bin/bash
# vgm2flac
# Bash tool for vgm encoding to flac
#
# Author: Romain Barbarot
# https://github.com/Jocker666z/vgm2flac
#
# licence : GNU GPL-2.0

# Paths
vgm2flac_cache="/home/$USER/.cache/vgm2flac"												# Cache directory
vgm2flac_cache_tag="/home/$USER/.cache/vgm2flac/tag-$(date +%Y%m%s%N).info"					# Tag cache
export PATH=$PATH:/home/$USER/.local/bin													# For case of launch script outside a terminal

# Others
core_dependency=(bc bchunk ffmpeg ffprobe sox xxd)
ffmpeg_log_lvl="-hide_banner -loglevel panic -stats"										# ffmpeg log level
nprocessor=$(nproc --all)																	# Set number of processor

# Output
default_wav_fade_out="6"																	# Default fade out value in second, apply to all file during more than 10s
default_wav_bit_depth="pcm_s16le"															# Wav bit depth must be pcm_s16le, pcm_s24le or pcm_s32le
default_flac_bit_depth="s16"																# Flac bit depth must be s16 or s32
default_peakdb_norm="1"																		# Peak db normalization option, this value is written as positive but is used in negative, e.g. 4 = -4
# Atari ST
sc68_loops="1"
# Commodore 64/128
sid_loops="1"																				# sid file loop file number, value must be 1 or 2
sid_duration_without_loop="15"																# Track duration is second that does not trigger a music loop 
# Game Boy, NES, PC-Engine
xxs_default_max_duration="360"																# In second
# Midi
fluidsynth_soundfont=""																		# Set soundfont file that fluidsynth will use for the conversion, leave empty it will use the default soundfont
munt_rom_path=""																			# Set munt ROM dir (Roland MT-32 ROM)
# SNES
spc_default_duration="180"																	# In second
# vgm2wav
vgm2wav_samplerate="44100"																	# Sample rate in Hz
vgm2wav_bit_depth="16"																		# Bit depth must be 16 or 24
vgm2wav_loops="2"
# vgmstream
vgmstream_force_looping=""																	# force end-to-end looping with value "1", if empty no force


# Extensions
ext_adplay="hsq|imf|sdb|sqx|wlf"
ext_bchunk_cue="cue"
ext_bchunk_iso="bin|img|iso"
ext_ffmpeg="mod|spc|xa"
ext_ffmpeg_gbs="gbs"
ext_ffmpeg_hes="hes"
ext_midi="mid"
ext_nsfplay_nsf="nsf"
ext_nsfplay_nsfe="nsfe"
ext_sc68="snd|sndh"
ext_sox="bin|pcm|raw"
ext_playlist="m3u"
ext_vgm2wav="s98|vgm|vgz"
ext_zxtune_ay="ay"
ext_zxtune_nsf="nsf"
ext_zxtune_sid="sid"
ext_zxtune_xsf="2sf|gsf|dsf|psf|psf2|mini2sf|minigsf|minipsf|minipsf2|minissf|miniusf|minincsf|ncsf|ssf|usf"
ext_zxtune_ym="ym"
ext_zxtune_zx_spectrum="asc|psc|pt2|pt3|sqt|stc|stp"

# Bin check and set variable
adplay_bin() {
local bin_name="adplay"
local system_bin_location
system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	adplay_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
fluidsynth_bin() {
local bin_name="fluidsynth"
local system_bin_location
system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	if [[ -z "$fluidsynth_soundfont" ]]; then
		echo "Warning, the variable (fluidsynth_soundfont) indicating the location of the soundfont to use is not filled in, the result can be disgusting. See documentation."
	elif ! [[ -f "$fluidsynth_soundfont" ]]; then
		echo "Break, the variable (fluidsynth_soundfont) not indicating a file. See documentation."
		exit
	fi
	fluidsynth_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
info68_bin() {
local bin_name="info68"
local system_bin_location
system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	info68_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
munt_bin() {
local bin_name="mt32emu-smf2wav"
local system_bin_location
system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	if [[ -z "$munt_rom_path" ]]; then
		echo "Break, the variable (munt_rom_path) indicating the location of the Roland MT-32 ROM must be filled in. See documentation."
		exit
	elif ! [[ -d "$munt_rom_path" ]]; then
		echo "Break, the variable (munt_rom_path) not indicating a directory. See documentation."
		exit
	fi
	munt_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
nsfplay_bin() {
local bin_name="nsf2wav"
local system_bin_location
system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	nsfplay_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
sc68_bin() {
local bin_name="sc68"
local system_bin_location
system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	sc68_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
vgm2wav_bin() {
local bin_name="vgm2wav"
local system_bin_location
system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	vgm2wav_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
vgmstream_cli_bin() {
local bin_name="vgmstream_cli"
local system_bin_location
system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	vgmstream_cli_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
vgm_tag_bin() {
local bin_name="vgm_tag"
local system_bin_location
system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	vgm_tag_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
uade123_bin() {
local bin_name="uade123"
local system_bin_location
system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	uade123_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
zxtune123_bin() {
local bin_name="zxtune123"
local system_bin_location
system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	zxtune123_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
common_bin() {
n=0;
for command in "${core_dependency[@]}"; do
	if hash "$command" &>/dev/null
	then
		(( c++ )) || true
	else
		local command_fail+=("$command")
		(( n++ )) || true
	fi
done
if (( "${#command_fail[@]}" )); then
	echo "vgm2flac break, the following dependencies are not installed:"
	printf '  %s\n' "${command_fail[@]}"
	exit
fi
}

# Messages
cmd_usage() {
cat <<- EOF
vgm2flac - GNU GPL-2.0 Copyright - <https://github.com/Jocker666z/vgm2flac>
Bash tool for vgm/chiptune encoding to flac 

Usage: vgm2flac [options]
                          Without option treat current directory.
  -h|--help               Display this help.
  --no_fade_out           Force no fade out.
  --no_flac               Force output wav temp. files only.
  --no_normalization      Force no peak db normalization.
  --no_remove_silence     Force no remove silence at start & end of track.
  --pal                   Force the tempo reduction to simulate 50hz.

EOF
}
display_separator() {
echo "--------------------------------------------------------------"
}
display_flac_in_error() {
if ! [[ "${#lst_flac_in_error[@]}" = "0" ]]; then
	display_separator
	echo
	echo "FLAC file(s) in error:"
	printf ' %s\n' "${lst_flac_in_error[@]}"
	echo
fi
}

# Cache directory
check_cache_directory() {
if [ ! -d "$vgm2flac_cache" ]; then
	mkdir "$vgm2flac_cache"
fi
}
clean_cache_directory() {
find "$vgm2flac_cache/" -type f -mtime +3 -exec /bin/rm -f {} \;			# if file exist in cache directory after 3 days, delete it
rm "$vgm2flac_cache_tag" &>/dev/null
}

# Files array
list_source_files() {
mapfile -t lst_adplay < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_adplay')$' 2>/dev/null | sort)
mapfile -t lst_all_files < <(find "$PWD" -maxdepth 1 -type f 2>/dev/null | sort)
mapfile -t lst_bchunk_cue < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_bchunk_cue')$' 2>/dev/null | sort)
mapfile -t lst_bchunk_iso < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_bchunk_iso')$' 2>/dev/null | sort)
mapfile -t lst_ffmpeg < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_ffmpeg')$' 2>/dev/null | sort)
mapfile -t lst_ffmpeg_gbs < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_ffmpeg_gbs')$' 2>/dev/null | sort)
mapfile -t lst_ffmpeg_hes < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_ffmpeg_hes')$' 2>/dev/null | sort)
mapfile -t lst_midi < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_midi')$' 2>/dev/null | sort)
mapfile -t lst_m3u < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_playlist')$' 2>/dev/null | sort)
mapfile -t lst_nsfplay_nsf < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_nsfplay_nsf')$' 2>/dev/null | sort)
mapfile -t lst_nsfplay_nsfe < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_nsfplay_nsfe')$' 2>/dev/null | sort)
mapfile -t lst_sc68 < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_sc68')$' 2>/dev/null | sort)
mapfile -t lst_sox < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_sox')$' 2>/dev/null | sort)
mapfile -t lst_vgm2wav < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_vgm2wav')$' 2>/dev/null | sort)
mapfile -t lst_zxtune_ay < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_zxtune_ay')$' 2>/dev/null | sort)
mapfile -t lst_zxtune_sid < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_zxtune_sid')$' 2>/dev/null | sort)
mapfile -t lst_zxtune_xsf < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_zxtune_xsf')$' 2>/dev/null | sort)
mapfile -t lst_zxtune_ym < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_zxtune_ym')$' 2>/dev/null | sort)
mapfile -t lst_zxtune_zx_spectrum < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_zxtune_zx_spectrum')$' 2>/dev/null | sort)

# bin/cue clean
if [ "${#lst_bchunk_cue[@]}" -gt "1" ]; then											# If cue = 1
	echo "More than one CUE file in working directory"
	exit
elif [ "${#lst_bchunk_iso[@]}" = 1 ] && [ "${#lst_bchunk_cue[@]}" = 1 ]; then			# If bin/iso + cue = 1 + 1 - bchunk use
	unset lst_sox
	bchunk="1"
elif [ "${#lst_bchunk_cue[@]}" -gt "1" ]; then											# If bin > 1 - sox use
	unset lst_bchunk_cue
	unset lst_bchunk_iso
fi
}
list_wav_files() {
mapfile -t lst_wav < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('wav')$' 2>/dev/null | sort)
}
list_flac_files() {
mapfile -t lst_flac < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('flac')$' 2>/dev/null | sort)
}
list_flac_validation() {
if ! [[ "${#lst_flac[@]}" = "0" ]]; then
	local flac_test
	for i in "${!lst_flac[@]}"; do
		flac_error_test=$(soxi "${lst_flac[i]}" 2>/dev/null)
		flac_empty_test=$(sox "${lst_flac[i]}" -n stat 2>&1 | grep "Maximum amplitude:" | awk '{print $3}')
		if [ -z "$flac_error_test" ] || [[ "$flac_empty_test" = "0.000000" ]]; then
			lst_flac_in_error+=( "${lst_flac[i]}" )
		else
			lst_flac_validated+=( "${lst_flac[i]}" )
		fi
	done
fi
}

# Audio treatment
wav_remove_silent() {
if ! [[ "$no_remove_silence" = "1" ]]; then

	# Local variable
	local test_duration

	# Remove silence from audio files while leaving gaps, if audio during more than 10s
	test_duration=$(ffprobe -i "${files%.*}".wav -show_format -v quiet | grep duration | sed 's/.*=//' | cut -f1 -d".")
	if ! [[ "$test_duration" = "N/A" ]]; then			 # If not a bad file
		if [[ "$test_duration" -gt 10 ]]; then
			# Remove silence at start & end
			sox "${files%.*}".wav temp-out.wav silence 1 0.2 -85d reverse silence 1 0.2 -85d reverse
			rm "${files%.*}".wav &>/dev/null
			mv temp-out.wav "${files%.*}".wav &>/dev/null
		fi
	fi

fi
}
wav_remove_empty() {
	# Local variable
	local test_empty_wav

	# Remove wav empty
	for files in "${lst_wav[@]}"; do
		test_empty_wav=$(sox "$files" -n stat 2>&1 | grep "Maximum amplitude:" | awk '{print $3}')
		if [[ "$test_empty_wav" = "0.000000" ]]; then
			rm "$files" &>/dev/null
		fi
	done
}
wav_fade_out() {
if ! [[ "$no_fade_out" = "1" ]]; then

	# Local variables
	local test_duration
	local duration
	local sox_fade_in

	# Out fade, if audio during more than 10s
	test_duration=$(ffprobe -i "${files%.*}".wav -show_format -v quiet | grep duration | sed 's/.*=//' | cut -f1 -d".")
	if ! [[ "$test_duration" = "N/A" ]]; then			 # If not a bad file
		if [[ "$test_duration" -gt 10 ]]; then
			duration=$(soxi -d "${files%.*}".wav)
			sox_fade_in="0:0.0"
			if [[ -z "$imported_sox_fade_out" ]]; then
				local sox_fade_out="0:$default_wav_fade_out"
			else
				local sox_fade_out="0:$imported_sox_fade_out"
			fi
			sox "${files%.*}".wav temp-out.wav fade t "$sox_fade_in" "$duration" "$sox_fade_out"
			rm "${files%.*}".wav &>/dev/null
			mv temp-out.wav "${files%.*}".wav &>/dev/null
		fi
	fi

fi
}
wav_normalization_channel_test() {
# For active end functions
flac_loop_activated="1"

if ! [[ "$no_normalization" = "1" ]]; then

	# Local variables
	local testdb
	local positive_testdb
	local db
	local left_md5
	local right_md5

	# Test Volume, set normalization variable
	testdb=$(ffmpeg -i "${files%.*}".wav -af "volumedetect" -vn -sn -dn -f null /dev/null 2>&1 | grep "max_volume" | awk '{print $5;}')
	if [[ "$testdb" = *"-"* ]]; then
		positive_testdb=$(echo "$testdb" | cut -c2-)
	fi
	if [[ "$testdb" = *"-"* ]] && (( $(echo "$positive_testdb > $default_peakdb_norm" | bc -l) )); then
		db="$(echo "$testdb" | cut -c2- | awk -v var="$default_peakdb_norm" '{print $1-var}')dB"
		afilter="-af volume=$db"
	else
		afilter=""
	fi
	echo "$positive_testdb $default_peakdb_norm"
	echo "$positive_testdb > $default_peakdb_norm" | bc -l

	# Channel test mono or stereo
	left_md5=$(ffmpeg -i "${files%.*}".wav -map_channel 0.0.0 -f md5 - 2>/dev/null)
	right_md5=$(ffmpeg -i "${files%.*}".wav -map_channel 0.0.1 -f md5 - 2>/dev/null)
	if [ "$left_md5" = "$right_md5" ]; then
		confchan="-channel_layout mono"
	else
		confchan=""
	fi

	# Encoding Wav
	ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav $afilter $confchan -acodec "$default_wav_bit_depth" -f wav temp-out.wav
	rm "${files%.*}".wav &>/dev/null
	mv temp-out.wav "${files%.*}".wav &>/dev/null

fi
}
flac_force_pal_tempo() {
if [[ "$flac_force_pal" = "1" ]]; then
	# In case of audio speed is to high, reduce tempo to simulate 50hz
	# 60hz - 50hz = 83.333333333% of orginal speed
	for i in "${lst_flac_validated[@]}"; do
		sox "$files" temp-out.flac tempo 0.83333333333
		rm "$files".flac &>/dev/null
		mv temp-out.flac "$files" &>/dev/null
	done
fi
}
wav2flac() {
if ! [[ "$no_flac" = "1" ]]; then
	# Enconding final flac
	ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav -acodec flac -compression_level 12 -sample_fmt "$default_flac_bit_depth" -metadata title="$tag_song" -metadata album="$tag_album" -metadata artist="$tag_artist" -metadata date="$tag_date_formated" "${files%.*}".flac
fi
}

# Convert loop
loop_adplay() {				# PC adlib
if (( "${#lst_adplay[@]}" )); then
	# Bin check & set
	adplay_bin

	# Tag
	tag_machine="PC"
	tag_pc_sound_module="Adlib"
	tag_questions
	tag_album
	
	# Wav loop
	for files in "${lst_adplay[@]}"; do
		# Extract WAV
		(
		"$adplay_bin" "$files" --device "${files%.*}".wav --output=disk
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Generate wav array
	list_wav_files

	# Flac loop
	for files in "${lst_wav[@]}"; do
		# Tag
		tag_song
		# Peak normalisation to 0, false stereo detection 
		wav_normalization_channel_test
		# Remove silence
		wav_remove_silent
		# Add fade out
		wav_fade_out
		# Flac conversion
		(
		wav2flac
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_bchunk() {				# Various machines CDDA
if (( "${#lst_bchunk_iso[@]}" )); then

	# Local variable
	local track_name

	if test -n "$bchunk"; then				# If bchunk="1" in list_source_files()

		# Tag
		tag_questions
		tag_album

		# Extract WAV
		track_name=$(basename "${lst_bchunk_iso%.*}")
		bchunk -w "${lst_bchunk_iso[0]}" "${lst_bchunk_cue[0]}" "$track_name"-Track-
	
		# Remove data track
		rm -- "$track_name"-Track-*.iso &>/dev/null

		# Populate wav array
		list_wav_files

		# Flac loop
		for files in "${lst_wav[@]}"; do
			# Tag
			tag_song="[untitled]"
			# Peak normalisation to 0, false stereo detection 
			wav_normalization_channel_test
			# Remove silence
			wav_remove_silent
			# Flac conversion
			(
			wav2flac
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait
	fi
fi
}
loop_ffmpeg() {				# SNES, PS1 xa, PC mod, CD-i xa
if (( "${#lst_ffmpeg[@]}" )); then
	for files in "${lst_ffmpeg[@]}"; do
		shopt -s nocasematch									# Set case insentive
		case "${files[@]##*.}" in
			*mod)												# PC ProTracker MOD
				shopt -u nocasematch							# Set case sentive
				# Tag
				tag_questions
				tag_album
				tag_song
				# Extract WAV
				ffmpeg $ffmpeg_log_lvl -y -i "$files" -acodec pcm_s16le -ar 44100 -f wav "${files%.*}".wav
				# Peak normalisation to 0, false stereo detection 
				wav_normalization_channel_test
				# Remove silence
				wav_remove_silent
				# Fade out
				wav_fade_out
			;;
			*spc)												# SNES
				shopt -u nocasematch							# Set case sentive
				# Tag
				tag_spc
				tag_questions
				tag_album
				# Calc duration/fading
				local spc_fading_second=$(($spc_fading/1000))
				local spc_duration_total=$(($spc_duration+$spc_fading_second))
				# Extract WAV
				ffmpeg $ffmpeg_log_lvl -y -i "$files" -t $spc_duration_total -acodec pcm_s16le -ar 32000 -f wav "${files%.*}".wav
				# Fade out
				imported_sox_fade_out="$spc_fading_second"
				wav_fade_out
				# Peak normalisation to 0, false stereo detection 
				wav_normalization_channel_test
				# Remove silence
				wav_remove_silent
			;;
			*xa)												# PS1, CD-i
				shopt -u nocasematch							# Set case sentive
				# Tag
				tag_questions
				tag_album
				tag_song
				# Extract WAV
				ffmpeg $ffmpeg_log_lvl -y -i "$files" -acodec pcm_s16le -f wav "${files%.*}".wav
				# Peak normalisation to 0, false stereo detection 
				wav_normalization_channel_test
				# Remove silence
				wav_remove_silent
			;;
		esac

		# Flac conversion
		(
		wav2flac
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_ffmpeg_gbs() {			# GB/GBC
if (( "${#lst_ffmpeg_gbs[@]}" )); then

	# Local variables
	local file_total_track
	local total_sub_track

	for gbs in "${lst_ffmpeg_gbs[@]}"; do
		# Tags
		tag_gbs_extract
		tag_machine="Game Boy"
		tag_questions
		tag_album

		# Get total real total track
		file_total_track=$(xxd -ps -s 0x04 -l 1 "$gbs" | awk -Wposix '{printf("%d\n","0x" $1)}')	# Hex to decimal
		total_sub_track=$(("$file_total_track"-1))

		# Wav loop
		for sub_track in $(seq -w 0 "$total_sub_track"); do
			# Tag
			xxs_track=$((10#"$sub_track"))
			tag_xxs_loop
			(
			ffmpeg $ffmpeg_log_lvl -track_index "$sub_track" -y -i "$gbs" -t $xxs_duration_second -channel_layout mono -acodec pcm_s16le -ar 44100 \
				-f wav "$sub_track - $tag_song".wav
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

		# Flac loop
		for sub_track in $(seq -w 0 "$total_sub_track"); do
			# Tag
			xxs_track=$((10#"$sub_track"))
			tag_xxs_loop
			# File variable for next function
			files="$sub_track - $tag_song.wav"
			if [ -f "$files" ]; then
				# Peak normalisation to 0, false stereo detection 
				wav_normalization_channel_test
				# Fade out
				imported_sox_fade_out="$xxs_fading_second"
				wav_fade_out
				# Remove silence
				wav_remove_silent
				# Flac conversion
				(
				wav2flac
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
			fi
		done
		wait

	done
fi
}
loop_ffmpeg_hes() {			# PC-Engine (HuC6280)
if (( "${#lst_ffmpeg_hes[@]}" )); then

	# Local variable
	local total_sub_track

	for hes in "${lst_ffmpeg_hes[@]}"; do
		# Tags
		tag_hes_extract
		tag_machine="PC-Engine"
		tag_questions
		tag_album

		# Get total track
		total_sub_track="256"

		# Wav loop
		for sub_track in $(seq -w 0 "$total_sub_track"); do
			# Tag
			xxs_track=$((10#"$sub_track"))
			tag_xxs_loop
			# Extract WAV
			(
			ffmpeg $ffmpeg_log_lvl -track_index "$sub_track" -y -i "$hes" -t $xxs_duration_second -acodec pcm_s16le -ar 44100 \
				-f wav "$sub_track - $tag_song".wav
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

		# Remove empty wav
		list_wav_files
		wav_remove_empty

		for sub_track in $(seq -w 0 "$total_sub_track"); do
			# Tag
			xxs_track=$((10#"$sub_track"))
			tag_xxs_loop
			# File variable for next function
			files="$sub_track - $tag_song.wav"
			if [ -f "$files" ]; then
				# Peak normalisation to 0, false stereo detection 
				wav_normalization_channel_test
				# Fade out
				imported_sox_fade_out="$xxs_fading_second"
				wav_fade_out
				# Remove silence
				wav_remove_silent
				# Flac conversion
				(
				wav2flac
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
			fi
		done
		wait
	done
fi
}
loop_nsfplay_nsf() {		# NES
if (( "${#lst_nsfplay_nsf[@]}" )); then
	# Bin check & set
	nsfplay_bin

	# Local variables
	local file_total_track
	local total_sub_track

	for nsf in "${lst_nsfplay_nsf[@]}"; do
		# Tags
		tag_nsf_extract
		tag_machine="NES"
		tag_questions
		tag_album

		# Get total track
		file_total_track=$(xxd -ps -s 0x006 -l 1 "$nsf" | awk -Wposix '{printf("%d\n","0x" $1)}')	# Hex to decimal
		total_sub_track="$file_total_track"

		# Wav loop
		for sub_track in $(seq -w 1 "$total_sub_track"); do
			# Tag
			xxs_track=$((10#"$sub_track"))
			tag_xxs_loop
			(
			"$nsfplay_bin" --fade_ms="$xxs_fading_msecond" --length_ms="$xxs_duration_msecond" --samplerate=44100 --quiet \
				--track="$sub_track" "$nsf" "$sub_track - $tag_song".wav
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

		# Flac loop
		for sub_track in $(seq -w 0 "$total_sub_track"); do
			# Tag
			xxs_track=$((10#"$sub_track"))
			tag_xxs_loop
			# File variable for next function
			files="$sub_track - $tag_song.wav"
			if [ -f "$files" ]; then
				# Peak normalisation to 0, false stereo detection 
				wav_normalization_channel_test
				# Remove silence
				wav_remove_silent
				# Flac conversion
				(
				wav2flac
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
			fi
		done
		wait

	done
fi
}
loop_nsfplay_nsfe() {		# NES
if (( "${#lst_nsfplay_nsfe[@]}" )); then
	# Bin check & set
	nsfplay_bin

	# Local variables
	local file_total_track
	local total_sub_track

	for nsfe in "${lst_nsfplay_nsfe[@]}"; do
		# Tags
		tag_nsfe
		tag_machine="NES"
		tag_questions
		tag_album

		# Get total track
		file_total_track=$("$nsfplay_bin" "$nsfe" | grep "Track " | wc -l)
		total_sub_track="$file_total_track"

		# Wav loop
		for sub_track in $(seq -w 1 "$total_sub_track"); do
			# Tag
			tag_nsfe
			(
			"$nsfplay_bin" --length_ms="$nsfplay_default_max_duration" --samplerate=44100 --quiet \
				--track="$sub_track" "$nsfe" "$sub_track - $tag_song".wav
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

		# Flac loop
		for sub_track in $(seq -w 0 "$total_sub_track"); do
			# Tag
			tag_nsfe
			# File variable for next function
			files="$sub_track - $tag_song.wav"
			if [ -f "$files" ]; then
				# Peak normalisation to 0, false stereo detection 
				wav_normalization_channel_test
				# Remove silence
				wav_remove_silent
				# Flac conversion
				(
				wav2flac
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
			fi
		done
		wait

	done
fi
}
loop_midi() {				# PC midi
if (( "${#lst_midi[@]}" )); then

	# Local variables
	local midi_bin
	local midi_choice
	local fluidsynth_loop_nb

	# Bin selection
	echo
	echo " Select midi software synthesizer:"
	echo
	echo "  [0]* > fluidsynth -> Use soundfont"
	echo "  [1]  > munt       -> Use Roland MT-32, CM-32L, CM-64, LAPC-I emulator"
	read -e -p "-> " midi_choice
	case "$midi_choice" in
		"0")
			fluidsynth_bin
			midi_bin="$fluidsynth_bin"
			tag_pc_sound_module="Soundfont"
		;;
		"1")
			munt_bin
			midi_bin="$munt_bin"
			tag_pc_sound_module="Roland MT-32"
		;;
		*)
			fluidsynth_bin
			midi_bin="$fluidsynth_bin"
			midi_choice="0"
		;;
	esac

	# Fluidsynth loop number question
	if [[ "$midi_choice" = "0" ]]; then
		echo " Number of audio loops:"
		echo
		echo "  [1]* > Once"
		echo "  [2]  > Twice"
		read -e -p "-> " midi_loop_nb
		case "$midi_loop_nb" in
			"1")
				fluidsynth_loop_nb="1"
			;;
			"2")
				fluidsynth_loop_nb="2"
			;;
			*)
				fluidsynth_loop_nb="1"
			;;
		esac
	fi

	# Tag
	tag_machine="PC"
	tag_questions
	tag_album
	
	# Wav loop
	for files in "${lst_midi[@]}"; do
		# Extract WAV
		(
		if [[ "$midi_choice" = "0" ]]; then		# fluidsynth
			if [[ "$fluidsynth_loop_nb" = "1" ]]; then			# 1 loop
				"$midi_bin" -F "${files%.*}".wav "$fluidsynth_soundfont" "$files"
			elif [[ "$fluidsynth_loop_nb" = "2" ]]; then		# 2 loops
				"$midi_bin" -F "${files%.*}".wav "$fluidsynth_soundfont" "$files" "$files"
			fi
		elif [[ "$midi_choice" = "1" ]]; then	# munt
			"$midi_bin" -m "$munt_rom_path" -r 1 --output-sample-format=1 -p 44100 --src-quality=3 --analog-output-mode=2 -f \
				--record-max-end-silence=1000 -o "${files%.*}".wav "$files"
		fi
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Generate wav array
	list_wav_files

	# Flac loop
	for files in "${lst_wav[@]}"; do
		# Tag
		tag_song
		# Peak normalisation to 0, false stereo detection 
		wav_normalization_channel_test
		# Remove silence
		wav_remove_silent
		# Add fade out
		wav_fade_out
		# Flac conversion
		(
		wav2flac
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_sc68() {				# Atari ST (YM2149)
if (( "${#lst_sc68[@]}" )); then
	# Bin check & set
	info68_bin
	sc68_bin

	# Local variable
	local total_sub_track

	for sc68_files in "${lst_sc68[@]}"; do
		# Tag extract
		"$info68_bin" -A "$sc68_files" > "$vgm2flac_cache_tag"
		if [[ -z "$tag_game" && -z "$tag_artist" && -z "$tag_machine" ]]; then
			tag_game=$(cat "$vgm2flac_cache_tag" | grep -i -a title: | sed 's/^.*: //' | head -1)
			tag_artist=$(cat "$vgm2flac_cache_tag" | grep -i -a artist: | sed 's/^.*: //' | head -1)
			tag_date=$(cat "$vgm2flac_cache_tag" | grep -i -a year: | sed 's/^.*: //' | head -1)
		fi
		# Tag
		tag_questions
		tag_album
		# Get total track
		total_sub_track=$(cat "$vgm2flac_cache_tag" | grep -i -a track: | sed 's/^.*: //' | tail -1)
		# Track loop
		local track_name
		for sub_track in $(seq -w 1 "$total_sub_track"); do
			# Extract WAV
			track_name=$(basename "${sc68_files%.*}")
			"$sc68_bin" -l "$sc68_loops" -c -t "$sub_track" "$sc68_files" > "$sub_track".raw
			sox -t raw -r 44100 -b 16 -c 2 -L -e signed-integer "$sub_track".raw "$sub_track - $track_name".wav
			rm "$sub_track".raw
		done

		# Add lead 0 at filename
		rename_add_lead_zero
		# Generate wav array
		list_wav_files

		# Flac loop
		for files in "${lst_wav[@]}"; do
			# Tag
			tag_song="[untitled]"
			# Peak normalisation to 0, false stereo detection 
			wav_normalization_channel_test
			# Remove silence
			wav_remove_silent
			# Add fade out
			wav_fade_out
			# Flac conversion
			(
			wav2flac
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait
	done
fi
}
loop_sox() {				# Various machines
if (( "${#lst_sox[@]}" )); then

	# Local variable
	local delta

	for files in "${lst_sox[@]}"; do
		# Test if data by measuring maximum difference between two successive samples
		delta=$(sox -t raw -r 44100 -b 16 -c 2 -L -e signed-integer "$files" -n stat 2>&1 | grep "Maximum delta:" | awk '{print $3}')
		# If Maximum delta < 1.9 - raw -> wav
		if awk -v n1="$delta" -v n2="1.9" 'BEGIN {if (n1+0<n2+0) exit 0; exit 1}'; then
			# Tag
			tag_questions
			tag_album
			tag_song
			# Extract WAV
			(
			sox -t raw -r 44100 -b 16 -c 2 -L -e signed-integer "$files" "${files%.*}".wav
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		fi
	done
	wait

	for files in "${lst_sox[@]}"; do
		# Tag
		tag_song="[untitled]"
		tag_song
		# Peak normalisation to 0, false stereo detection 
		wav_normalization_channel_test
		# Remove silence
		wav_remove_silent
		# Flac conversion
		(
		wav2flac
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_uade() {				# Amiga
if (( "${#lst_all_files[@]}" )); then
	# Bin check & set
	uade123_bin

	# Local variables
	local uade_test_result
	local total_track
	local current_track
	local diff_track
	local file_name

	# Test all files
	lst_uade=()
	for files in "${lst_all_files[@]}"; do
		uade_test_result=$("$uade123_bin" -g "$files" 2>/dev/null)
		if [ "${#uade_test_result}" -gt "0" ]; then
			lst_uade+=("$files")
		fi
	done

	# Start
	if (( "${#lst_uade[@]}" )); then
		for files in "${lst_uade[@]}"; do
			# Tag
			tag_machine="Amiga"
			tag_questions
			tag_album

			# Get total track
			total_track=$("$uade123_bin" -g "$files" | grep "subsongs:" | awk '/^subsongs:/ { print $NF }')
			current_track=$("$uade123_bin" -g "$files" | grep "subsongs:" | awk '/^subsongs:/ { print $3 }')
			diff_track=$(( current_track - total_track ))
			# Wav loop
			for sub_track in $(seq -w "$current_track" "$total_track"); do
				# Filename construction
				if [ "$diff_track" -eq "0" ]; then
					file_name="$files"
				else
					file_name="${files}-$sub_track"
				fi
				# Wav extract
				(
				"$uade123_bin" --force-led=0 --one --silence-timeout 5 --panning 0.8 --subsong "$sub_track" "$files" -f "$file_name".wav
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
			done
			wait
		done
		# Generate wav array
		list_wav_files

		# Flac loop
		for files in "${lst_wav[@]}"; do
				# Tag
				tag_song

				# Peak normalisation to 0, false stereo detection 
				wav_normalization_channel_test
				# Remove silence
				wav_remove_silent
				# Fade out
				wav_fade_out
				# Flac conversion
				(
				wav2flac
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
		done
		wait
	fi
fi
}
loop_vgm2wav() {			# Various machines
if (( "${#lst_vgm2wav[@]}" )); then
	# Bin check & set
	vgm2wav_bin
	vgm_tag_bin

	# Wav loop
	for files in "${lst_vgm2wav[@]}"; do
		shopt -s nocasematch									# Set case insentive
		case "${files[@]##*.}" in
			*vgm|*vgz)
				shopt -u nocasematch							# Set case sentive
				# Extract WAV
				(
				"$vgm2wav_bin" --samplerate "$vgm2wav_samplerate" --bps "$vgm2wav_bit_depth" --loops "$vgm2wav_loops" \
				"$files" "${files%.*}".wav
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
			;;
			*s98)
				shopt -u nocasematch							# Set case sentive
				# Extract WAV
				(
				"$vgm2wav_bin" --samplerate "$vgm2wav_samplerate" --bps "$vgm2wav_bit_depth" --loops "$vgm2wav_loops" \
				"$files" "${files%.*}".wav
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
			;;
		esac
	done
	wait

	# Flac/tag loop
	for files in "${lst_vgm2wav[@]}"; do
		shopt -s nocasematch									# Set case insentive
		# Tag
		case "${files[@]##*.}" in
			*vgm|*vgz)
				shopt -u nocasematch							# Set case sentive
				# Tag
				tag_vgm
			;;
			*s98)
				shopt -u nocasematch							# Set case sentive
				# Tag
				tag_s98
			;;
		esac
		tag_questions
		tag_album
		# Peak normalisation to 0, false stereo detection 
		wav_normalization_channel_test
		# Remove silence
		wav_remove_silent
		# Flac conversion
		(
		wav2flac
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_vgmstream() {			# Various machines
if (( "${#lst_all_files[@]}" )); then
	# Bin check & set
	unset lst_wav
	vgmstream_cli_bin

	# Local variables
	local vgmstream_test_result
	local total_sub_track
	local force_fade_out

	for files in "${lst_all_files[@]}"; do
		if ! [[ "${files##*.}" = "wav" || "${files##*.}" = "flac" ]]; then
			vgmstream_test_result=$("$vgmstream_cli_bin" -m "$files" 2>/dev/null)
			# If vgmstream pass test, add to array
			if [ "${#vgmstream_test_result}" -gt "0" ] && ! [[ "${files##*.}" = "TXTH" ]]; then
				# If no wav already output ok add to array
				if ! compgen -G "$files*.wav" > /dev/null; then
					lst_vgmstream+=("$files")
				fi
				# Activate fade out for files: his
				if [[ "${files##*.}" = "his" ]]; then
					force_fade_out="1"
				fi
			fi
		fi
	done

	for files in "${lst_vgmstream[@]}"; do
		# Tag
		tag_questions
		tag_album

		# Get total track
		total_sub_track=$("$vgmstream_cli_bin" -m "$files" | grep -i -a "stream count" | sed 's/^.*: //')
		# Record output name
		if [[ -z "$total_sub_track" ]] || [[ "$total_sub_track" = "1" ]]; then
			lst_wav+=("${files%.*}".wav)
		else
			lst_wav+=("${files%.*}"-"$sub_track".wav)
		fi
		# Extract WAV
		(
			if [[ "$vgmstream_force_looping" = "1" ]]; then
				if [[ -z "$total_sub_track" ]] || [[ "$total_sub_track" = "1" ]]; then
					"$vgmstream_cli_bin" -e -o "${files%.*}".wav "$files"
				else
					# Multi track loop
					for sub_track in $(seq -w 1 "$total_sub_track"); do
						"$vgmstream_cli_bin" -e -s "$sub_track" -o "${files%.*}"-"$sub_track".wav "$files"
					done
				fi
			else
				if [[ -z "$total_sub_track" ]] || [[ "$total_sub_track" = "1" ]]; then
					"$vgmstream_cli_bin" -o "${files%.*}".wav "$files"
				else
					# Multi track loop
					for sub_track in $(seq -w 1 "$total_sub_track"); do
						"$vgmstream_cli_bin" -s "$sub_track" -o "${files%.*}"-"$sub_track".wav "$files"
					done
				fi
			fi
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Flac loop
	for files in "${lst_wav[@]}"; do
		# Tag
		tag_song
		# Remove silence
		wav_remove_silent
		# Peak normalisation to 0, false stereo detection 
		wav_normalization_channel_test
		# Fade out, vgmstream fade out default off, special case for files: his
		if [[ "$force_fade_out" = "1" ]]; then
			wav_fade_out
		fi
		# Flac conversion
		(
		wav2flac
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_zxtune_ay() {			# Amstrad CPC, ZX Spectrum
if (( "${#lst_zxtune_ay[@]}" )); then
	# Bin check & set
	zxtune123_bin

	for files in "${lst_zxtune_ay[@]}"; do
		# Tag extract
		"$zxtune123_bin" --null device=/dev/null "${files[0]}" > "$vgm2flac_cache_tag"
		tag_ay
		tag_questions
		tag_album

		# Wav loop by track
		for sub_track in $(seq -w 1 99); do
			# Extract WAV
			"$zxtune123_bin" --wav filename="${files%.*}".wav "$files"?#"$sub_track" > "$vgm2flac_cache_tag"
			# Break loop when fail
			if [ ! -f "${files%.*}".wav ]; then
				break
			fi
			# Tag
			tag_ay
			# Peak normalisation to 0, false stereo detection 
			wav_normalization_channel_test
			# Remove silence
			wav_remove_silent
			# Add fade out
			wav_fade_out
			# Flac conversion
			wav2flac
			# Clean
			mv "${files%.*}".wav "$sub_track - $tag_song".wav
			mv "${files%.*}".flac "$sub_track - $tag_song".flac
		done

		# Generate wav array
		list_wav_files
		# if no wav, try without subtrack
		if [ "${#lst_wav[@]}" -eq 0 ]; then
			# Extract WAV
			"$zxtune123_bin" --wav filename="${files%.*}".wav "$files" > "$vgm2flac_cache_tag"
			# Generate wav array
			list_wav_files
			# Tag
			tag_ay
			# Peak normalisation to 0, false stereo detection 
			wav_normalization_channel_test
			# Remove silence
			wav_remove_silent
			# Add fade out
			wav_fade_out
			# Flac conversion
			wav2flac
		fi

	done
fi
}
loop_zxtune_sid() {			# Commodore 64/128
if (( "${#lst_zxtune_sid[@]}" )); then
	# Bin check & set
	zxtune123_bin

	# Local variable
	local test_duration

	for files in "${lst_zxtune_sid[@]}"; do
		# Tag extract
		tag_sid
		tag_questions
		tag_album
		tag_song

		# Wav loop by track
		for sub_track in $(seq -w 1 99); do
			# Extract WAV
			"$zxtune123_bin" --wav filename="$sub_track - $tag_song"0.wav "$files"?#"$sub_track"

			if [[ "$sid_loops" = "1" ]]; then
				mv "$sub_track - $tag_song"0.wav "$sub_track - $tag_song".wav &>/dev/null
			else
				# 2 loops contruction
				test_duration=$(ffprobe -i "$sub_track - $tag_song"0.wav -show_format -v quiet | grep duration | sed 's/.*=//' | cut -f1 -d".")
				if [[ "$test_duration" -gt "$sid_duration_without_loop" ]] ; then
					# copy another wav if duration > 15s
					cp "$sub_track - $tag_song"0.wav "$sub_track - $tag_song"1.wav &>/dev/null
					# make clean loop without silence
					sox "$sub_track - $tag_song"0.wav temp-out0.wav silence 1 0.1 1% reverse silence 1 0.1 1% reverse
					sox "$sub_track - $tag_song"1.wav temp-out1.wav silence 1 0.1 1% reverse silence 1 0.1 1% reverse
					rm "$sub_track - $tag_song"0.wav "$sub_track - $tag_song"1.wav &>/dev/null
					mv temp-out0.wav "$sub_track - $tag_song"0.wav &>/dev/null
					mv temp-out1.wav "$sub_track - $tag_song"1.wav &>/dev/null
					# Concatenate loops
					sox "$sub_track - $tag_song"0.wav "$sub_track - $tag_song"1.wav "$sub_track - $tag_song".wav
					# Clean temp files
					rm "$sub_track - $tag_song"0.wav "$sub_track - $tag_song"1.wav &>/dev/null
				else
					mv "$sub_track - $tag_song"0.wav "$sub_track - $tag_song".wav &>/dev/null
				fi
			fi

			# Break loop when fail
			if [ ! -f "$sub_track - $tag_song".wav ]; then
				break
			fi
		done

		# Generate wav array
		list_wav_files

		# if no wav, try without subtrack
		if [ "${#lst_wav[@]}" -eq 0 ]; then
			# Extract WAV
			"$zxtune123_bin" --wav filename="$tag_song"0.wav "$files"

			if [[ "$sid_loops" = "1" ]]; then
				mv "$sub_track - $tag_song"0.wav "$sub_track - $tag_song".wav &>/dev/null
			else
				# 2 loops contruction
				test_duration=$(ffprobe -i "$tag_song"0.wav -show_format -v quiet | grep duration | sed 's/.*=//' | cut -f1 -d".")
				if [[ "$test_duration" -gt "$sid_duration_without_loop" ]] ; then
					# copy another wav if duration > 15s
					cp "$tag_song"0.wav "$tag_song"1.wav &>/dev/null
					# make clean loop without silence
					sox "$tag_song"0.wav temp-out0.wav silence 1 0.1 1% reverse silence 1 0.1 1% reverse
					sox "$tag_song"1.wav temp-out1.wav silence 1 0.1 1% reverse silence 1 0.1 1% reverse
					rm "$tag_song"0.wav "$tag_song"1.wav &>/dev/null
					mv temp-out0.wav "$tag_song"0.wav &>/dev/null
					mv temp-out1.wav "$tag_song"1.wav &>/dev/null
					# Concatenate loops
					sox "$tag_song"0.wav "$tag_song"1.wav "$tag_song".wav
					# Clean temp files
					rm "$tag_song"0.wav "$tag_song"1.wav &>/dev/null
				else
					mv "$tag_song"0.wav "$tag_song".wav &>/dev/null
				fi
			fi
			# Generate wav array
			list_wav_files
		fi

	done

	# Flac loop
	for files in "${lst_wav[@]}"; do
		# Tag
		tag_song="[untitled]"
		# Peak normalisation to 0, false stereo detection 
		wav_normalization_channel_test
		# Remove silence
		wav_remove_silent
		# Add fade out
		wav_fade_out
		# Flac conversion
		(
		wav2flac
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

fi
}
loop_zxtune_xfs() {			# PS1, PS2, NDS, Saturn, GBA, N64, Dreamcast
if (( "${#lst_zxtune_xsf[@]}" )); then
	# Bin check & set
	zxtune123_bin

	# Local variables
	local file_name_base
	local file_name
	local file_name_random

	# Wav loop
	for files in "${lst_zxtune_xsf[@]}"; do
		# Tag (one time)
		if [[ "$files" = "${lst_zxtune_xsf[0]}" ]];then
			tag_xfs
			tag_questions
			tag_album
		fi
		# Extract WAV
		file_name_base="${files%.*}"
		file_name="${file_name_base##*/}"
		file_name_random=$(( RANDOM % 10000 ))
		(
		"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$files" \
			&& mv output-"$file_name_random".wav "${file_name##*/}".wav
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Flac/tag loop
	for files in "${lst_zxtune_xsf[@]}"; do
		# Tag
		tag_xfs
		tag_questions
		tag_album

		# Peak normalisation to 0, false stereo detection 
		wav_normalization_channel_test
		# Remove silence
		wav_remove_silent
		# Consider fade out if N64 files not have tag_length
		if [ "${files##*.}" = "miniusf" ] || [ "${files##*.}" = "usf" ]; then
			if [[ -z "$tag_length" ]]; then
				wav_fade_out
			fi
		fi
		# Flac conversion
		(
		wav2flac
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_zxtune_ym() {			# Amstrad CPC, Atari ST (YM2149)
if (( "${#lst_zxtune_ym[@]}" )); then
	# Bin check & set
	zxtune123_bin

	# Local variables
	local file_name_base
	local file_name

	# Tag
	tag_questions
	tag_album
	
	# Wav loop
	for files in "${lst_zxtune_ym[@]}"; do
		# Extract WAV
		file_name_base="${files%.*}"
		file_name="${file_name_base##*/}"
		(
		"$zxtune123_bin" --wav filename="${file_name##*/}".wav "$files"
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Generate wav array
	list_wav_files

	# Flac loop
	for files in "${lst_wav[@]}"; do
		# Tag
		tag_song
		# Peak normalisation to 0, false stereo detection 
		wav_normalization_channel_test
		# Remove silence
		wav_remove_silent
		# Add fade out
		wav_fade_out
		# Flac conversion
		(
		wav2flac
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_zxtune_zx_spectrum() {	# ZX Spectrum
if (( "${#lst_zxtune_zx_spectrum[@]}" )); then
	# Bin check & set
	zxtune123_bin

	# Local variables
	local file_name_base
	local file_name

	# Tag
	tag_machine="ZX Spectrum"
	tag_questions
	tag_album
	
	# Wav loop
	for files in "${lst_zxtune_zx_spectrum[@]}"; do
		# Extract WAV
		file_name_base="${files%.*}"
		file_name="${file_name_base##*/}"
		(
		"$zxtune123_bin" --wav filename="${file_name##*/}".wav "$files"
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Generate wav array
	list_wav_files

	# Flac loop
	for files in "${lst_wav[@]}"; do
		# Tag
		tag_song
		# Peak normalisation to 0, false stereo detection 
		wav_normalization_channel_test
		# Remove silence
		wav_remove_silent
		# Add fade out
		wav_fade_out
		# Flac conversion
		(
		wav2flac
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}

# Tag common
tag_track() {
if [ "${#lst_flac[@]}" -gt "0" ] && [ "${#lst_wav[@]}" -gt "0" ]; then		# If number of flac > 0
local tag_track_count
local count
	for files in "${lst_flac[@]}"; do
		tag_track_count=$(($count+1))
		count="$tag_track_count"

		# Add lead zero if necessary
		if [ "${#lst_flac[@]}" -lt "100" ]; then
			if [[ "${#tag_track_count}" -eq "1" ]] ; then				# if integer in one digit
				local tag_track_count="0$tag_track_count" 
			fi
		elif [ "${#lst_flac[@]}" -ge "100" ]; then
			if [[ "${#tag_track_count}" -eq "1" ]] ; then				# if integer in one digit
				local tag_track_count="00$tag_track_count"
			elif [[ "${#tag_track_count}" -eq "2" ]] ; then				# if integer in two digit
				local tag_track_count="0$tag_track_count"
			fi
		fi

		ffmpeg $ffmpeg_log_lvl -i "$files" -c:v copy -c:a copy -metadata TRACKNUMBER="$tag_track_count" \
			-metadata TRACK="$tag_track_count" "${files%.*}"-temp.flac
		# If temp-file exist remove source and rename
		if [[ -f "${files%.*}-temp.flac" && -s "${files%.*}-temp.flac" ]]; then
			rm "$files" &>/dev/null
			mv "${files%.*}"-temp.flac "$files" &>/dev/null
		fi
	done
fi
}
tag_questions() {
if ! [[ "$no_flac" = "1" ]]; then
	if test -z "$tag_game"; then
		echo "Please indicate the game title (leave empty for [unknown])"
		read -r -e -p " -> " tag_game
		echo
		if test -z "$tag_game"; then
			tag_game="unknown"
		fi
	fi
	if test -z "$tag_artist"; then
		echo "Please indicate the artist (leave empty for [unknown])"
		read -r -e -p " -> " tag_artist
		echo
		if test -z "$tag_artist"; then
			tag_artist="unknown"
		fi
	fi
	if test -z "$tag_date"; then
		echo "Please indicate the release date"
		read -r -e -p " -> " tag_date
		echo
		if test -z "$tag_date"; then
			tag_date="NULL"
			tag_date_formated=""
		fi
	elif [[ "$tag_date" = "NULL" ]]; then
		tag_date_formated=""
	else
		tag_date_formated="$tag_date"
	fi
	if test -z "$tag_machine"; then
		echo "Please indicate the release platform"
		read -r -e -p " -> " tag_machine
		echo
		if test -z "$tag_machine"; then
			tag_machine="NULL"
		fi
	fi
fi
}
tag_album() {
# Local variables
local tag_machine_album_formated
local tag_pc_sound_module_album_formated

# If tag exist add ()
if ! [[ "$tag_machine" = "NULL" ]]; then
	tag_machine_album_formated=$(echo "$tag_machine" | sed 's/\(.*\)/\(\1\)/')
fi
if [[ -n "$tag_pc_sound_module" ]]; then
	tag_pc_sound_module_album_formated=$(echo "$tag_pc_sound_module" | sed 's/\(.*\)/\(\1\)/')
fi

# Album tag
tag_album=$(echo "$tag_game $tag_machine_album_formated $tag_pc_sound_module_album_formated" | sed 's/ *$//')
}
tag_song() {
tag_song=$(basename "${files%.*}")
}

# Tag by files type
tag_m3u_clean_extract() {
# Local variable
local m3u_track_hex_test

m3u_track_hex_test=$(cat "$m3u_file" |  awk -F"," '{ print $2 }' | grep -F -e "$")
if [[ -z "$m3u_track_hex_test" ]]; then													# Decimal track
	cat "$m3u_file" | sed '/^#/d' | sed 's/\\//g' | uniq | sed -r '/^\s*$/d' | sort -t, -k2,2 -n \
	| sed 's/.*::/GAME::/' | sed -e 's/\\,/ -/g' > "$vgm2flac_cache_tag"
else																					# Hexadecimal track
	cat "$m3u_file" | sed '/^#/d' | sed 's/\\//g' | uniq | sed -r '/^\s*$/d' \
	| tr -d '$' | awk --non-decimal-data -F ',' -v OFS=',' '$1 {$2=("0x"$2)+0; print}' \
	| sort -t, -k2,2 -n | sed 's/.*::/GAME::/' | sed -e 's/\\,/ -/g' > "$vgm2flac_cache_tag"
fi
}
tag_xxs_loop() {			# Game Boy (gbs), NES (nsf), PC-Enginge (HES)
if [ "${#lst_m3u[@]}" -gt "0" ]; then

	# Local variables
	local tag_track_test
	local xxs_duration
	local xxs_duration_format
	local xxs_fading
	local xxs_fading_format

	# Prevent track start at 0 in m3u
	tag_track_test=$(cat "$vgm2flac_cache_tag" | head -1 | awk -F"," '{ print $2 }')

	tag_song=$(cat "$vgm2flac_cache_tag" | awk -v var=$xxs_track -F',' '$2 == var { print $0 }' | awk -F"," '{ print $3 }')
	if [[ -z "$tag_song" ]]; then
		tag_song="[untitled]"
	fi

	# Get fade out and duration
	xxs_duration=$(cat "$vgm2flac_cache_tag" | grep ",$xxs_track," \
					| awk -F"," '{ print $4 }' | tr -d '[:space:]' \
					| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')					# Total duration in ?:m:s
	if [[ -n "$xxs_duration" ]]; then
		xxs_duration_format=$(echo "$xxs_duration"| grep -o ":" | wc -l)
		if [[ "$xxs_duration_format" = "2" ]]; then										# If duration is in this format = h:m:s
			xxs_duration=$(echo "$xxs_duration" | awk -F":" '{ print ($2":"$3) }')
		elif [[ "$xxs_duration_format" = "0" && -n "$xxs_duration" ]]; then				# If duration is in this format = s
			xxs_duration=$(echo "$xxs_duration" | sed 's/^/00:/')
		fi
		xxs_duration_second=$(echo "$xxs_duration" | awk -F":" '{ print ($1 * 60) + $2 }' | tr -d '[:space:]')	# Total duration in s
		# Duration value
		xxs_duration_second=$(($xxs_duration_second+1))															# Total duration in s + 1s
		xxs_duration_msecond=$(($xxs_duration_second*1000))														# Total duration in ms
	else
		# Duration value
		xxs_duration_second="$xxs_default_max_duration"
		xxs_duration_msecond=$(($xxs_default_max_duration*1000))
	fi

	# Fade out
	xxs_fading=$(cat "$vgm2flac_cache_tag" | grep ",$xxs_track," \
				| awk -F"," '{ print $(NF) }' | tr -d '[:space:]' \
				| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')						# Fade out duration in ?:m:s
	if [[ -n "$xxs_fading" ]]; then
		xxs_fading_format=$(echo "$xxs_fading"| grep -o ":" | wc -l)
		if [[ "$xxs_fading_format" = "2" ]]; then										# If duration is in this format = h:m:s
			xxs_fading=$(echo "$xxs_fading" | awk -F":" '{ print ($2":"$3) }')
		elif [[ "$xxs_fading_format" = "0" && -n "$xxs_fading" ]]; then					# If duration is in this format = s
			xxs_fading=$(echo "$xxs_fading" | sed 's/^/00:/')
		fi
		# Fading value
		xxs_fading_second=$(echo "$xxs_fading" | awk -F":" '{ print ($1 * 60) + $2 }' | tr -d '[:space:]')			# Fade out duration in s
		xxs_fading_msecond=$(($xxs_fading_second*1000))																# Fade out duration in ms
	else
		xxs_fading_second="0"
	fi

	# nsfplay fading correction if empty (.nsf apply only)
	if [[ "$xxs_fading_second" = 0 && "xxs_duration_second" -gt "10" ]]; then
		xxs_fading_msecond=$(($default_wav_fade_out*1000))
	fi

	# Prevent incoherence duration between fade out and total duration
	if [[ "$xxs_fading_second" -ge "xxs_duration_second" ]]; then
		unset xxs_fading_second
		xxs_fading_msecond="0"
	fi

else
	tag_song="[untitled]"
	xxs_duration_second="$xss_default_max_duration"

	# nsfplay duration & fading s to ms
	xxs_duration_msecond=$(($xxs_default_max_duration*1000))
	xxs_fading_msecond=$(($default_wav_fade_out*1000))
fi
}
tag_ay() {					# Amstrad CPC, ZX Spectrum
# Tag extract
tag_song=$(sed -n 's/Title:/&\n/;s/.*\n//p' "$vgm2flac_cache_tag" | awk '{$1=$1}1')
if [[ -z "$tag_song" ]] || [ "$tag_song" = "?" ]; then
	tag_song="[untitled]"
fi

tag_artist_backup="$tag_artist"
tag_artist=$(sed -n 's/Author:/&\n/;s/.*\n//p' "$vgm2flac_cache_tag" | awk '{$1=$1}1')
if [[ -z "$tag_artist" ]]; then
	tag_artist="$tag_artist_backup"
elif [ "$tag_artist" = "?" ]; then
	tag_artist=""
fi

}
tag_gbs_extract() {			# GB/GBC		- Tag extraction & m3u cleaning
# Tag extract by hexdump
tag_game=$(xxd -ps -s 0x10 -l 32 "$gbs" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
tag_artist=$(xxd -ps -s 0x30 -l 32 "$gbs" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')

# If m3u
if [ "${#lst_m3u[@]}" -gt "0" ]; then
	m3u_file="${gbs%.*}.m3u"
	m3u_track_hex_test=$(cat "${gbs%.*}".m3u |  awk -F"," '{ print $2 }' | grep -F -e "$")
	tag_m3u_clean_extract
fi
}
tag_hes_extract() {			# PC Engine		- Tag extraction & m3u cleaning
# If m3u
if [ "${#lst_m3u[@]}" -gt "0" ]; then
	m3u_file="${hes%.*}.m3u"
	tag_game=$(cat "${hes%.*}".m3u | grep "@TITLE" | awk -v n=3 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' | tr -d "\n\r")
	tag_artist=$(cat "${hes%.*}".m3u | grep "@COMPOSER" | awk -v n=3 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' | tr -d "\n\r")
	tag_date=$(cat "${hes%.*}".m3u | grep "@DATE" | awk -v n=3 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' | tr -d "\n\r")
	tag_m3u_clean_extract
fi
}
tag_nsf_extract() {			# NES			- Tag extraction & m3u cleaning
# Tag extract by hexdump
tag_game=$(xxd -ps -s 0x00E -l 32 "$nsf" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
tag_artist=$(xxd -ps -s 0x02E -l 32 "$nsf" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')

# If m3u
if [ "${#lst_m3u[@]}" -gt "0" ]; then
	m3u_file="${nsf%.*}.m3u"
	tag_m3u_clean_extract
fi
}
tag_nsfe() {				# NES
# Local variable
local nsfplay_sub_track

# Tag extract
"$nsfplay_bin" "$nsfe" > "$vgm2flac_cache_tag"

nsfplay_sub_track="${sub_track}:"

tag_song=$(cat "$vgm2flac_cache_tag" | grep "$nsfplay_sub_track" | sed -n "s/$nsfplay_sub_track/&\n/;s/.*\n//p" | awk '{$1=$1}1')
if [[ -z "$tag_song" ]]; then
	tag_song="[untitled]"
fi

tag_artist_backup="$tag_artist"
tag_artist=$(sed -n 's/Artist:/&\n/;s/.*\n//p' "$vgm2flac_cache_tag" | awk '{$1=$1}1')
if [[ -z "$tag_artist" ]]; then
	tag_artist="$tag_artist_backup"
fi

if [[ -z "$tag_game" ]]; then
	tag_game=$(sed -n 's/Title:/&\n/;s/.*\n//p' "$vgm2flac_cache_tag" | awk '{$1=$1}1')
fi

# Set max duration s to ms
nsfplay_default_max_duration=$(($xxs_default_max_duration*1000))
}
tag_s98() {					# NEC PC-6001, PC-6601, PC-8801,PC-9801, Sharp X1, Fujitsu FM-7 & FM TownsSharp X1
# Tag extract
strings "$files" > "$vgm2flac_cache_tag"

tag_song=$(cat "$vgm2flac_cache_tag" | grep -i -a title | sed 's/^.*=//' | head -1)
if [[ -z "$tag_song" ]]; then
	tag_song
fi

tag_artist_backup="$tag_artist"
tag_artist=$(cat "$vgm2flac_cache_tag" | grep -i -a artist | sed 's/^.*=//' | head -1)
if [[ -z "$tag_artist" ]]; then
	tag_artist="$tag_artist_backup"
fi

if [[ -z "$tag_game" && -z "$tag_machine" && -z "$tag_date" ]]; then
	tag_game=$(cat "$vgm2flac_cache_tag" | grep -i -a game | sed 's/^.*=//' | head -1)
	tag_machine=$(cat "$vgm2flac_cache_tag" | grep -i -a system | sed 's/^.*=//' | head -1)
	tag_date=$(cat "$vgm2flac_cache_tag" | grep -i -a year | sed 's/^.*=//' | head -1)
fi
}
tag_sid() {					# Commodore 64/128
# Tag extract by hexdump
if [[ -z "$tag_artist" ]]; then
	tag_artist=$(xxd -ps -s 0x36 -l 32 "$files" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
fi
if [ "$tag_artist" = "<?>" ]; then
	tag_artist=""
fi

if [[ -z "$tag_game" ]]; then
	tag_game=$(xxd -ps -s 0x16 -l 32 "$files" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
fi
if [ "$tag_game" = "<?>" ]; then
	tag_game=""
fi
}
tag_spc() {					# SNES
# Local variable
local id666_test

# Tag extract by hexdump
id666_test=$(xxd -ps -s 0x00023h -l 1 "$files")			# Test ID666 here
if [ "$id666_test" = "1a" ]; then						# 1a hex = 26 dec
	tag_song=$(xxd -ps -s 0x0002Eh -l 32 "$files" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
	if [[ -z "$tag_song" ]]; then
		tag_song
	fi

	tag_artist_backup="$tag_artist"
	tag_artist=$(xxd -ps -s 0x000B1h -l 32 "$files" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
	if [[ -z "$tag_artist" ]]; then
		tag_artist="$tag_artist_backup"
	fi

	if [[ -z "$tag_game" ]]; then
		tag_game=$(xxd -ps -s 0x0004Eh -l 32 "$files" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
	fi
	spc_duration=$(xxd -ps -s 0x000A9h -l 3 "$files" | xxd -r -p | tr -d '\0')	# In s
	spc_fading=$(xxd -ps -s 0x000ACh -l 5 "$files" | xxd -r -p | tr -d '\0')	# In ms

	# Duration correction if empty, or not an integer
	if [[ -z "$spc_duration" ]] || ! [[ "$spc_duration" =~ ^[0-9]*$ ]]; then
		spc_duration="$spc_default_duration"
	fi

	# Fading correction if empty, or not an integer
	if [[ -z "$spc_fading" ]] || ! [[ "$spc_fading" =~ ^[0-9]*$ ]]; then
		spc_fading=$(($default_wav_fade_out*1000))
	fi

	# Prevent incoherence duration between fade out and total duration
	if [[ "$spc_duration" -ge "spc_fading" ]]; then
		spc_fading="0"
	fi

fi
if [[ -z "$tag_machine" ]]; then
	tag_machine="SNES"
fi
}
tag_vgm() {					# Various machines
# Tag extract
"$vgm_tag_bin" -ShowTag8 "$files" > "$vgm2flac_cache_tag"

tag_song=$(sed -n 's/Track Title:/&\n/;s/.*\n//p' "$vgm2flac_cache_tag" | awk '{$1=$1}1')
if [[ -z "$tag_song" ]]; then
	tag_song
fi

tag_artist_backup="$tag_artist"
tag_artist=$(sed -n 's/Composer:/&\n/;s/.*\n//p' "$vgm2flac_cache_tag" | awk '{$1=$1}1')
if [[ -z "$tag_artist" ]]; then
	tag_artist="$tag_artist_backup"
fi

if [[ -z "$tag_game" && -z "$tag_machine" && -z "$tag_date" ]]; then
	tag_game=$(sed -n 's/Game Name:/&\n/;s/.*\n//p' "$vgm2flac_cache_tag" | awk '{$1=$1}1')
	tag_machine=$(sed -n 's/System:/&\n/;s/.*\n//p' "$vgm2flac_cache_tag" | awk '{$1=$1}1')
	tag_date=$(sed -n 's/Release:/&\n/;s/.*\n//p' "$vgm2flac_cache_tag" | awk '{$1=$1}1')
fi
}
tag_xfs() {					# PS1, PS2, NDS, Saturn, GBA, N64, Dreamcast
# Tag extract
strings "$files" | sed -n '/TAG/,$p' > "$vgm2flac_cache_tag"

tag_song=$(cat "$vgm2flac_cache_tag" | grep -i -a title= | sed 's/^.*=//')
if [[ -z "$tag_song" ]]; then
	tag_song
fi

tag_artist_backup="$tag_artist"
tag_artist=$(cat "$vgm2flac_cache_tag" | grep -i -a artist= | sed 's/^.*=//')
if [[ -z "$tag_artist" ]]; then
	tag_artist="$tag_artist_backup"
fi

if [[ -z "$tag_game" && -z "$tag_date" ]]; then
	tag_game=$(cat "$vgm2flac_cache_tag" | grep -i -a game= | sed 's/^.*=//')
	tag_date=$(cat "$vgm2flac_cache_tag" | grep -i -a year= | sed 's/^.*=//')
fi

if [[ "${files##*.}" = "psf" || "${files##*.}" = "minipsf" ]]; then
	tag_machine="PS1"
elif [[ "${files##*.}" = "psf2" || "${files##*.}" = "minipsf2" ]]; then
	tag_machine="PS2"
elif [[ "${files##*.}" = "2sf" || "${files##*.}" = "mini2sf" || "${files##*.}" = "minincsf" || "${files##*.}" = "ncsf" ]]; then
	tag_machine="DS"
elif [[ "${files##*.}" = "ssf" || "${files##*.}" = "minissf" ]]; then
	tag_machine="Saturn"
elif [[ "${files##*.}" = "gsf" || "${files##*.}" = "minigsf" ]]; then
	tag_machine="GBA"
elif [[ "${files##*.}" = "usf" || "${files##*.}" = "miniusf" ]]; then
	tag_machine="N64"
elif [[ "${files##*.}" = "dsf" ]]; then
	tag_machine="Dreamcast"
fi

# N64, get tag lenght for test in loop, notag=notimepoint -> fadeout
if [ "${files##*.}" = "miniusf" ] || [ "${files##*.}" = "usf" ]; then
	tag_length=$(cat "$vgm2flac_cache_tag" | grep -i -a length= | sed 's/^.*=//')
fi
}

# Temp clean & target filename/directory structure
rename_add_lead_zero() {
# Local variables
local number
local padded
local new_name

# Populate wav array & rename
list_wav_files
if [ "${#lst_wav[@]}" -gt "0" ]; then											# If number of wav > 0
	for files in "${lst_wav[@]}"; do
		number=$(echo "$files" | sed 's/[^0-9]*//g')
		padded=$(printf "%02d" "${number#0}")
		new_name=$(echo "$files" | sed "s/${number}/${padded}/")
		mv "$files" "$new_name" &>/dev/null
	done
fi
}
wav_remove() {
if [ "${#lst_wav[@]}" -gt "0" ]; then											# If number of wav > 0
	read -r -e -p "Remove wav files (temp audio)? [y/N]:" qarm
	case $qarm in
		"Y"|"y")
			for files in "${lst_wav[@]}"; do
				rm -f "$files" &>/dev/null
			done
		;;
	esac
fi
}
flac_corrupted_remove() {
if [ "${#lst_flac_in_error[@]}" -gt "0" ]; then											# If number of flac corrupted > 0
	for files in "${lst_flac_in_error[@]}"; do
		rm -f "$files" &>/dev/null
	done
fi
}
mk_target_directory() {
# Local variables
local tag_game_dir
local tag_machine_dir
local tag_date_dir
local tag_pc_sound_module_dir
local target_directory

# Get tag, mkdir & mv
if [ "${#lst_flac[@]}" -gt "0" ] && [ "${#lst_wav[@]}" -gt "0" ]; then		# If number of flac > 0
	# If tag exist add () & replace eventualy "/" & ":" in string
	tag_game_dir=$(echo "$tag_game" | sed s#/#-#g | sed s#:#-#g)					# Replace eventualy "/" & ":" in string
	if ! [[ "$tag_machine" = "NULL" ]]; then
		tag_machine_dir=$(echo "$tag_machine" | sed s#/#-#g | sed s#:#-#g | sed 's/\(.*\)/\(\1\)/')
	fi
	if ! [[ "$tag_date" = "NULL" ]]; then
		tag_date_dir=$(echo "$tag_date" | sed s#/#-#g | sed s#:#-#g | sed 's/\(.*\)/\(\1\)/')
	fi
	if [[ -n "$tag_pc_sound_module" ]]; then
		tag_pc_sound_module_dir=$(echo "$tag_pc_sound_module" | sed s#/#-#g | sed s#:#-#g | sed 's/\(.*\)/\(\1\)/')
	fi
	target_directory=$(echo "$tag_game_dir $tag_date_dir $tag_machine_dir $tag_pc_sound_module_dir" | sed 's/ *$//')

	# Create target dir & mv
	if [ ! -d "$PWD/$target_directory" ]; then
		mkdir "$PWD/$target_directory" &>/dev/null
	fi
	for files in "${lst_flac[@]}"; do
		mv "$files" "$PWD/$target_directory" &>/dev/null
	done
fi
}
end_functions() {
if [[ "$no_flac" = "1" ]]; then
	clean_cache_directory
else
	if [[ "$flac_loop_activated" = "1" ]]; then
		list_wav_files
		list_flac_files
		list_flac_validation
		flac_corrupted_remove
		flac_force_pal_tempo
		tag_track
		mk_target_directory
		clean_cache_directory
		display_flac_in_error
		wav_remove
	fi
fi
}

# Arguments variables
while [[ $# -gt 0 ]]; do
	key="$1"
	case "$key" in
	-h|--help)																# Help
		cmd_usage
		exit
	;;
	---pal)
		flac_force_pal="1"													# Set pal mode
	;;
	--no_fade_out)
		no_fade_out="1"														# Set force no fade out
	;;
	--no_flac)
		no_flac="1"															# Set force wav temp. files only
	;;
	--no_normalization)
		no_normalization="1"												# Set force no peak db norm. & channel test
	;;
	--no_remove_silence)
		no_remove_silence="1"												# Set force no remove silence
	;;
	*)
		cmd_usage
		exit
	;;
esac
shift
done

# Bin check & set
common_bin

# Files source check & set
check_cache_directory
list_source_files

# Encoding/tag loop
loop_adplay
loop_bchunk
loop_ffmpeg
loop_ffmpeg_gbs
loop_ffmpeg_hes
loop_midi
loop_nsfplay_nsf
loop_nsfplay_nsfe
loop_sc68
loop_sox
loop_vgm2wav
loop_zxtune_ay
loop_zxtune_sid
loop_zxtune_xfs
loop_zxtune_ym
loop_zxtune_zx_spectrum
loop_uade
loop_vgmstream
end_functions

exit
