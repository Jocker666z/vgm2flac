#!/bin/bash
# vgm2flac
# Bash tool for vgm encoding to flac
#
# Author: Romain Barbarot
# https://github.com/Jocker666z/vgm2flac
#
# licence : GNU GPL-2.0
# Paths
vgm2flac_path="$( cd "$( dirname "$0" )" && pwd )"
vgm2flac_cache="/home/$USER/.cache/vgm2flac"												# Cache directory
vgm2flac_cache_tag="/home/$USER/.cache/vgm2flac/tag-$(date +%Y%m%s%N).info"					# Tag cache
export PATH=$PATH:/home/$USER/.local/bin													# For case of launch script outside a terminal

# Others
core_dependency=(bc bchunk ffmpeg ffprobe sox xxd )
ffmpeg_log_lvl="-hide_banner -loglevel panic -stats"										# ffmpeg log level
nprocessor=$(nproc --all)																	# Set number of processor
default_sox_fade_out="5"																	# Default fade out value in second

# Extensions
ext_adplay="hsq|sdb|sqx"
ext_bchunk_cue="cue"
ext_bchunk_iso="bin|iso"
ext_ffmpeg="mod|spc|xa"
ext_fluidsynth="mid"
ext_sc68="snd|sndh"
ext_sox="bin|pcm|raw|tak"
ext_playlist="m3u"
ext_vgm2wav="s98|vgm|vgz"
ext_vgmstream="aa3|adp|adpcm|ads|adx|aif|aifc|aix|ast|at3|bcstm|bcwav|bfstm|bfwav|bik|bnk|cfn|dsp|eam|fsb|genh|his|hps|imc|int|laac|logg|ktss|msf|mtaf|mib|mpf|mus|rak|raw|sad|sfd|sgd|smk|sng|spsd|str|ss2|thp|txtp|vag|vgs|vpk|wem|xvag|xwav|xwb"
ext_uade="aam\.|core\.|cust\.|dw\.|gmc\.|mdat\.|mod\.|sa\.|sb\.|sfx\."
ext_zxtune_gbs="gbs"
ext_zxtune_nsf="nsf"
ext_zxtune_sid="sid"
ext_zxtune_xsf="2sf|gsf|dsf|psf|psf2|mini2sf|minigsf|minipsf|minipsf2|minissf|miniusf|ssf|usf"
ext_zxtune_ym="ym"
ext_zxtune_zx_spectrum="asc|psc|pt2|pt3|sqt|stc|stp"

# Bin check and set variable
adplay_bin() {
local bin_name="adplay"
local system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	adplay_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
fluidsynth_bin() {
local bin_name="fluidsynth"
local system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	fluidsynth_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
info68_bin() {
local bin_name="info68"
local system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	info68_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
sc68_bin() {
local bin_name="sc68"
local system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	sc68_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
uade123_bin() {
local bin_name="uade123"
local system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	uade123_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
vgm2wav_bin() {
local bin_name="vgm2wav"
local system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	vgm2wav_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
vgmstream_cli_bin() {
local bin_name="vgmstream_cli"
local system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	vgmstream_cli_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
vgm_tag_bin() {
local bin_name="vgm_tag"
local system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	vgm_tag_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
zxtune123_bin() {
local bin_name="zxtune123"
local system_bin_location=$(which $bin_name)

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
		let c++
	else
		local command_fail+=("$command")
		let n++
	fi
done
if (( "${#command_fail[@]}" )); then
	echo "vgm2flac break, the following dependencies are not installed:"
	printf '  %s\n' "${command_fail[@]}"
	exit
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
mapfile -t lst_bchunk_cue < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_bchunk_cue')$' 2>/dev/null | sort)
mapfile -t lst_bchunk_iso < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_bchunk_iso')$' 2>/dev/null | sort)
mapfile -t lst_ffmpeg < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_ffmpeg')$' 2>/dev/null | sort)
mapfile -t lst_fluidsynth < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_fluidsynth')$' 2>/dev/null | sort)
mapfile -t lst_m3u < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_playlist')$' 2>/dev/null | sort)
mapfile -t lst_sc68 < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_sc68')$' 2>/dev/null | sort)
mapfile -t lst_sox < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_sox')$' 2>/dev/null | sort)
mapfile -t lst_vgm2wav < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_vgm2wav')$' 2>/dev/null | sort)
mapfile -t lst_vgmstream < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_vgmstream')$' 2>/dev/null | sort)
mapfile -t lst_uade < <(find "$PWD" -maxdepth 1 -type f | grep -E -i -- ''$ext_uade'' | sort)
mapfile -t lst_zxtune_gbs < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_zxtune_gbs')$' 2>/dev/null | sort)
mapfile -t lst_zxtune_nsf < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_zxtune_nsf')$' 2>/dev/null | sort)
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
list_temp_files() {
mapfile -t lst_wav < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('wav')$' 2>/dev/null | sort)
}
list_target_files() {
mapfile -t lst_flac < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('flac')$' 2>/dev/null | sort)
}

# Audio treatment
wav_remove_silent() {
# Remove silence from audio files while leaving gaps, if audio during more than 10s
local test_duration=$(ffprobe -i "${files%.*}".wav -show_format -v quiet | grep duration | sed 's/.*=//' | cut -f1 -d".")
if [[ "$test_duration" -gt 10 ]] ; then
	# Remove silence at start & end
	sox "${files%.*}".wav temp-out.wav silence 1 0.1 1% reverse silence 1 0.1 1% reverse
	rm "${files%.*}".wav &>/dev/null
	mv temp-out.wav "${files%.*}".wav &>/dev/null
	# Remove silence > 5s
	sox "${files%.*}".wav temp-out.wav silence -l 1 0.1 0.01% -1 5.0 0.01%
	rm "${files%.*}".wav &>/dev/null
	mv temp-out.wav "${files%.*}".wav &>/dev/null
fi
}
wav_fade_out() {
# Out fade, if audio during more than 10s
local test_duration=$(ffprobe -i "${files%.*}".wav -show_format -v quiet | grep duration | sed 's/.*=//' | cut -f1 -d".")
if [[ "$test_duration" -gt 10 ]] ; then
	local duration=$(soxi -d "${files%.*}".wav)
	local sox_fade_in="0:0.0"
	if [[ -z "$imported_sox_fade_out" ]]; then
		local sox_fade_out="0:$default_sox_fade_out"
	else
		local sox_fade_out="0:$imported_sox_fade_out"
	fi
	sox "${files%.*}".wav temp-out.wav fade t $sox_fade_in $duration $sox_fade_out
	rm "${files%.*}".wav &>/dev/null
	mv temp-out.wav "${files%.*}".wav &>/dev/null
fi
}
wav_normalization_channel_test() {
# Test Volume, set normalization variable
local testdb=$(ffmpeg -i "${files%.*}".wav -af "volumedetect" -vn -sn -dn -f null /dev/null 2>&1 | grep "max_volume" | awk '{print $5;}')
if [[ $testdb = *"-"* ]]; then
	local db=$(echo "$testdb" | cut -c2-)dB
	afilter="-af volume=$db"
else
	afilter=""
fi

# Channel test mono or stereo
local left_md5=$(ffmpeg -i "${files%.*}".wav -map_channel 0.0.0 -f md5 - 2>/dev/null)
local right_md5=$(ffmpeg -i "${files%.*}".wav -map_channel 0.0.1 -f md5 - 2>/dev/null)
if [ "$left_md5" = "$right_md5" ]; then
	confchan="-channel_layout mono"
else
	confchan=""
fi

# Encoding Wav
ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav $afilter $confchan -acodec pcm_s16le -f wav temp-out.wav
rm "${files%.*}".wav &>/dev/null
mv temp-out.wav "${files%.*}".wav &>/dev/null
}
wav2flac() {
ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav -acodec flac -compression_level 12 -sample_fmt s16 -metadata title="$tag_song" -metadata album="$tag_album" -metadata artist="$tag_artist" -metadata date="$tag_date" "${files%.*}".flac
}

# Convert loop
loop_adplay() {				# PC adlib
if (( "${#lst_adplay[@]}" )); then
	# Bin check & set
	adplay_bin

	# Tag
	tag_machine="PC"
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
	list_temp_files

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
	if test -n "$bchunk"; then				# If bchunk="1" in list_source_files()
		# Tag
		tag_questions
		tag_album
		# Extract WAV
		local track_name=$(basename "${lst_bchunk_iso%.*}")
		bchunk -w "${lst_bchunk_iso[0]}" "${lst_bchunk_cue[0]}" "$track_name"-Track-
		# Remove data track
		rm -- "$track_name"-Track-*.iso
		# Populate wav array
		list_temp_files
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
				tag_song
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
loop_fluidsynth() {			# PC midi
if (( "${#lst_fluidsynth[@]}" )); then
	# Bin check & set
	fluidsynth_bin

	# Tag
	tag_machine="PC"
	tag_questions
	tag_album
	
	# Wav loop
	for files in "${lst_fluidsynth[@]}"; do
		# Extract WAV
		(
		"$fluidsynth_bin" -F "${files%.*}".wav "$files"

		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Generate wav array
	list_temp_files

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
loop_sc68() {				# Atari ST
if (( "${#lst_sc68[@]}" )); then
	# Bin check & set
	info68_bin
	sc68_bin
	for files in "${lst_sc68[@]}"; do
		# Tag extract
		"$info68_bin" -A "$files" > "$vgm2flac_cache_tag"
		if [[ -z "$tag_game" && -z "$tag_artist" && -z "$tag_machine" ]]; then
			tag_game=$(cat "$vgm2flac_cache_tag" | grep -i -a title: | sed 's/^.*: //' | head -1)
			tag_artist=$(cat "$vgm2flac_cache_tag" | grep -i -a artist: | sed 's/^.*: //' | head -1)
			tag_date=$(cat "$vgm2flac_cache_tag" | grep -i -a year: | sed 's/^.*: //' | head -1)
		fi
		# Tag
		tag_questions
		tag_album
		# Get total track
		local total_sub_track=$(cat "$vgm2flac_cache_tag" | grep -i -a track: | sed 's/^.*: //' | tail -1)
		# Track loop
		for sub_track in `seq -w 1 $total_sub_track`; do
			# Extract WAV
			local track_name=$(basename "${files%.*}")
			"$sc68_bin" -c -t "$sub_track" "$files" > "$sub_track".raw
			sox -t raw -r 44100 -b 16 -c 2 -L -e signed-integer "$sub_track".raw "$sub_track - $track_name".wav
			rm "$sub_track".raw
		done

		# Add lead 0 at filename
		rename_add_lead_zero
		# Generate wav array
		list_temp_files

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
	for files in "${lst_sox[@]}"; do
		# Test if data by measuring maximum difference between two successive samples
		local delta=$(sox -t raw -r 44100 -b 16 -c 2 -L -e signed-integer "$files" -n stat 2>&1 | grep "Maximum delta:" | awk '{print $3}')
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
if (( "${#lst_uade[@]}" )); then
	# Bin check & set
	uade123_bin
	for files in "${lst_uade[@]}"; do
		# Tag
		tag_machine="Amiga"
		tag_questions
		tag_album

		# Get total track
		local total_sub_track=$(uade123 -g "$files" | grep "subsongs:" | awk '/^subsongs:/ { print $NF }')
		# Total correction if 0
		if [ "$total_sub_track" -eq "0" ]; then
			total_sub_track="1"
		fi
		# Wav loop
		for sub_track in `seq -w 1 $total_sub_track`; do
			# Filename construction
			if [ "$total_sub_track" -eq "1" ]; then
				local file_name_base="${files##*/}"
				local file_name="${file_name_base#*.}"
			else
				local file_name_base="${files##*/}"
				local file_name="${file_name_base#*.}-$sub_track"
			fi
			# Wav extract
			(
			"$uade123_bin" --one --silence-timeout 5 --panning 0.8 --subsong "$sub_track" "$files" -f "$file_name".wav
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait
	done

	# Generate wav array
	list_temp_files

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
				"$vgm2wav_bin" "$files" "${files%.*}".wav
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
			;;
			*s98)
				shopt -u nocasematch							# Set case sentive
				# Extract WAV
				(
				"$vgm2wav_bin" --loops 1 "$files" "${files%.*}".wav
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
loop_vgmstream() {			# Various machines
if (( "${#lst_vgmstream[@]}" )); then
	# Bin check & set
	vgmstream_cli_bin

	for files in "${lst_vgmstream[@]}"; do
		# Tag
		tag_questions
		tag_album
		# Extract WAV
		(
		"$vgmstream_cli_bin" -o "${files%.*}".wav "$files"
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	for files in "${lst_vgmstream[@]}"; do
		# Tag
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
loop_zxtune_gbs() {			# GB/GBC
if (( "${#lst_zxtune_gbs[@]}" )); then
	# Bin check & set
	zxtune123_bin

	for gbs in "${lst_zxtune_gbs[@]}"; do

		# Tag extract
		tag_gbs_extract
		tag_game=$(xxd -ps -s 0x10 -l 32 "$gbs" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
		tag_artist=$(xxd -ps -s 0x30 -l 32 "$gbs" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')

		# Tag
		tag_questions
		tag_album

		# Get total real total track
		local file_total_track=$(xxd -ps -s 0x04 -l 1 "$gbs" | awk -Wposix '{printf("%d\n","0x" $1)}')	# Hex to decimal
		local total_sub_track="$file_total_track"

		# Wav loop
		for sub_track in `seq -w 1 $total_sub_track`; do
			# Extract WAV
			(
			"$zxtune123_bin" --wav filename="$sub_track".wav "$gbs"?#"$sub_track"
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

		# Wav duration loop
		for sub_track in `seq -w 1 $total_sub_track`; do
			# Tag
			gbs_track=$((10#"$sub_track"))
			tag_gbs

			# Duration change if different to 180s
			if [[ "$gbs_duration_second" != "180" ]]; then
				(
				ffmpeg $ffmpeg_log_lvl -y -i "$sub_track".wav -t $gbs_duration_second -acodec pcm_s16le -ar 44100 -f wav "$sub_track - $tag_song".wav \
				&& rm "$sub_track".wav &>/dev/null
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
			fi
		done
		wait

		# Flac loop
		for sub_track in `seq -w 1 $total_sub_track`; do
			# Tag
			gbs_track=$((10#"$sub_track"))
			tag_gbs

			# File variable for next function
			files="$sub_track - $tag_song.wav"
			# Peak normalisation to 0, false stereo detection 
			wav_normalization_channel_test
			# Fade out
			imported_sox_fade_out="$gbs_fading_second"
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
		done
		wait

	done
fi
}
loop_zxtune_nsf() {			# NES
if (( "${#lst_zxtune_nsf[@]}" )); then
	# Bin check & set
	zxtune123_bin

	for nsf in "${lst_zxtune_nsf[@]}"; do
		# Tag extract
		tag_nsf_extract
		tag_artist=$(xxd -ps -s 0x02E -l 32 "$nsf" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
		tag_game=$(xxd -ps -s 0x00E -l 32 "$nsf" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
		tag_machine="NES"
		tag_questions
		tag_album

		# Get total track
		local file_total_track=$(xxd -ps -s 0x006 -l 1 "$nsf" | awk -Wposix '{printf("%d\n","0x" $1)}')	# Hex to decimal
		local total_sub_track="$file_total_track"

		# Wav loop
		for sub_track in `seq -w 1 $total_sub_track`; do
			# Extract WAV
			(
			"$zxtune123_bin" --wav filename="$sub_track".wav "$nsf"?#"$sub_track"
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

		# Wav duration loop
		for sub_track in `seq -w 1 $total_sub_track`; do
			# Tag
			gbs_track=$((10#"$sub_track"))
			tag_gbs

			# Duration change if different to 180s
			if [[ "$nsf_duration_second" != "180" ]]; then
				(
				ffmpeg $ffmpeg_log_lvl -y -i "$sub_track".wav -t $gbs_duration_second -acodec pcm_s16le -ar 44100 -f wav "$sub_track - $tag_song".wav \
				&& rm "$sub_track".wav &>/dev/null
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
			fi
		done
		wait

		# Flac loop
		for sub_track in `seq -w 1 $total_sub_track`; do
			# Tag
			nbs_track=$((10#"$sub_track"))
			tag_nsf

			# File variable for next function
			files="$sub_track - $tag_song.wav"
			# Peak normalisation to 0, false stereo detection 
			wav_normalization_channel_test
			# Fade out
			imported_sox_fade_out="$nsf_fading_second"
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
		done
		wait
	done
fi
}
loop_zxtune_sid() {			# Commodore 64/128
if (( "${#lst_zxtune_sid[@]}" )); then
	# Bin check & set
	zxtune123_bin

	for files in "${lst_zxtune_sid[@]}"; do
		# Tag extract
		tag_sid
		tag_questions
		tag_album
		tag_song

		# Wav loop by track
		for sub_track in `seq -w 1 99`; do
			# Extract WAV
			"$zxtune123_bin" --wav filename="$sub_track - $tag_song".wav "$files"?#"$sub_track"
			# Break loop when fail
			if [ ! -f "$sub_track - $tag_song".wav ]; then
				break
			fi
		done

		# Generate wav array
		list_temp_files

		# if no wav, try without subtrack
		if [ "${#lst_wav[@]}" -eq 0 ]; then
			# Extract WAV
			"$zxtune123_bin" --wav filename="$tag_song".wav "$files"
			# Generate wav array
			list_temp_files
		fi

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
loop_zxtune_xfs() {			# PS1, PS2, NDS, Saturn, GBA, N64, Dreamcast
if (( "${#lst_zxtune_xsf[@]}" )); then
	# Bin check & set
	zxtune123_bin

	# Wav loop
	for files in "${lst_zxtune_xsf[@]}"; do
		# Extract WAV
		local file_name_base="${files%.*}"
		local file_name="${file_name_base##*/}"
		(
		"$zxtune123_bin" --wav filename="${file_name##*/}".wav "$files"
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
loop_zxtune_ym() {			# Amstrad CPC, Atari ST
if (( "${#lst_zxtune_ym[@]}" )); then
	# Bin check & set
	zxtune123_bin

	# Tag
	tag_questions
	tag_album
	
	# Wav loop
	for files in "${lst_zxtune_ym[@]}"; do
		# Extract WAV
		local file_name_base="${files%.*}"
		local file_name="${file_name_base##*/}"
		(
		"$zxtune123_bin" --wav filename="${file_name##*/}".wav "$files"
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Generate wav array
	list_temp_files

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

	# Tag
	tag_machine="ZX Spectrum"
	tag_questions
	tag_album
	
	# Wav loop
	for files in "${lst_zxtune_zx_spectrum[@]}"; do
		# Extract WAV
		local file_name_base="${files%.*}"
		local file_name="${file_name_base##*/}"
		(
		"$zxtune123_bin" --wav filename="${file_name##*/}".wav "$files"
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Generate wav array
	list_temp_files

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
tag_track_count=()
count=()
for files in "${lst_flac[@]}"; do
	tag_track_count=$(($count+1))
	count=$tag_track_count
	if [[ "${#tag_track_count}" -eq "1" ]] ; then				# if integer in one digit add 0
		tag_track_count="0$tag_track_count" 
	fi
	ffmpeg $ffmpeg_log_lvl -i "$files" -c:v copy -c:a copy -metadata TRACKNUMBER="$tag_track_count" -metadata TRACK="$tag_track_count" "${files%.*}"-temp.flac
	# If temp-file exist remove source and rename
	if [[ -f "${files%.*}-temp.flac" && -s "${files%.*}-temp.flac" ]]; then
		rm "$files" &>/dev/null
		mv "${files%.*}"-temp.flac "$files" &>/dev/null
	fi
done
}
tag_questions() {
if test -z "$tag_game"; then
	echo "Please indicate the game title"
	read -e -p " -> " tag_game
	echo
fi
if test -z "$tag_artist"; then
	echo "Please indicate the artist"
	read -e -p " -> " tag_artist
	echo
fi
if test -z "$tag_date"; then
	echo "Please indicate the release date"
	read -e -p " -> " tag_date
	echo
fi
if test -z "$tag_machine"; then
	echo "Please indicate the release platform"
	read -e -p " -> " tag_machine
	echo
fi
}
tag_album() {
tag_album=$(echo $tag_album | sed s#/#-#g | sed s#:#-#g)				# Replace eventualy "/" & ":" in string
tag_machine=$(echo $tag_machine | sed s#/#-#g | sed s#:#-#g)			# Replace eventualy "/" & ":" in string
tag_album="$tag_game ($tag_machine)"
}
tag_song() {
tag_song=$(basename "${files%.*}")
}

# Tag by files type
tag_gbs_extract() {			# GB/GBC
if [ "${#lst_m3u[@]}" -gt "0" ]; then
	local m3u_track_hex_test=$(cat "${gbs%.*}".m3u |  awk -F"," '{ print $2 }' | grep "$")
	if [[ -z "$m3u_track_hex_test" ]]; then
		cat "${gbs%.*}".m3u | sed '/^#/d' | uniq | sed -r '/^\s*$/d' | sort -t, -k2,2 -n \
		| sed 's/.*::/GAME::/' | sed -e 's/\\,/ -/g' > "$vgm2flac_cache_tag"
	else
		cat "${gbs%.*}".m3u | sed '/^#/d' | uniq | sed -r '/^\s*$/d' \
		| tr -d '$' | awk --non-decimal-data -F ',' -v OFS=',' '$1 {$2=("0x"$2)+1; print}' \
		| sort -t, -k2,2 -n | sed 's/.*::/GAME::/' | sed -e 's/\\,/ -/g' > "$vgm2flac_cache_tag"
	fi
fi
}
tag_gbs() {					# GB/GBC
if [ "${#lst_m3u[@]}" -gt "0" ]; then
	# Prevent track start at 0 in m3u
	local tag_track_test=$(cat "$vgm2flac_cache_tag" | head -1 | awk -F"," '{ print $2 }')
	if [[ "$tag_track_test" = "0" ]]; then
		gbs_track=$(("$gbs_track"-1))
	fi

	tag_song=$(cat "$vgm2flac_cache_tag" | grep ",$gbs_track," | awk -F"," '{ print $3 }')
	if [[ -z "$tag_song" ]]; then
		tag_song="[untitled]"
	fi
	# Get fade out and duration
	gbs_duration=$(cat "$vgm2flac_cache_tag" | grep ",$gbs_track," \
					| awk -F"," '{ print $4 }' | tr -d '[:space:]' \
					| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')			# Total duration in m:s
	if [[ -z "$gbs_duration" ]]; then
		gbs_duration_second="180"
	else
		gbs_duration_second=$(echo $gbs_duration | awk -F":" '{ print ($1 * 60) + $2 }' | tr -d '[:space:]')					# Total duration in s
	fi
	# Fade out
	gbs_fading_second=$(cat "$vgm2flac_cache_tag" | grep ",$gbs_track," | awk -F"," '{ print $(NF) }' | tr -d '[:space:]')			# Fade out duration in s
	if [[ "$gbs_fading_second" -ge "$gbs_duration_second" ]] ; then																# Prevent incoherence duration between fade out and total duration
		unset gbs_fading_second
	fi
else
	tag_song="[untitled]"
	gbs_duration_second="180"
fi
}
tag_nsf_extract() {			# NES
if [ "${#lst_m3u[@]}" -gt "0" ]; then
	local m3u_track_hex_test=$(cat "${nsf%.*}".m3u |  awk -F"," '{ print $2 }' | grep "$")
	if [[ -z "$m3u_track_hex_test" ]]; then
		cat "${nsf%.*}".m3u | sed '/^#/d' | uniq | sed -r '/^\s*$/d' | sort -t, -k2,2 -n \
		| sed 's/.*::/GAME::/' | sed -e 's/\\,/ -/g' > "$vgm2flac_cache_tag"
	else
		cat "${nsf%.*}".m3u | sed '/^#/d' | uniq | sed -r '/^\s*$/d' \
		| tr -d '$' | awk --non-decimal-data -F ',' -v OFS=',' '$1 {$2=("0x"$2)+1; print}' \
		| sort -t, -k2,2 -n | sed 's/.*::/GAME::/' | sed -e 's/\\,/ -/g' > "$vgm2flac_cache_tag"
	fi
fi
}
tag_nsf() {					# NES
if [ "${#lst_m3u[@]}" -gt "0" ]; then
	# Prevent track start at 0 in m3u
	local tag_track_test=$(cat "$vgm2flac_cache_tag" | head -1 | awk -F"," '{ print $2 }')
	if [[ "$tag_track_test" = "0" ]]; then
		nsf_track=$(("$nsf_track"-1))
	fi

	tag_song=$(cat "$vgm2flac_cache_tag" | grep ",$nbs_track," | awk -F"," '{ print $3 }')
	if [[ -z "$tag_song" ]]; then
		tag_song="[untitled]"
	fi

	# Get fade out and duration
	nsf_duration=$(cat "$vgm2flac_cache_tag" | grep ",$nbs_track," \
					| awk -F"," '{ print $(NF-2) }' | tr -d '[:space:]' \
					| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')			# Total duration in m:s
	if [[ $nsf_duration =~ ^0:* ]]; then
		nsf_duration=$(echo "$nsf_duration" | awk -F":" '{ print ($2":"$3) }')
	fi
	if [[ -z "$nsf_duration" ]]; then
		nsf_duration_second="180"
	else
		nsf_duration_second=$(echo $nsf_duration | awk -F":" '{ print ($1 * 60) + $2 }' | tr -d '[:space:]')				# Total duration in s
	fi

	# Fade out
	nsf_fading=$(cat "$vgm2flac_cache_tag" | grep ",$nbs_track," \
				| awk -F"," '{ print $(NF) }' | tr -d '[:space:]' \
				| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')			# Fade out duration in s
	if [[ $nsf_fading =~ ^0:* ]]; then
		nsf_fading=$(echo "$nsf_fading" | awk -F":" '{ print ($2":"$3) }')
	fi
	nsf_fading_second=$(echo $nsf_fading | awk -F":" '{ print ($1 * 60) + $2 }' | tr -d '[:space:]')						# Fade out duration in s
	if [[ "$nfs_fading_second" -ge "$nsf_duration_second" ]] ; then															# Prevent incoherence duration between fade out and total duration
		unset nsf_fading_second
	fi

else
	tag_song="[untitled]"
	nsf_duration_second="180"
fi
}
tag_s98() {					# NEC PC-6001, PC-6601, PC-8801,PC-9801, Sharp X1, Fujitsu FM-7 & FM TownsSharp X1
strings "$files" > "$vgm2flac_cache_tag"

tag_song=$(cat "$vgm2flac_cache_tag" | grep -i -a title | sed 's/^.*=//' | head -1)

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
local id666_test=$(xxd -ps -s 0x00023h -l 1 "$files")	# Test ID666 here
if [ "$id666_test" = "1a" ]; then						# 1a hex = 26 dec
	tag_song=$(xxd -ps -s 0x0002Eh -l 32 "$files" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')

	tag_artist_backup="$tag_artist"
	tag_artist=$(xxd -ps -s 0x000B1h -l 32 "$files" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
	if [[ -z "$tag_artist" ]]; then
		tag_artist="$tag_artist_backup"
	fi

	if [[ -z "$tag_game" ]]; then
		tag_game=$(xxd -ps -s 0x0004Eh -l 32 "$files" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
	fi
	spc_duration=$(xxd -ps -s 0x000A9h -l 3 "$files" | xxd -r -p | tr -d '\0')
	spc_fading=$(xxd -ps -s 0x000ACh -l 5 "$files" | xxd -r -p | tr -d '\0')
fi
if [[ -z "$tag_machine" ]]; then
	tag_machine="SNES"
fi
}
tag_vgm() {					# Various machines
"$vgm_tag_bin" -ShowTag8 "$files" > "$vgm2flac_cache_tag"

tag_song=$(sed -n 's/Track Title:/&\n/;s/.*\n//p' "$vgm2flac_cache_tag" | awk '{$1=$1}1')

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
strings "$files" | awk '/TAG/{y=1;next}y' > "$vgm2flac_cache_tag"

tag_song=$(cat "$vgm2flac_cache_tag" | grep -i -a title= | sed 's/^.*=//')

tag_artist_backup="$tag_artist"
tag_artist=$(cat "$vgm2flac_cache_tag" | grep -i -a artist= | sed 's/^.*=//')
if [[ -z "$tag_artist" ]]; then
	tag_artist="$tag_artist_backup"
fi

if [[ -z "$tag_game" && -z "$tag_date" ]]; then
	tag_game=$(cat "$vgm2flac_cache_tag" | grep -i -a game= | sed 's/^.*=//')
	tag_date=$(cat "$vgm2flac_cache_tag" | grep -i -a year= | sed 's/^.*=//')
fi

if [[ "${files##*.}" = "psf" || "${files##*.}" = "minipfs" ]]; then
	tag_machine="PS1"
elif [[ "${files##*.}" = "psf2" || "${files##*.}" = "minipfs2" ]]; then
	tag_machine="PS2"
elif [[ "${files##*.}" = "2sf" || "${files##*.}" = "mini2sf" ]]; then
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
}

# Temp clean & target filename/directory structure
rename_add_lead_zero() {
# Populate wav array
list_temp_files
if [ "${#lst_wav[@]}" -gt "0" ]; then											# If number of wav > 0
	for files in "${lst_wav[@]}"; do
		local number=$(echo $files | sed 's/[^0-9]*//g')
		local padded=$(printf "%02d" "${number#0}")
		local new_name=$(echo $files | sed "s/${number}/${padded}/")
		mv "$files" "$new_name" &>/dev/null
	done
fi
}
wav_remove() {
if [ "${#lst_wav[@]}" -gt "0" ]; then											# If number of wav > 0
	read -p "Remove wav files (temp audio)? [y/N]:" qarm
	case $qarm in
		"Y"|"y")
			for files in "${lst_wav[@]}"; do
				rm -f "$files" 2>/dev/null
			done
		;;
	esac
fi
}
mk_flac_directory() {
if [ "${#lst_flac[@]}" -gt "0" ]; then											# If number of flac > 0
	tag_date=$(echo $tag_date | sed s#/#-#g | sed s#:#-#g)			# Replace eventualy "/" & ":" in string
	local flac_directory="$tag_game ($tag_date) ($tag_machine)"
	if [ ! -d "$VGM_DIR" ]; then
		mkdir "$PWD/$flac_directory"
	fi
	for files in "${lst_flac[@]}"; do
		mv "$files" "$PWD/$flac_directory"
	done
fi
}

# Bin check & set
common_bin

# Files source check & set
check_cache_directory
list_source_files

# Encoding/tag loop
loop_adplay
loop_bchunk
loop_ffmpeg
loop_fluidsynth
loop_sc68
loop_sox
loop_uade
loop_vgm2wav
loop_vgmstream
loop_zxtune_gbs
loop_zxtune_nsf
loop_zxtune_sid
loop_zxtune_xfs
loop_zxtune_ym
loop_zxtune_zx_spectrum

# Clean
list_temp_files
list_target_files
tag_track
mk_flac_directory
wav_remove
clean_cache_directory

exit
