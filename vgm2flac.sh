#!/bin/bash
# vgm2flac
# Bash tool for vgm encoding to flac
#
# Author: Romain Barbarot
# https://github.com/Jocker666z/vgm2flac
#
# licence : GNU GPL-2.0

# Paths
vgm2flac_cache="/tmp/vgm2flac"																# Cache directory
vgm2flac_cache_tag="$vgm2flac_cache/tag-$(date +%Y%m%s%N).info"								# Tag cache
export PATH=$PATH:/home/$USER/.local/bin													# For case of launch script outside a terminal

# Others
core_dependency=(awk bc ffmpeg ffprobe find sed sox xxd)
ffmpeg_log_lvl="-hide_banner -loglevel quiet"												# ffmpeg log level
nprocessor=$(nproc --all)																	# Set number of processor

# Output
default_wav_fade_out="6"																	# Fade out value in second, apply to all file during more than 10s
default_wav_bit_depth="pcm_s16le"															# Wav bit depth must be pcm_s16le, pcm_s24le or pcm_s32le
default_flac_bit_depth="s16"																# Flac bit depth must be s16 or s32
default_peakdb_norm="1"																		# Peak db normalization option, this value is written as positive but is used in negative, e.g. 4 = -4
default_silent_db_cut="85"																	# Silence db value for cut file
default_agressive_silent_db_cut="58"														# Agressive silence db value for cut file
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
vgm2wav_samplerate="48000"																	# Sample rate in Hz
vgm2wav_bit_depth="16"																		# Bit depth must be 16 or 24
vgm2wav_loops="2"
# vgmstream
vgmstream_loops="1"																			# Number of loop made by vgmstream

# Extensions
ext_adplay="hsq|imf|sdb|sqx|wlf"
ext_bchunk_cue="cue"
ext_bchunk_iso="bin|img|iso"
ext_ffmpeg_gbs="gbs"
ext_ffmpeg_hes="hes"
ext_ffmpeg_spc="spc"
ext_ffmpeg_xa="xa"
ext_midi="mid"
ext_nsfplay_nsf="nsf"
ext_nsfplay_nsfe="nsfe"
ext_sc68="snd|sndh"
ext_sox="bin|pcm|raw"
ext_playlist="m3u"
ext_vgm2wav="s98|vgm|vgz"
ext_zxtune_ay="ay"
ext_zxtune_sid="sid"
ext_zxtune_xsf="2sf|gsf|dsf|psf|psf2|mini2sf|minigsf|minipsf|minipsf2|minissf|miniusf|minincsf|ncsf|ssf|usf"
ext_zxtune_ym="ym"
ext_zxtune_zx_spectrum="asc|psc|pt2|pt3|sqt|stc|stp"

# Bin check and set variable
adplay_bin() {
local bin_name="adplay"
local system_bin_location
system_bin_location=$(command -v $bin_name)

if test -n "$system_bin_location"; then
	adplay_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
bchunk_bin() {
local bin_name="bchunk"
local system_bin_location
system_bin_location=$(command -v $bin_name)

if test -n "$system_bin_location"; then
	bchunk_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
fluidsynth_bin() {
local bin_name="fluidsynth"
local system_bin_location
system_bin_location=$(command -v $bin_name)
if test -n "$system_bin_location"; then
	if [[ -z "$fluidsynth_soundfont" ]]; then
		echo_pre_space "Warning, the variable (fluidsynth_soundfont) indicating the location"
		echo_pre_space "of the soundfont to use is not filled in, the result can be disgusting."
		echo_pre_space "Read documentation."
	elif ! [[ -f "$fluidsynth_soundfont" ]]; then
		echo_pre_space "Break, the variable (fluidsynth_soundfont) not indicating a file."
		echo_pre_space "Read documentation."
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
system_bin_location=$(command -v $bin_name)

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
system_bin_location=$(command -v $bin_name)

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
system_bin_location=$(command -v $bin_name)

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
system_bin_location=$(command -v $bin_name)

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
system_bin_location=$(command -v $bin_name)

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
system_bin_location=$(command -v $bin_name)

if test -n "$system_bin_location"; then
	vgmstream_cli_bin="$system_bin_location"
else
	echo_pre_space "Warning, $bin_name is not installed; Various machines files will not be detected"
fi
}
vgm_tag_bin() {
local bin_name="vgm_tag"
local system_bin_location
system_bin_location=$(command -v $bin_name)

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
system_bin_location=$(command -v $bin_name)

if test -n "$system_bin_location"; then
	uade123_bin="$system_bin_location"
else
	echo_pre_space "Warning, $bin_name is not installed; Amiga files will not be detected"
fi
}
zxtune123_bin() {
local bin_name="zxtune123"
local system_bin_location
system_bin_location=$(command -v $bin_name)

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
test_write_access() {
if ! [[ -w "$PWD" ]]; then
	chmod -R 775 "$PWD"
	if ! [[ -w "$PWD" ]]; then
		echo "vgm2flac fail: Current directory not writable"
		exit
	fi
fi
}

# Messages
cmd_usage() {
cat <<- EOF
vgm2flac - GNU GPL-2.0 Copyright - <https://github.com/Jocker666z/vgm2flac>
Bash tool for vgm/chiptune encoding to flac 

Usage: vgm2flac [options]
                          Without option treat current directory.
  --agressive_rm_silent   Force agressive mode for remove silent 85db->58db
  -h|--help               Display this help.
  --fade_out              Force default fade out.
  --no_fade_out           Force no fade out.
  --no_flac               Force output wav files only.
  --no_normalization      Force no peak db normalization.
  --no_remove_duplicate   Force no remove duplicate files.
  --no_remove_silence     Force no remove silence at start & end of track.
  --pal                   Force the tempo reduction to simulate 50hz.
  -v|--verbose            Verbose mode

EOF
}
echo_pre_space() {
local label
label="$1"

echo " $label"
}
display_separator() {
echo "--------------------------------------------------------------"
}
display_all_in_errors() {
if ! [[ "${#lst_wav_in_error[@]}" = "0" ]]; then
	display_separator
	echo_pre_space "WAV in error:"
	display_separator
	printf ' %s\n' "${lst_wav_in_error[@]}"
fi
if ! [[ "${#lst_wav_duplicate[@]}" = "0" ]]; then
	display_separator
	echo_pre_space "WAV duplicate:"
	display_separator
	printf ' %s\n' "${lst_wav_duplicate[@]}"
fi
if ! [[ "${#lst_flac_in_error[@]}" = "0" ]]; then
	display_separator
	echo_pre_space "FLAC in error:"
	display_separator
	printf ' %s\n' "${lst_flac_in_error[@]}"
fi
if ! [[ "${#lst_flac_duplicate[@]}" = "0" ]]; then
	display_separator
	echo_pre_space "FLAC duplicate:"
	display_separator
	printf ' %s\n' "${lst_flac_duplicate[@]}"
fi
}
display_loop_title() {
local command
local machine
command="$1"
machine="$2"

display_separator
echo_pre_space "working directory: $PWD"
echo_pre_space "vgm2flac - $command loop - $machine"
display_separator
}
display_convert_title() {
local extract_label
extract_label="$1"

if ! [[ "$no_flac" = "1" ]]; then
	if [[ "$extract_label" = "FLAC" ]]; then
		display_separator
	fi
	echo_pre_space "$extract_label conversion"
	display_separator
fi
}
display_remove_previous_line() {
printf '\e[A\e[K'
}
display_end_summary() {
local wav_size
local flac_size
local wav_size_in_mb
local flac_size_in_mb
local diff_in_s
local elapsed_time_formated

# Get wav size in bytes
if (( "${#lst_wav[@]}" )); then
	wav_size=$(wc -c "${lst_wav[@]}" | tail -1 | awk '{print $1;}')
else
	wav_size="0"
fi
# Wav in MB
wav_size_in_mb=$(bc <<< "scale=1; $wav_size / 1024 / 1024" | sed 's!\.0*$!!')
# Get flac size in bytes
if (( "${#lst_flac[@]}" )); then
	flac_size=$(wc -c "${lst_flac[@]}" | tail -1 | awk '{print $1;}')
else
	flac_size="0"
fi
# Flac in MB
flac_size_in_mb=$(bc <<< "scale=1; $flac_size / 1024 / 1024" | sed 's!\.0*$!!')
# If string start by "." add lead 0
if [[ "${wav_size_in_mb:0:1}" == "." ]]; then
	wav_size_in_mb="0$wav_size_in_mb"
fi
if [[ "${flac_size_in_mb:0:1}" == "." ]]; then
	flac_size_in_mb="0$flac_size_in_mb"
fi

# Timer
diff_in_s=$(( timer_stop - timer_start ))
elapsed_time_formated="$((diff_in_s/3600))h$((diff_in_s%3600/60))m$((diff_in_s%60))s"

# Print
display_separator
echo_pre_space "Summary"
display_separator
echo_pre_space "WAV  - ${#lst_wav[@]} file(s) - $wav_size_in_mb MB"
if ! [[ "$no_flac" = "1" ]]; then
	echo_pre_space "FLAC - ${#lst_flac[@]} file(s) - $flac_size_in_mb MB"
fi
echo_pre_space "Mono - ${#lst_wav_in_mono[@]} file(s)"
echo_pre_space "Normalized to -${default_peakdb_norm}dB - ${#lst_wav_normalized[@]} file(s)"
echo_pre_space "Encoding duration - $elapsed_time_formated"
}
progress_bar() {
# Local variables
local TotalFilesNB
local CurrentFilesNB
local ProgressTitle
local _progress
local _done
local _done
local _left

# arguments
CurrentFilesNB="$1"
TotalFilesNB="$2"

# Display variables
_progress=$(( ( ((CurrentFilesNB * 100) / TotalFilesNB) * 100 ) / 100 ))
_done=$(( (_progress * 4) / 10 ))
_left=$(( 40 - _done ))
_done=$(printf "%${_done}s")
_left=$(printf "%${_left}s")
ExtendLabel="${CurrentFilesNB}/${TotalFilesNB}"

# Progress bar display
echo -e -n "\r\e[0K ]${_done// /▇}${_left// / }[ ${_progress}% $ExtendLabel"
if [[ "$_progress" = "100" ]]; then
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
# Bin check & set
vgmstream_cli_bin
uade123_bin

# Local variables
local vgmstream_test_result
local uade_test_result
local progress_counter

mapfile -t lst_adplay < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_adplay')$' 2>/dev/null | sort)
mapfile -t lst_all_files < <(find "$PWD" -maxdepth 1 -type f 2>/dev/null | sort)
mapfile -t lst_bchunk_cue < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_bchunk_cue')$' 2>/dev/null | sort)
mapfile -t lst_bchunk_iso < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_bchunk_iso')$' 2>/dev/null | sort)
mapfile -t lst_ffmpeg_gbs < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_ffmpeg_gbs')$' 2>/dev/null | sort)
mapfile -t lst_ffmpeg_hes < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_ffmpeg_hes')$' 2>/dev/null | sort)
mapfile -t lst_ffmpeg_spc < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_ffmpeg_spc')$' 2>/dev/null | sort)
mapfile -t lst_ffmpeg_xa < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_ffmpeg_xa')$' 2>/dev/null | sort)
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

# vgmstream & uade test all files
if [ "${#uade123_bin}" -gt "0" ] || [ "${#vgmstream_cli_bin}" -gt "0" ]; then
	echo_pre_space "vgm2flac - Files test:"
	for files in "${lst_all_files[@]}"; do

		if ! [[ "${files##*.}" = "mod" ]]; then
			uade_test_result=$("$uade123_bin" -g "$files" 2>/dev/null)
		fi

		if ! [[ "${files##*.}" = "wav" || "${files##*.}" = "flac" ]]; then
			vgmstream_test_result=$("$vgmstream_cli_bin" -m "$files" 2>/dev/null)
		fi

		if [ "${#uade_test_result}" -gt "0" ] && [ "${#vgmstream_test_result}" -gt "0" ]; then
			lst_uade+=("$files")
		elif [ "${#uade_test_result}" -eq "0" ] && [ "${#vgmstream_test_result}" -gt "0" ]; then
			# Ignore txth
			test_ext_file="${files##*.}"
			if [ "${#vgmstream_test_result}" -gt "0" ] && ! [[ "${test_ext_file^^}" = "TXTH" ]]; then
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

		# Progress bar
		progress_counter=$(( progress_counter + 1 ))
		progress_bar "$progress_counter" "${#lst_all_files[@]}"

	done
fi
}
list_wav_files() {
mapfile -t lst_wav < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('wav')$' 2>/dev/null | sort)
}
list_flac_files() {
mapfile -t lst_flac < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('flac')$' 2>/dev/null | sort)
}

# Files cleaning
clean_wav_flac_validation() {
# Regenerate array
list_wav_files
list_flac_files

# FLAC test
if ! [[ "${#lst_flac[@]}" = "0" ]]; then
	# Local variable
	local flac_error_test

	for files in "${lst_flac[@]}"; do
		flac_error_test=$(soxi "$files" 2>/dev/null)
		if [ -z "$flac_error_test" ]; then
			lst_flac_in_error+=( "${files##*/}" )
			rm "${file2%.*}".flac &>/dev/null
		fi
	done

fi

# WAV test
if ! [[ "${#lst_wav[@]}" = "0" ]]; then
	# Local variable
	local wav_error_test
	local wav_empty_test

	for files in "${lst_wav[@]}"; do
		wav_error_test=$(soxi "$files" 2>/dev/null)
		wav_empty_test=$(sox "$files" -n stat 2>&1 | grep "Maximum amplitude:" | awk '{print $3}')
		if [ -z "$wav_error_test" ] || [[ "$wav_empty_test" = "0.000000" ]]; then
			lst_wav_in_error+=( "${files##*/}" )
			rm "${file2%.*}".wav &>/dev/null
		fi
	done

	# Regenerate array
	list_wav_files

	# Remove duplicate - https://superuser.com/a/386207/857763
	for file1 in "${lst_wav[@]}"; do
		for file2 in "${lst_wav[@]}"; do
			if [[ "$file1" != "$file2" && -e "$file1" && -e "$file2" ]]; then
				if diff "$file1" "$file2" > /dev/null; then
					if ! [[ "$no_remove_duplicate" = "1" ]]; then
						lst_wav_duplicate+=( "${file1##*/} = ${file2##*/} (removed)" )
						rm "${file2%.*}".wav &>/dev/null
						rm "${file2%.*}".flac &>/dev/null
					else
						lst_wav_duplicate+=( "${file1##*/} = ${file2##*/} (keep)" )
					fi
				fi
			fi
		done
	done

	# Regenerate array
	list_wav_files
	list_flac_files
fi
}

# Audio treatment
wav_remove_silent() {
if [[ -f "${files%.*}".wav ]]; then
	if ! [[ "$no_remove_silence" = "1" ]]; then

		# Local variable
		local test_duration
		local silent_db_cut

		# Agressive silent cut
		if [[ "$agressive_silence" = "1" ]]; then
			silent_db_cut="$default_agressive_silent_db_cut"
		else
			silent_db_cut="$default_silent_db_cut"
		fi

		# Remove silence from audio files while leaving gaps, if audio during more than 10s
		test_duration=$(ffprobe -i "${files%.*}".wav -show_format -v quiet | grep duration | sed 's/.*=//' | cut -f1 -d".")
		if ! [[ "$test_duration" = "N/A" ]]; then			 # If not a bad file
			if [[ "$test_duration" -gt 10 ]]; then
				# Remove silence at start & end
				sox "${files%.*}".wav temp-out.wav silence 1 0.2 -"$silent_db_cut"d reverse silence 1 0.2 -"$silent_db_cut"d reverse
				rm "${files%.*}".wav &>/dev/null
				mv temp-out.wav "${files%.*}".wav &>/dev/null
			fi
		fi

	fi
fi
}
wav_fade_out() {
if [[ -f "${files%.*}".wav ]]; then
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
				if [[ "$verbose" = "1" ]]; then
					sox "${files%.*}".wav temp-out.wav fade t "$sox_fade_in" "$duration" "$sox_fade_out"
				else
					sox "${files%.*}".wav temp-out.wav fade t "$sox_fade_in" "$duration" "$sox_fade_out" &>/dev/null
				fi
				rm "${files%.*}".wav &>/dev/null
				mv temp-out.wav "${files%.*}".wav &>/dev/null
			fi
		fi

	fi
fi
}
wav_normalization_channel_test() {
if [[ -f "${files%.*}".wav ]]; then

	# For active end functions
	flac_loop_activated="1"

	# Local variables
	local testdb
	local db
	local left_md5
	local right_md5
	local afilter
	local confchan

	# Test Volume, set normalization variable
	if ! [[ "$no_normalization" = "1" ]]; then
		testdb=$(ffmpeg -i "${files%.*}".wav -af "volumedetect" -vn -sn -dn -f null /dev/null 2>&1 | grep "max_volume" | awk '{print $5;}')

		if [[ "$testdb" = *"-"* ]] && (( $(echo "${testdb/-/} > $default_peakdb_norm" | bc -l) )); then
			db="$(echo "${testdb/-/}" | awk -v var="$default_peakdb_norm" '{print $1-var}')dB"
			afilter="-af volume=$db"
			# Record for summary
			lst_wav_normalized+=( "${files%.*}.wav" )
		fi
	fi

	# Channel test mono or stereo
	left_md5=$(ffmpeg -i "${files%.*}".wav -map_channel 0.0.0 -f md5 - 2>/dev/null)
	right_md5=$(ffmpeg -i "${files%.*}".wav -map_channel 0.0.1 -f md5 - 2>/dev/null)
	if [ "$left_md5" = "$right_md5" ]; then
		confchan="-channel_layout mono"
		# Record for summary
		lst_wav_in_mono+=( "${files%.*}.wav" )
	fi

	# Encoding Wav
	if [[ -n "$afilter" ]] || [[ -n "$confchan" ]]; then
		ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav $afilter $confchan -acodec "$default_wav_bit_depth" -f wav temp-out.wav
		rm "${files%.*}".wav &>/dev/null
		mv temp-out.wav "${files%.*}".wav &>/dev/null
	fi

fi
}
flac_force_pal_tempo() {
if ! [[ "$no_flac" = "1" ]]; then
	if (( "${#lst_flac[@]}" )); then
		if [[ "$flac_force_pal" = "1" ]]; then
			# In case of audio speed is to high, reduce tempo to simulate 50hz
			# 60hz - 50hz = 83.333333333% of orginal speed
			for files in "${lst_flac[@]}"; do
				if [[ "$verbose" = "1" ]]; then
					sox "$files" temp-out.flac tempo 0.83333333333
				else
					sox "$files" temp-out.flac tempo 0.83333333333 &>/dev/null
				fi
				rm "$files".flac &>/dev/null
				mv temp-out.flac "$files" &>/dev/null
			done
		fi
	fi
fi
}

# Audio convert command
cmd_adplay() {
if [[ "$verbose" = "1" ]]; then
	"$adplay_bin" "$files" -v --device "${files%.*}".wav --output=disk
else
	"$adplay_bin" "$files" --device "${files%.*}".wav --output=disk &>/dev/null \
		&& echo_pre_space "✓ WAV  <- ${files##*/}" || echo_pre_space "x WAV  <- ${files##*/}"
fi
}
cmd_bchunk() {
if [[ "$verbose" = "1" ]]; then
	"$bchunk_bin" -v -w "${lst_bchunk_iso[0]}" "${lst_bchunk_cue[0]}" "$track_name"-Track-
else
	"$bchunk_bin" -w "${lst_bchunk_iso[0]}" "${lst_bchunk_cue[0]}" "$track_name"-Track- &>/dev/null \
		&& echo_pre_space "✓ WAV  <- ${lst_bchunk_iso##*/}" || echo_pre_space "x WAV  <- ${lst_bchunk_iso##*/}"
fi
}
cmd_ffmpeg_gbs() {
if [[ "$verbose" = "1" ]]; then
	ffmpeg $ffmpeg_log_lvl -track_index "$sub_track" -y -i "$gbs" -t $xxs_duration_second -channel_layout mono -acodec pcm_s16le -ar 44100 \
		-f wav "$sub_track - $tag_song".wav
else
	ffmpeg $ffmpeg_log_lvl -track_index "$sub_track" -y -i "$gbs" -t $xxs_duration_second -channel_layout mono -acodec pcm_s16le -ar 44100 \
		-f wav "$sub_track - $tag_song".wav \
		&& echo_pre_space "✓ WAV  <- $sub_track - $tag_song" || echo_pre_space "x WAV  <- $sub_track - $tag_song"
fi
}
cmd_ffmpeg_hes() {
if [[ "$verbose" = "1" ]]; then
	ffmpeg $ffmpeg_log_lvl -track_index "$sub_track" -y -i "$hes" -t $xxs_duration_second -acodec pcm_s16le \
		-f wav "$sub_track - $tag_song".wav
else
	ffmpeg $ffmpeg_log_lvl -track_index "$sub_track" -y -i "$hes" -t $xxs_duration_second -acodec pcm_s16le \
		-f wav "$sub_track - $tag_song".wav \
		&& echo_pre_space "✓ WAV  <- $sub_track - $tag_song" || echo_pre_space "x WAV  <- $sub_track - $tag_song"
fi
}
cmd_ffmpeg_spc() {
if [[ "$verbose" = "1" ]]; then
	ffmpeg $ffmpeg_log_lvl -y -i "$files" -t $spc_duration_total -acodec pcm_s16le -ar 32000 -f wav "${files%.*}".wav
else
	ffmpeg $ffmpeg_log_lvl -y -i "$files" -t $spc_duration_total -acodec pcm_s16le -ar 32000 -f wav "${files%.*}".wav \
		&& echo_pre_space "✓ WAV  <- ${files##*/}" || echo_pre_space "x WAV  <- ${files##*/}"
fi
}
cmd_ffmpeg_xa() {
if [[ "$verbose" = "1" ]]; then
	ffmpeg $ffmpeg_log_lvl -y -i "$files" -acodec pcm_s16le -f wav "${files%.*}".wav
else
	ffmpeg $ffmpeg_log_lvl -y -i "$files" -acodec pcm_s16le -f wav "${files%.*}".wav \
		&& echo_pre_space "✓ WAV  <- ${files##*/}" || echo_pre_space "x WAV  <- ${files##*/}"
fi
}
cmd_fluidsynth_loop1() {
if [[ "$verbose" = "1" ]]; then
	"$fluidsynth_bin" -v -F "${files%.*}".wav "$fluidsynth_soundfont" "$files"
else
	"$fluidsynth_bin" -F "${files%.*}".wav "$fluidsynth_soundfont" "$files" &>/dev/null \
		&& echo_pre_space "✓ WAV  <- ${files##*/}" || echo_pre_space "x WAV  <- ${files##*/}"
fi
}
cmd_fluidsynth_loop2() {
if [[ "$verbose" = "1" ]]; then
	"$fluidsynth_bin" -v -F "${files%.*}".wav "$fluidsynth_soundfont" "$files" "$files"
else
	"$fluidsynth_bin" -F "${files%.*}".wav "$fluidsynth_soundfont" "$files" &>/dev/null \
		&& echo_pre_space "✓ WAV  <- ${files##*/}" || echo_pre_space "x WAV  <- ${files##*/}"
fi
}
cmd_munt() {
if [[ "$verbose" = "1" ]]; then
	"$munt_bin" -m "$munt_rom_path" -r 1 --output-sample-format=1 -p 44100 --src-quality=3 --analog-output-mode=2 -f \
		--record-max-end-silence=1000 -o "${files%.*}".wav "$files"
else
	"$munt_bin" -m "$munt_rom_path" -r 1 --output-sample-format=1 -p 44100 --src-quality=3 --analog-output-mode=2 -f \
		--record-max-end-silence=1000 -o "${files%.*}".wav "$files" &>/dev/null \
		&& echo_pre_space "✓ WAV  <- ${files##*/}" || echo_pre_space "x WAV  <- ${files##*/}"
fi
}
cmd_nsfplay_nsf() {
if [[ "$verbose" = "1" ]]; then
	"$nsfplay_bin" --fade_ms="$xxs_fading_msecond" --length_ms="$xxs_duration_msecond" --samplerate=44100 \
		--track="$sub_track" "$nsf" "$sub_track".wav \
		&& mv "$sub_track".wav "$sub_track - $tag_song".wav
else
	"$nsfplay_bin" --fade_ms="$xxs_fading_msecond" --length_ms="$xxs_duration_msecond" --samplerate=44100 --quiet \
		--track="$sub_track" "$nsf" "$sub_track".wav &>/dev/null \
		&& mv "$sub_track".wav "$sub_track - $tag_song".wav \
		&& echo_pre_space "✓ WAV  <- $sub_track - $tag_song" || echo_pre_space "x WAV  <- $sub_track - $tag_song"
fi
}
cmd_nsfplay_nsfe() {
if [[ "$verbose" = "1" ]]; then
	"$nsfplay_bin" --length_ms="$nsfplay_default_max_duration" --samplerate=44100 \
		--track="$sub_track" "$nsfe" "$sub_track".wav \
		&& mv "$sub_track".wav "$sub_track - $tag_song".wav
else
	"$nsfplay_bin" --length_ms="$nsfplay_default_max_duration" --samplerate=44100 --quiet \
		--track="$sub_track" "$nsfe" "$sub_track".wav &>/dev/null \
		&& mv "$sub_track".wav "$sub_track - $tag_song".wav &>/dev/null \
		&& echo_pre_space "✓ WAV  <- $sub_track - $tag_song" || echo_pre_space "x WAV  <- $sub_track - $tag_song"
fi
}
cmd_sc68() {
if [[ "$verbose" = "1" ]]; then
	"$sc68_bin" -l "$sc68_loops" -c -t "$sub_track" "$sc68_files" > "$sub_track".raw \
		&& sox -t raw -r 44100 -b 16 -c 2 -L -e signed-integer "$sub_track".raw "$sub_track - $track_name".wav
else
	"$sc68_bin" -qqq -l "$sc68_loops" -c -t "$sub_track" "$sc68_files" > "$sub_track".raw \
		&& sox -t raw -r 44100 -b 16 -c 2 -L -e signed-integer "$sub_track".raw "$sub_track - $track_name".wav \
		&& echo_pre_space "✓ WAV  <- $sub_track - $track_name" || echo_pre_space "x WAV  <- $sub_track - $track_name"
fi
}
cmd_sox() {
if [[ "$verbose" = "1" ]]; then
	sox -t raw -r "$sox_sample_rate" -b 16 -c "$sox_channel" -L -e signed-integer "$files" "${files%.*}".wav repeat "$sox_loop"
else
	sox -t raw -r "$sox_sample_rate" -b 16 -c "$sox_channel" -L -e signed-integer "$files" "${files%.*}".wav repeat "$sox_loop" &>/dev/null \
		&& echo_pre_space "✓ WAV  <- ${files##*/}" || echo_pre_space "x WAV  <- ${files##*/}"
fi
}
cmd_uade() {
if [[ "$verbose" = "1" ]]; then
	"$uade123_bin" --force-led=0 --one --silence-timeout 5 --panning 0.8 --subsong "$sub_track" "$files" -f "$file_name".wav
else
	"$uade123_bin" --force-led=0 --one --silence-timeout 5 --panning 0.8 --subsong "$sub_track" "$files" -f "$file_name".wav &>/dev/null \
		&& echo_pre_space "✓ WAV  <- $file_name" || echo_pre_space "x WAV  <- $file_name"
fi
}
cmd_vgm2wav() {
if [[ "$verbose" = "1" ]]; then
	"$vgm2wav_bin" --samplerate "$vgm2wav_samplerate" --bps "$vgm2wav_bit_depth" --loops "$vgm2wav_loops" \
		"$files" "${files%.*}".wav
else
	"$vgm2wav_bin" --samplerate "$vgm2wav_samplerate" --bps "$vgm2wav_bit_depth" --loops "$vgm2wav_loops" \
		"$files" "${files%.*}".wav &>/dev/null \
		&& echo_pre_space "✓ WAV  <- ${files##*/}" || echo_pre_space "x WAV  <- ${files##*/}"
fi
}
cmd_vgmstream() {
if [[ "$verbose" = "1" ]]; then
	"$vgmstream_cli_bin" -l "$vgmstream_loops" -o "${files%.*}".wav "$files"
else
	"$vgmstream_cli_bin" -l "$vgmstream_loops" -o "${files%.*}".wav "$files" &>/dev/null \
		&& echo_pre_space "✓ WAV  <- ${files##*/}" || echo_pre_space "x WAV  <- ${files##*/}"
fi
}
cmd_vgmstream_multi_track() {
if [[ "$verbose" = "1" ]]; then
	"$vgmstream_cli_bin" -l "$vgmstream_loops" -s "$sub_track" -o "${files%.*}"-"$sub_track".wav "$files"
else
	"$vgmstream_cli_bin" -l "$vgmstream_loops" -s "$sub_track" -o "${files%.*}"-"$sub_track".wav "$files" &>/dev/null \
		&& echo_pre_space "✓ WAV  <- ${files%.*}-$sub_track" || echo_pre_space "x WAV  <- ${files%.*}-$sub_track"
fi
}
cmd_zxtune_ay() {
if [[ "$verbose" = "1" ]]; then
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$ay" \
		&& mv output-"$file_name_random".wav "$tag_song".wav
else
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$ay" &>/dev/null \
		&& mv output-"$file_name_random".wav "$tag_song".wav &>/dev/null \
		&& echo_pre_space "✓ WAV  <- ${ay##*/}" || echo_pre_space "x WAV  <- ${ay##*/}"
fi
}
cmd_zxtune_ay_multi_track() {
if [[ "$verbose" = "1" ]]; then
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$ay"?#"$sub_track" \
		&& mv output-"$file_name_random".wav "$sub_track".wav
else
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$ay"?#"$sub_track" &>/dev/null \
		&& mv output-"$file_name_random".wav "$sub_track".wav \
		&& echo_pre_space "✓ WAV  <- $sub_track - ${ay##*/}" || echo_pre_space "x WAV  <- $sub_track - ${ay##*/}"
fi
}
cmd_zxtune_sid() {
if [[ "$verbose" = "1" ]]; then
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$files" \
		&& mv output-"$file_name_random".wav "$tag_song"0.wav
else
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$files" &>/dev/null \
		&& mv output-"$file_name_random".wav "$tag_song"0.wav &>/dev/null \
		&& echo_pre_space "✓ WAV  <- ${files##*/}" || echo_pre_space "x WAV  <- ${files##*/}"
fi
}
cmd_zxtune_sid_multi_track() {
if [[ "$verbose" = "1" ]]; then
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$files"?#"$sub_track" \
	&& mv output-"$file_name_random".wav "$sub_track - $tag_song"0.wav
else
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$files"?#"$sub_track" &>/dev/null \
		&& mv output-"$file_name_random".wav "$sub_track - $tag_song"0.wav &>/dev/null \
		&& echo_pre_space "✓ WAV  <- $sub_track - ${files##*/}" || echo_pre_space "x WAV  <- $sub_track - ${files##*/}"
fi
}
cmd_zxtune_xfs_ym_zxspectrum() {
if [[ "$verbose" = "1" ]]; then
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$files" \
		&& mv output-"$file_name_random".wav "$file_name".wav
else
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$files" &>/dev/null \
		&& mv output-"$file_name_random".wav "$file_name".wav &>/dev/null \
		&& echo_pre_space "✓ WAV  <- ${files##*/}" || echo_pre_space "x WAV  <- ${files##*/}"
fi
}
wav2flac() {
# Enconding final flac
if [[ "$verbose" = "1" ]]; then
	if ! [[ "$no_flac" = "1" ]]; then
		ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav -acodec flac -compression_level 12 -sample_fmt "$default_flac_bit_depth" \
			-metadata title="$tag_song" -metadata album="$tag_album" -metadata artist="$tag_artist" \
			-metadata date="$tag_date_formated" "${files%.*}".flac
	fi
else
	if ! [[ "$no_flac" = "1" ]]; then
		ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav -acodec flac -compression_level 12 -sample_fmt "$default_flac_bit_depth" \
			-metadata title="$tag_song" -metadata album="$tag_album" -metadata artist="$tag_artist" \
			-metadata date="$tag_date_formated" "${files%.*}".flac \
			&& echo_pre_space "✓ FLAC <- $(basename "${files%.*}").wav" || echo_pre_space "x FLAC <- $(basename "${files%.*}").wav"
	fi
fi
}

# Convert loop
loop_adplay() {				# PC adlib
if (( "${#lst_adplay[@]}" )); then
	# Bin check & set
	adplay_bin

	# User info - Title
	display_loop_title "adplay" "PC adlib"

	# Tag
	tag_machine="PC"
	tag_pc_sound_module="Adlib"
	tag_questions
	tag_album

	# Wav loop
	display_convert_title "WAV"
	for files in "${lst_adplay[@]}"; do
		# Extract WAV
		(
		cmd_adplay
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Generate wav array
	list_wav_files

	# Flac loop
	display_convert_title "FLAC"
	for files in "${lst_wav[@]}"; do
		# Tag
		tag_song
		# Peak normalisation, false stereo detection 
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
	if test -n "$bchunk"; then				# If bchunk="1" in list_source_files()

		# Bin check & set
		bchunk_bin

		# Local variable
		local track_name

		# User info - Title
		display_loop_title "bchunk" "Various machines CDDA"

		# Tag
		tag_questions
		tag_album

		# Extract WAV
		display_convert_title "WAV"
		track_name=$(basename "${lst_bchunk_iso%.*}")
		cmd_bchunk
	
		# Remove data track
		rm -- "$track_name"-Track-*.iso &>/dev/null

		# Populate wav array
		list_wav_files

		# Flac loop
		display_convert_title "FLAC"
		for files in "${lst_wav[@]}"; do
			# Tag
			tag_song="[untitled]"
			# Peak normalisation, false stereo detection 
			wav_normalization_channel_test
			# Remove silence
			wav_remove_silent
			# Add fade out
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
fi
}
loop_ffmpeg_gbs() {			# GB/GBC
if (( "${#lst_ffmpeg_gbs[@]}" )); then

	# Local variables
	local file_total_track
	local total_sub_track

	# User info - Title
	display_loop_title "ffmpeg" "Game Boy, Game Boy Color"

	# machine selection
	echo_pre_space "Game Boy or Game Boy Color:"
	echo
	echo_pre_space " [0]* > Game Boy"
	echo_pre_space " [1]  > Game Boy Color"
	read -r -e -p " -> " gb_machine_choice
	case "$gb_machine_choice" in
		"0")
			tag_machine="Game Boy"
		;;
		"1")
			tag_machine="Game Boy Color"
		;;
		*)
			tag_machine="Game Boy"
			display_remove_previous_line
			echo " -> 0"
		;;
	esac
	display_separator

	for gbs in "${lst_ffmpeg_gbs[@]}"; do

		# Tags
		tag_gbs_extract
		tag_questions
		tag_album

		# Get total real total track
		file_total_track=$(xxd -ps -s 0x04 -l 1 "$gbs" | awk -Wposix '{printf("%d\n","0x" $1)}')	# Hex to decimal
		total_sub_track=$(("$file_total_track"-1))

		# Wav loop
		display_convert_title "WAV"
		for sub_track in $(seq -w 0 "$total_sub_track"); do
			# Tag
			xxs_track=$((10#"$sub_track"))
			tag_xxs_loop
			(
			cmd_ffmpeg_gbs
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

		# Flac loop
		display_convert_title "FLAC"
		for sub_track in $(seq -w 0 "$total_sub_track"); do
			# Tag
			xxs_track=$((10#"$sub_track"))
			tag_xxs_loop
			# File variable for next function
			files="$sub_track - $tag_song.wav"
			if [ -f "$files" ]; then
				# Peak normalisation, false stereo detection 
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

	# User info - Title
	display_loop_title "ffmpeg" "PC-Engine"

	for hes in "${lst_ffmpeg_hes[@]}"; do
		# Tags
		tag_hes_extract
		tag_machine="PC-Engine"
		tag_questions
		tag_album

		# Get total track
		total_sub_track="256"

		# Wav loop
		display_convert_title "WAV"
		for sub_track in $(seq -w 0 "$total_sub_track"); do
			# Tag
			xxs_track=$((10#"$sub_track"))
			tag_xxs_loop
			# Extract WAV
			(
			cmd_ffmpeg_hes
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

		# Wav clean
		list_wav_files

		display_convert_title "FLAC"
		for sub_track in $(seq -w 0 "$total_sub_track"); do
			# Tag
			xxs_track=$((10#"$sub_track"))
			tag_xxs_loop
			# File variable for next function
			files="$sub_track - $tag_song.wav"
			if [ -f "$files" ]; then
				# Peak normalisation, false stereo detection 
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
loop_ffmpeg_spc() {			# SNES
if (( "${#lst_ffmpeg_spc[@]}" )); then

	# User info - Title
	display_loop_title "ffmpeg" "SNES"

	# Extract WAV
	display_convert_title "WAV"
	for files in "${lst_ffmpeg_spc[@]}"; do
		# Tag
		tag_spc
		if [[ "$files" = "${lst_ffmpeg_spc[0]}" ]];then
			tag_questions
			tag_album
		fi
		# Calc duration/fading
		local spc_fading_second=$((spc_fading/1000))
		local spc_duration_total=$((spc_duration+spc_fading_second))
		# Extract WAV
		(
		cmd_ffmpeg_spc
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Flac loop
	display_convert_title "FLAC"
	for files in "${lst_ffmpeg_spc[@]}"; do
		# Tag
		tag_spc
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Fade out
		imported_sox_fade_out="$spc_fading_second"
		wav_fade_out
		# Remove silence
		wav_remove_silent
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
loop_ffmpeg_xa() {			# PS1/CD-i XA
if (( "${#lst_ffmpeg_xa[@]}" )); then

	# User info - Title
	display_loop_title "ffmpeg" "PS1/CD-i XA"

	# Tag
	tag_questions
	tag_album

	# Extract WAV
	display_convert_title "WAV"
	for files in "${lst_ffmpeg_xa[@]}"; do
		(
		cmd_ffmpeg_xa
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Flac loop
	display_convert_title "FLAC"
	for files in "${lst_wav[@]}"; do
		# Tag
		tag_song
		# Remove silence
		wav_remove_silent
		# Add fade out
		if [[ "$force_fade_out" = "1" ]]; then
			wav_fade_out
		fi
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
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
loop_midi() {				# midi
if (( "${#lst_midi[@]}" )); then

	# Local variables
	local midi_bin
	local fluidsynth_loop_nb

	# User info - Title
	display_loop_title "fluidsynth/munt" "midi"

	# Soundfont label
	current_soundfount=" ${fluidsynth_soundfont##*/}"

	# Bin selection
	echo_pre_space "Select midi software synthesizer:"
	echo
	echo_pre_space " [0]* > fluidsynth -> Use soundfont${current_soundfount}"
	echo_pre_space " [1]  > munt       -> Use Roland MT-32, CM-32L, CM-64, LAPC-I emulator"
	read -r -e -p " -> " midi_choice
	case "$midi_choice" in
		"0")
			fluidsynth_bin
			midi_bin="fluidsynth"
			tag_pc_sound_module="Soundfont${current_soundfount}"
		;;
		"1")
			munt_bin
			midi_bin="munt"
			tag_pc_sound_module="Roland MT-32"
		;;
		*)
			fluidsynth_bin
			midi_bin="fluidsynth"
			tag_pc_sound_module="Soundfont${current_soundfount}"
			display_remove_previous_line
			echo " -> 0"
		;;
	esac

	# Fluidsynth loop number question
	if [[ "$midi_bin" = "fluidsynth" ]]; then
		display_separator
		echo_pre_space "Number of audio loops:"
		echo
		echo_pre_space " [1]* > Once"
		echo_pre_space " [2]  > Twice"
		read -r -e -p " -> " midi_loop_nb
		case "$midi_loop_nb" in
			"1")
				fluidsynth_loop_nb="1"
			;;
			"2")
				fluidsynth_loop_nb="2"
			;;
			*)
				fluidsynth_loop_nb="1"
				display_remove_previous_line
				echo " -> 1"
			;;
		esac
	fi

	# Tag
	display_separator
	tag_questions
	tag_album
	
	# Wav loop
	display_convert_title "WAV"
	for files in "${lst_midi[@]}"; do
		# Extract WAV
		(
		if [[ "$midi_bin" = "fluidsynth" ]]; then
			if [[ "$fluidsynth_loop_nb" = "1" ]]; then			# 1 loop
				cmd_fluidsynth_loop1
			elif [[ "$fluidsynth_loop_nb" = "2" ]]; then		# 2 loops
				cmd_fluidsynth_loop2
			fi
		elif [[ "$midi_bin" = "munt" ]]; then
			cmd_munt
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
	display_convert_title "FLAC"
	for files in "${lst_wav[@]}"; do
		# Tag
		tag_song
		# Peak normalisation, false stereo detection 
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
loop_nsfplay_nsf() {		# NES
if (( "${#lst_nsfplay_nsf[@]}" )); then
	# Bin check & set
	nsfplay_bin

	# Local variables
	local file_total_track
	local total_sub_track

	# User info - Title
	display_loop_title "nsfplay" "NES"

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
		display_convert_title "WAV"
		for sub_track in $(seq -w 1 "$total_sub_track"); do
			# Tag
			xxs_track=$((10#"$sub_track"))
			tag_xxs_loop
			(
			cmd_nsfplay_nsf
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

		# Flac loop
		display_convert_title "FLAC"
		for sub_track in $(seq -w 0 "$total_sub_track"); do
			# Tag
			xxs_track=$((10#"$sub_track"))
			tag_xxs_loop
			# File variable for next function
			files="$sub_track - $tag_song.wav"
			if [ -f "$files" ]; then
				# Peak normalisation, false stereo detection 
				wav_normalization_channel_test
				# Remove silence
				wav_remove_silent
				# Add fade out
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

	# User info - Title
	display_loop_title "nsfplay" "NES"

	for nsfe in "${lst_nsfplay_nsfe[@]}"; do
		# Tags
		tag_nsfe
		tag_machine="NES"
		tag_questions
		tag_album

		# Get total track
		file_total_track=$("$nsfplay_bin" "$nsfe" | grep -c "Track ")
		total_sub_track="$file_total_track"

		# Wav loop
		display_convert_title "WAV"
		for sub_track in $(seq -w 1 "$total_sub_track"); do
			# Tag
			tag_nsfe
			(
			cmd_nsfplay_nsfe
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

		# Flac loop
		display_convert_title "FLAC"
		for sub_track in $(seq -w 0 "$total_sub_track"); do
			# Tag
			tag_nsfe
			# File variable for next function
			files="$sub_track - $tag_song.wav"
			if [ -f "$files" ]; then
				# Peak normalisation, false stereo detection 
				wav_normalization_channel_test
				# Remove silence
				wav_remove_silent
				# Add fade out
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
			fi
		done
		wait

	done
fi
}
loop_sc68() {				# Atari ST (YM2149)
if (( "${#lst_sc68[@]}" )); then
	# Bin check & set
	info68_bin
	sc68_bin

	# Local variable
	local total_sub_track
	local track_name

	# User info - Title
	display_loop_title "sc68" "Atari ST"

	for sc68_files in "${lst_sc68[@]}"; do
		# Tag extract
		"$info68_bin" -A "$sc68_files" > "$vgm2flac_cache_tag"
		if [[ -z "$tag_game" && -z "$tag_artist" && -z "$tag_machine" ]]; then
			tag_game=$(< "$vgm2flac_cache_tag" grep -i -a title: | sed 's/^.*: //' | head -1)
			tag_artist=$(< "$vgm2flac_cache_tag" grep -i -a artist: | sed 's/^.*: //' | head -1)
			tag_date=$(< "$vgm2flac_cache_tag" grep -i -a year: | sed 's/^.*: //' | head -1)
		fi

		# Tag
		tag_questions
		tag_album

		# Get total track
		total_sub_track=$(< "$vgm2flac_cache_tag" grep -i -a track: | sed 's/^.*: //' | tail -1)

		# Extract WAV
		display_convert_title "WAV"
		for sub_track in $(seq -w 1 "$total_sub_track"); do
			track_name=$(basename "${sc68_files%.*}")
			(
			cmd_sc68
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

		# Clean raw
		for files in *.raw; do
			rm "$files"
		done

		# Generate wav array
		list_wav_files

		# Flac loop
		display_convert_title "FLAC"
		for files in "${lst_wav[@]}"; do
			# Tag
			tag_song="[untitled]"
			# Peak normalisation, false stereo detection 
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
	local sox_sample_rate_question
	local sox_channel_question
	local sox_loop_question

	# Test files
	for files in "${lst_sox[@]}"; do
		# Test if data by measuring maximum difference between two successive samples
		delta=$(sox -t raw -r 44100 -b 16 -c 2 -L -e signed-integer "$files" -n stat 2>&1 | grep "Maximum delta:" | awk '{print $3}')
		# If Maximum delta < 1.9 - raw -> wav
		if awk -v n1="$delta" -v n2="1.9" 'BEGIN {if (n1+0<n2+0) exit 0; exit 1}'; then
			lst_sox_pass+=("$files")
		fi
	done
	wait

	# Start sox loop with file passed
	if (( "${#lst_sox_pass[@]}" )); then

		# User info - Title
		display_loop_title "sox" "Various machines - RAW files"

		# Tag
		tag_questions
		tag_album

		# Sample rate question
		echo_pre_space "Choose sample rate:"
		echo
		echo_pre_space " [1]  > 8000 Hz"
		echo_pre_space " [2]  > 11025 Hz"
		echo_pre_space " [3]  > 16000 Hz"
		echo_pre_space " [4]  > 22050 Hz"
		echo_pre_space " [5]  > 24000 Hz"
		echo_pre_space " [6]  > 32000 Hz"
		echo_pre_space " [7]* > 44100 Hz"
		echo_pre_space " [8]  > 48000 Hz"
		read -r -e -p " -> " sox_sample_rate_question
		case "$sox_sample_rate_question" in
			"1")
				sox_sample_rate="8000"
			;;
			"2")
				sox_sample_rate="11025"
			;;
			"3")
				sox_sample_rate="16000"
			;;
			"4")
				sox_sample_rate="22050"
			;;
			"5")
				sox_sample_rate="24000"
			;;
			"6")
				sox_sample_rate="32000"
			;;
			"7")
				sox_sample_rate="44100"
			;;
			"8")
				sox_sample_rate="48000"
			;;
			*)
				sox_sample_rate="44100"
				display_remove_previous_line
				echo " -> 44100"
			;;
		esac

		# Channels question
		display_separator
		echo_pre_space "Choose channels number:"
		echo
		echo_pre_space " [1]  > Mono"
		echo_pre_space " [2]* > Stereo"
		read -r -e -p " -> " sox_channel_question
		case "$sox_channel_question" in
			"1")
				sox_channel="1"
			;;
			"2")
				sox_channel="2"
			;;
			*)
				sox_channel="2"
				display_remove_previous_line
				echo " -> 2"
			;;
		esac

		# Loop question
		display_separator
		echo_pre_space "Choose number of loop:"
		echo
		echo_pre_space " [1]* > No loop"
		echo_pre_space " [2]  > 2 loop"
		read -r -e -p " -> " sox_loop_question
		case "$sox_loop_question" in
			"1")
				sox_loop="0"
			;;
			"2")
				sox_loop="1"
			;;
			*)
				sox_loop="0"
				display_remove_previous_line
				echo " -> 1"
			;;
		esac

		# Extract WAV
		display_convert_title "WAV"
		for files in "${lst_sox_pass[@]}"; do
				(
				cmd_sox
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
		done
		wait

		# Generate wav array
		list_wav_files

		# Flac loop
		display_convert_title "FLAC"
		for files in "${lst_wav[@]}"; do
			# Tag
			tag_song
			# Peak normalisation, false stereo detection 
			wav_normalization_channel_test
			# Remove silence
			wav_remove_silent
			# Fade out
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
fi
}
loop_uade() {				# Amiga
if (( "${#lst_uade[@]}" )); then
	# Local variables
	local total_track
	local current_track
	local diff_track
	local file_name

	# User info - Title
	display_loop_title "uade" "Amiga"

	display_convert_title "WAV"
	for files in "${lst_uade[@]}"; do
		# Tag
		tag_machine="Amiga"
		tag_questions
		tag_album

		# Get total track
		total_track=$("$uade123_bin" -g "$files" 2>/dev/null | grep "subsongs:"  | awk '/^subsongs:/ { print $NF }')
		current_track=$("$uade123_bin" -g "$files" 2>/dev/null | grep "subsongs:" | awk '/^subsongs:/ { print $3 }')
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
			cmd_uade
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
	display_convert_title "FLAC"
	for files in "${lst_wav[@]}"; do
			# Tag
			tag_song

			# Peak normalisation, false stereo detection 
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
}
loop_vgm2wav() {			# Various machines
if (( "${#lst_vgm2wav[@]}" )); then
	# Bin check & set
	vgm2wav_bin
	vgm_tag_bin

	# User info - Title
	display_loop_title "vgm2wav" "Various machines"

	# Wav loop
	display_convert_title "WAV"
	for files in "${lst_vgm2wav[@]}"; do
		(
		cmd_vgm2wav
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Flac/tag loop
	display_convert_title "FLAC"
	for files in "${lst_vgm2wav[@]}"; do
		# Tag
		# Set case insentive
		shopt -s nocasematch
		case "${files[@]##*.}" in
			*vgm|*vgz)
				# Set case sentive
				shopt -u nocasematch
				# Tag
				tag_vgm
			;;
			*s98)
				# Set case sentive
				shopt -u nocasematch
				# Tag
				tag_s98
			;;
		esac
		tag_questions
		tag_album

		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Remove silence
		wav_remove_silent
		# Add fade out
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
loop_vgmstream() {			# Various machines
if (( "${#lst_vgmstream[@]}" )); then
	# Local variables
	local total_sub_track
	local force_fade_out

	# User info - Title
	display_loop_title "vgmstream" "Various machines"

	# Tag
	tag_questions
	tag_album

	display_convert_title "WAV"
	for files in "${lst_vgmstream[@]}"; do
		# Get total track
		# Ignore txtp
		test_ext_file="${files##*.}"
		if ! [[ "${test_ext_file^^}" =~ "TXTP" ]]; then
			#total_sub_track=$("$vgmstream_cli_bin" -m "$files" | grep -i -a "stream count" | sed 's/^.*: //' | awk '{ print $1 - 1 }')
			total_sub_track=$("$vgmstream_cli_bin" -m "$files" | grep -i -a "stream count" | sed 's/^.*: //')
		fi
		# Record output name
		if [[ -z "$total_sub_track" ]] || [[ "$total_sub_track" = "1" ]]; then
			lst_wav+=("${files%.*}".wav)
		else
			for sub_track in $(seq -w 0 "$total_sub_track"); do
				lst_wav+=("${files%.*}"-"$sub_track".wav)
			done
		fi

		# Extract WAV
		(
		if [[ -z "$total_sub_track" ]] || [[ "$total_sub_track" = "1" ]]; then
			cmd_vgmstream
		else
			# Multi track loop
			for sub_track in $(seq -w 0 "$total_sub_track"); do
				cmd_vgmstream_multi_track
			done
		fi
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Flac loop
	display_convert_title "FLAC"
	for files in "${lst_wav[@]}"; do
		# Tag
		tag_song
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Remove silence
		wav_remove_silent
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

	# User info - Title
	display_loop_title "zxtune" "Amstrad CPC, ZX Spectrum"

	for ay in "${lst_zxtune_ay[@]}"; do

		# Tag extract
		tag_ay
		tag_questions
		tag_album

		# Get total track -1 (ay start by 0)
		total_sub_track=$(ffprobe -hide_banner -loglevel panic -select_streams a -show_streams -show_format "$ay" \
							| grep -i "tracks=" | awk -F'=' '{print $NF}' | awk '{print $1-1}')

		# Extract WAV
		display_convert_title "WAV"
		if [[ "$total_sub_track" = "0" ]]; then
			# Tag
			tag_ay

			# Filename contruction
			file_name_random=$(( RANDOM % 10000 ))
			# Extract WAV no subtrack
			cmd_zxtune_ay

			# Flac filename
			files="$tag_song.wav"
			# Peak normalisation, false stereo detection 
			wav_normalization_channel_test
			# Remove silence
			wav_remove_silent
			# Add fade out
			wav_fade_out
			# Flac conversion
			display_convert_title "FLAC"
			(
			wav2flac
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi

		else
			# Extract WAV with subtrack
			for sub_track in $(seq -w 0 "$total_sub_track"); do
				# Filename contruction
				file_name_random=$(( RANDOM % 10000 ))
				# Extract WAV
				(
				cmd_zxtune_ay_multi_track
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
			done
			wait
			# Flac conversion
			display_convert_title "FLAC"
			for sub_track in $(seq -w 0 "$total_sub_track"); do
				# Tag
				tag_ay
				# Flac filename
				mv "$sub_track".wav "$sub_track - $tag_song.wav"
				files="$sub_track - $tag_song.wav"
				# Peak normalisation, false stereo detection 
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

	done
	wait
fi
}
loop_zxtune_sid() {			# Commodore 64/128
if (( "${#lst_zxtune_sid[@]}" )); then
	# Bin check & set
	zxtune123_bin

	# Local variable
	local test_duration

	# User info - Title
	display_loop_title "zxtune" "Commodore 64/128"

	for files in "${lst_zxtune_sid[@]}"; do
		# Tag extract
		tag_sid
		tag_questions
		tag_album
		tag_song

		# Wav loop by track
		display_convert_title "WAV"
		for sub_track in $(seq -w 1 99); do
			# Filename contruction
			file_name_random=$(( RANDOM % 10000 ))
			# Extract WAV
			cmd_zxtune_sid_multi_track

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
			# Filename contruction
			file_name_random=$(( RANDOM % 10000 ))
			# Extract WAV
			cmd_zxtune_sid

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
		fi

	done

	# Generate wav array
	list_wav_files

	# Flac loop
	if (( "${#lst_wav[@]}" )); then
		display_convert_title "FLAC"
		for files in "${lst_wav[@]}"; do
			# Tag
			tag_song="[untitled]"
			# Peak normalisation, false stereo detection 
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

fi
}
loop_zxtune_xfs() {			# PS1, PS2, NDS, Saturn, GBA, N64, Dreamcast
if (( "${#lst_zxtune_xsf[@]}" )); then
	# Bin check & set
	zxtune123_bin

	# Local variables
	local file_name
	local file_name_random

	# User info - Title
	display_loop_title "zxtune" "Dreamcast, GBA, N64, NDS, Saturn, PS1, PS2"

	# Wav loop
	display_convert_title "WAV"
	for files in "${lst_zxtune_xsf[@]}"; do
		# Tag (one time)
		if [[ "$files" = "${lst_zxtune_xsf[0]}" ]];then
			tag_xfs
			tag_questions
			tag_album
		fi
		# Filename contruction
		file_name=$(basename "${files%.*}")
		file_name_random=$(( RANDOM % 10000 ))
		# Extract WAV
		(
		cmd_zxtune_xfs_ym_zxspectrum
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Flac/tag loop
	display_convert_title "FLAC"
	for files in "${lst_zxtune_xsf[@]}"; do
		# Tag
		tag_xfs
		tag_questions
		tag_album

		# Consider fade out if N64 files not have tag_length, or force
		if [ "${files##*.}" = "miniusf" ] || [ "${files##*.}" = "usf" ] || [ "$force_fade_out" = "1" ]; then
			if [[ -z "$tag_length" ]]; then
				# Remove silence
				wav_remove_silent
				# Peak normalisation, false stereo detection 
				wav_normalization_channel_test
				# Fade out
				wav_fade_out
			else
				# Remove silence
				wav_remove_silent
				# Peak normalisation, false stereo detection 
				wav_normalization_channel_test
			fi
		else
			# Peak normalisation, false stereo detection 
			wav_normalization_channel_test
			# Remove silence
			wav_remove_silent
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
	local file_name

	# User info - Title
	display_loop_title "zxtune" "Amstrad CPC, Atari ST"

	# Tag
	tag_questions
	tag_album
	
	# Wav loop
	display_convert_title "WAV"
	for files in "${lst_zxtune_ym[@]}"; do
		# Filename contruction
		file_name=$(basename "${files%.*}")
		file_name_random=$(( RANDOM % 10000 ))
		# Extract WAV
		(
		cmd_zxtune_xfs_ym_zxspectrum
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Generate wav array
	list_wav_files

	# Flac loop
	display_convert_title "FLAC"
	for files in "${lst_wav[@]}"; do
		# Tag
		tag_song
		# Peak normalisation, false stereo detection 
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
	local file_name

	# User info - Title
	display_loop_title "zxtune" "AZX Spectrum"

	# Tag
	tag_machine="ZX Spectrum"
	tag_questions
	tag_album
	
	# Wav loop
	display_convert_title "WAV"
	for files in "${lst_zxtune_zx_spectrum[@]}"; do
		# Filename contruction
		file_name=$(basename "${files%.*}")
		file_name_random=$(( RANDOM % 10000 ))
		# Extract WAV
		(
		cmd_zxtune_xfs_ym_zxspectrum
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Generate wav array
	list_wav_files

	# Flac loop
	display_convert_title "FLAC"
	for files in "${lst_wav[@]}"; do
		# Tag
		tag_song
		# Peak normalisation, false stereo detection 
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
		tag_track_count=$((count+1))
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
		read -r -e -p " Enter the game title: " tag_game
		display_remove_previous_line
		if test -z "$tag_game"; then
			tag_game="unknown"
		fi
	fi
	if test -z "$tag_artist"; then
		read -r -e -p " Enter the audio artist: " tag_artist
		display_remove_previous_line
		if test -z "$tag_artist"; then
			tag_artist="unknown"
		fi
	fi
	if test -z "$tag_date"; then
		read -r -e -p " Enter the release date: " tag_date
		display_remove_previous_line
		if test -z "$tag_date"; then
			tag_date="NULL"
			tag_date_formated=""
		else
			tag_date_formated="$tag_date"
		fi
	elif [[ "$tag_date" = "NULL" ]]; then
		tag_date_formated=""
	else
		tag_date_formated="$tag_date"
	fi
	if test -z "$tag_machine"; then
		read -r -e -p " Enter the release platform: " tag_machine
		display_remove_previous_line
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

m3u_track_hex_test=$(< "$m3u_file" awk -F"," '{ print $2 }' | grep -F -e "$")
if [[ -z "$m3u_track_hex_test" ]]; then													# Decimal track
	< "$m3u_file" sed '/^#/d' | sed 's/\\//g' | uniq | sed -r '/^\s*$/d' | sort -t, -k2,2 -n \
	| sed 's/.*::/GAME::/' | sed -e 's/\\,/ -/g' > "$vgm2flac_cache_tag"
else																					# Hexadecimal track
	< "$m3u_file" sed '/^#/d' | sed 's/\\//g' | uniq | sed -r '/^\s*$/d' \
	| tr -d '$' | awk --non-decimal-data -F ',' -v OFS=',' '$1 {$2=("0x"$2)+0; print}' \
	| sort -t, -k2,2 -n | sed 's/.*::/GAME::/' | sed -e 's/\\,/ -/g' > "$vgm2flac_cache_tag"
fi
}
tag_xxs_loop() {			# Game Boy (gbs), NES (nsf), PC-Enginge (HES)
if [ "${#lst_m3u[@]}" -gt "0" ]; then

	# Local variables
	local xxs_duration
	local xxs_duration_format
	local xxs_fading
	local xxs_fading_format

	tag_song=$(< "$vgm2flac_cache_tag" awk -v var=$xxs_track -F',' '$2 == var { print $0 }' | awk -F"," '{ print $3 }')
	tag_song=$(echo "$tag_song" | sed s#/#-#g | sed s#:#-#g)					# Replace eventualy "/" & ":" in string
	if [[ -z "$tag_song" ]]; then
		tag_song="[untitled]"
	fi

	# Get fade out and duration
	xxs_duration=$(< "$vgm2flac_cache_tag" grep ",$xxs_track," \
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
		xxs_duration_second=$((xxs_duration_second+1))															# Total duration in s + 1s
		xxs_duration_msecond=$((xxs_duration_second*1000))														# Total duration in ms
	else
		# Duration value
		xxs_duration_second="$xxs_default_max_duration"
		xxs_duration_msecond=$((xxs_default_max_duration*1000))
	fi

	# Fade out
	xxs_fading=$(< "$vgm2flac_cache_tag" grep ",$xxs_track," \
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
		xxs_fading_msecond=$((xxs_fading_second*1000))																# Fade out duration in ms
	else
		xxs_fading_second="0"
	fi

	# nsfplay fading correction if empty (.nsf apply only)
	if [[ "$xxs_fading_second" = 0 && "xxs_duration_second" -gt "10" ]]; then
		xxs_fading_msecond=$((default_wav_fade_out*1000))
	fi

	# Prevent incoherence duration between fade out and total duration
	if [[ "$xxs_fading_second" -ge "xxs_duration_second" ]]; then
		unset xxs_fading_second
		xxs_fading_msecond="0"
	fi

else
	tag_song="[untitled]"
	xxs_duration_second="$xxs_default_max_duration"

	# nsfplay duration & fading s to ms
	xxs_duration_msecond=$((xxs_default_max_duration*1000))
	xxs_fading_msecond=$((default_wav_fade_out*1000))
fi
}
tag_ay() {					# Amstrad CPC, ZX Spectrum
# Tag extract
if [[ "$total_sub_track" = "0" ]] || [[ -z "$total_sub_track" ]]; then
	ffprobe -hide_banner -loglevel panic -select_streams a -show_streams -show_format "$ay" > "$vgm2flac_cache_tag"
else
	ffprobe -track_index "$sub_track" -hide_banner -loglevel panic -select_streams a -show_streams -show_format "$ay" > "$vgm2flac_cache_tag"
fi

tag_song=$(< "$vgm2flac_cache_tag" grep -i "song=" | awk -F'=' '{print $NF}')
tag_song=$(echo "$tag_song" | sed s#/#-#g | sed s#:#-#g)					# Replace eventualy "/" & ":" in string
if [[ -z "$tag_song" ]] || [ "$tag_song" = "?" ]; then
	tag_song="[untitled]"
fi

tag_artist_backup="$tag_artist"
tag_artist=$(< "$vgm2flac_cache_tag" grep -i "author=" | awk -F'=' '{print $NF}')
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
	m3u_track_hex_test=$(< "${gbs%.*}".m3u awk -F"," '{ print $2 }' | grep -F -e "$")
	tag_m3u_clean_extract
fi
}
tag_hes_extract() {			# PC Engine		- Tag extraction & m3u cleaning
# If m3u
if [ "${#lst_m3u[@]}" -gt "0" ]; then
	m3u_file="${hes%.*}.m3u"
	tag_game=$(< "${hes%.*}".m3u grep "@TITLE" | awk -v n=3 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' | tr -d "\n\r")
	tag_artist=$(< "${hes%.*}".m3u grep "@COMPOSER" | awk -v n=3 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' | tr -d "\n\r")
	tag_date=$(< "${hes%.*}".m3u grep "@DATE" | awk -v n=3 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' | tr -d "\n\r")
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

tag_song=$(< "$vgm2flac_cache_tag" grep "$nsfplay_sub_track" | sed -n "s/$nsfplay_sub_track/&\n/;s/.*\n//p" | awk '{$1=$1}1')
tag_song=$(echo "$tag_song" | sed s#/#-#g | sed s#:#-#g)					# Replace eventualy "/" & ":" in string
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
nsfplay_default_max_duration=$((xxs_default_max_duration*1000))
}
tag_s98() {					# NEC PC-6001, PC-6601, PC-8801,PC-9801, Sharp X1, Fujitsu FM-7 & FM TownsSharp X1
# Tag extract
strings "$files" > "$vgm2flac_cache_tag"

tag_song=$(< "$vgm2flac_cache_tag" grep -i -a title | sed 's/^.*=//' | head -1)
if [[ -z "$tag_song" ]]; then
	tag_song
fi

tag_artist_backup="$tag_artist"
tag_artist=$(< "$vgm2flac_cache_tag" grep -i -a artist | sed 's/^.*=//' | head -1)
if [[ -z "$tag_artist" ]]; then
	tag_artist="$tag_artist_backup"
fi

if [[ -z "$tag_game" && -z "$tag_machine" && -z "$tag_date" ]]; then
	tag_game=$(< "$vgm2flac_cache_tag" grep -i -a game | sed 's/^.*=//' | head -1)
	tag_machine=$(< "$vgm2flac_cache_tag" grep -i -a system | sed 's/^.*=//' | head -1)
	tag_date=$(< "$vgm2flac_cache_tag" grep -i -a year | sed 's/^.*=//' | head -1)
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
		spc_fading=$((default_wav_fade_out*1000))
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

tag_song=$(< "$vgm2flac_cache_tag" grep -i -a title= | sed 's/^.*=//')
if [[ -z "$tag_song" ]]; then
	tag_song
fi

tag_artist_backup="$tag_artist"
tag_artist=$(< "$vgm2flac_cache_tag" grep -i -a artist= | sed 's/^.*=//')
if [[ -z "$tag_artist" ]]; then
	tag_artist="$tag_artist_backup"
fi

if [[ -z "$tag_game" && -z "$tag_date" ]]; then
	tag_game=$(< "$vgm2flac_cache_tag" grep -i -a game= | sed 's/^.*=//')
	tag_date=$(< "$vgm2flac_cache_tag" grep -i -a year= | sed 's/^.*=//')
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
	tag_length=$(< "$vgm2flac_cache_tag" grep -i -a length= | sed 's/^.*=//')
fi
}

# Temp clean & target filename/directory structure
wav_remove() {
if [ "${#lst_wav[@]}" -gt "0" ]; then											# If number of wav > 0
	display_separator
	read -r -e -p " Remove wav files (temp. audio)? [y/N]:" qarm
	case $qarm in
		"Y"|"y")
			for files in "${lst_wav[@]}"; do
				rm -f "$files" &>/dev/null
			done
		;;
	esac
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

	# If target exist add date +%s after dir name
	if [ ! -d "$PWD/$target_directory" ]; then
		mkdir "$PWD/$target_directory" &>/dev/null
	else
		target_directory="$target_directory-$(date +%s)"
		mkdir "$PWD/$target_directory" &>/dev/null
	fi

	# Create target dir & mv
	for files in "${lst_flac[@]}"; do
		mv "$files" "$PWD/$target_directory" &>/dev/null
	done
fi
}
end_functions() {
if [[ "$no_flac" = "1" ]]; then
	clean_wav_flac_validation
	display_all_in_errors
	display_end_summary
	clean_cache_directory
else
	if [[ "$flac_loop_activated" = "1" ]]; then
		clean_wav_flac_validation
		flac_force_pal_tempo
		tag_track
		display_all_in_errors
		display_end_summary
		mk_target_directory
		clean_cache_directory
		wav_remove
	fi
fi
}

# Arguments variables
while [[ $# -gt 0 ]]; do
	key="$1"
	case "$key" in
	--agressive_rm_silent)													# Set agressive mode for remove silent 85db->58db
		agressive_silence="1"
	;;
	-h|--help)																# Help
		cmd_usage
		exit
	;;
	--fade_out)
		force_fade_out="1"													# Set force default fade out
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
	--no_remove_duplicate)
		no_remove_duplicate="1"												# Set force no remove duplicate files
	;;
	--no_remove_silence)
		no_remove_silence="1"												# Set force no remove silence
	;;
	--pal)
		flac_force_pal="1"													# Set pal mode
	;;
	-v|--verbose)
		verbose="1"
		unset ffmpeg_log_lvl												# Unset default ffmpeg log
		ffmpeg_log_lvl="-loglevel info -stats"								# Set ffmpeg log level to stats
		unset nprocessor
		nprocessor="1"
	;;
	*)
		cmd_usage
		exit
	;;
esac
shift
done

# Bin check & set
test_write_access
common_bin

# Files source check & set
check_cache_directory
list_source_files

# Timer start
timer_start=$(date +%s)

# Encoding/tag loop
loop_adplay
loop_bchunk
loop_ffmpeg_gbs
loop_ffmpeg_hes
loop_ffmpeg_spc
loop_ffmpeg_xa
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

# Timer stop
timer_stop=$(date +%s)

# End
end_functions

exit
