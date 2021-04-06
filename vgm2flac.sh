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
core_dependency=(bc bchunk ffmpeg ffprobe sox xxd)
ffmpeg_log_lvl="-hide_banner -loglevel panic -stats"										# ffmpeg log level
nprocessor=$(nproc --all)																	# Set number of processor

# Output
default_wav_fade_out="5"																	# Default fade out value in second, apply to all file during more than 10s
default_wav_bit_depth="pcm_s16le"															# Wav bit depth must be pcm_s16le, pcm_s24le or pcm_s32le
default_flac_bit_depth="s16"																# Flac bit depth must be s16 or s32
default_peakdb_norm="1"																		# Peak db normalization option, this value is written as positive but is used in negative, e.g. 4 = -4
# Game Boy
gbs_default_max_duration="360"																# In second
# Midi
fluidsynth_soundfont=""																		# Set soundfont file that fluidsynth will use for the conversion, leave empty it will use the default soundfont
munt_rom_path=""																			# Set munt ROM dir (Roland MT-32 ROM)
# NES
nsf_default_max_duration="180"																# In second
# sc68
sc68_loops="2"
# PC-Engine
hes_default_max_duration="180"																# In second
# vgm2wav
vgm2wav_samplerate="44100"																	# Sample rate in Hz
vgm2wav_bit_depth="16"																		# Bit depth must be 16 or 24
vgm2wav_loops="2"
# zxtune_sid
zxtune_duration_without_loop="15"															# Track duration is second that does not trigger a music loop 

# Extensions
ext_adplay="hsq|imf|sdb|sqx|wlf"
ext_bchunk_cue="cue"
ext_bchunk_iso="bin|img|iso"
ext_ffmpeg="mod|spc|xa"
ext_ffmpeg_gbs="gbs"
ext_ffmpeg_hes="hes"
ext_midi="mid"
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
local system_bin_location=$(which $bin_name)

if test -n "$system_bin_location"; then
	info68_bin="$system_bin_location"
else
	echo "Break, $bin_name is not installed"
	exit
fi
}
munt_bin() {
local bin_name="mt32emu-smf2wav"
local system_bin_location=$(which $bin_name)

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

# Messages
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
mapfile -t lst_sc68 < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_sc68')$' 2>/dev/null | sort)
mapfile -t lst_sox < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_sox')$' 2>/dev/null | sort)
mapfile -t lst_vgm2wav < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_vgm2wav')$' 2>/dev/null | sort)
mapfile -t lst_zxtune_ay < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_zxtune_ay')$' 2>/dev/null | sort)
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
list_wav_files() {
mapfile -t lst_wav < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('wav')$' 2>/dev/null | sort)
}
list_flac_files() {
mapfile -t lst_flac < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('flac')$' 2>/dev/null | sort)
}
list_flac_validation() {
if ! [[ "${#lst_flac[@]}" = "0" ]]; then
	for i in "${!lst_flac[@]}"; do
		local flac_test=$(soxi "${lst_flac[i]}" 2>/dev/null)
		if [ -z "$flac_test" ]; then
			lst_flac_in_error+=( "${lst_flac[i]}" )
		fi
	done
fi
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
wav_remove_empty() {
# Remove wav empty
for files in "${lst_wav[@]}"; do
	local test_empty_wav=$(sox "$files" -n stat 2>&1 | grep "Maximum amplitude:" | awk '{print $3}')
	if [[ "$test_empty_wav" = "0.000000" ]]; then
		rm "$files"
	fi
done
}
wav_fade_out() {
# Out fade, if audio during more than 10s
local test_duration=$(ffprobe -i "${files%.*}".wav -show_format -v quiet | grep duration | sed 's/.*=//' | cut -f1 -d".")
if [[ "$test_duration" -gt 10 ]] ; then
	local duration=$(soxi -d "${files%.*}".wav)
	local sox_fade_in="0:0.0"
	if [[ -z "$imported_sox_fade_out" ]]; then
		local sox_fade_out="0:$default_wav_fade_out"
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
if [[ "$testdb" = *"-"* ]] || [[ "$testdb" = "0.0" ]]; then
	local db=$(echo "$testdb" | cut -c2- | awk -v var="$default_peakdb_norm" '{print $1-var}')dB
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
ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav $afilter $confchan -acodec "$default_wav_bit_depth" -f wav temp-out.wav
rm "${files%.*}".wav &>/dev/null
mv temp-out.wav "${files%.*}".wav &>/dev/null
}
wav2flac() {
ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav -acodec flac -compression_level 12 -sample_fmt "$default_flac_bit_depth" -metadata title="$tag_song" -metadata album="$tag_album" -metadata artist="$tag_artist" -metadata date="$tag_date" "${files%.*}".flac
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
	for gbs in "${lst_ffmpeg_gbs[@]}"; do
		# Tags
		tag_gbs_extract
		tag_machine="Game Boy"
		tag_questions
		tag_album

		# Get total real total track
		local file_total_track=$(xxd -ps -s 0x04 -l 1 "$gbs" | awk -Wposix '{printf("%d\n","0x" $1)}')	# Hex to decimal
		local total_sub_track=$(("$file_total_track"-1))

		# Wav loop
		for sub_track in `seq -w 0 $total_sub_track`; do
			# Tag
			gbs_track=$((10#"$sub_track"))
			tag_gbs
			(
			ffmpeg $ffmpeg_log_lvl -track_index "$sub_track" -y -i "$gbs" -t $gbs_duration_second -channel_layout mono -acodec pcm_s16le -ar 44100 -f wav "$sub_track - $tag_song".wav
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

		# Flac loop
		for sub_track in `seq -w 0 $total_sub_track`; do
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
loop_ffmpeg_hes() {			# PC-Engine
if (( "${#lst_ffmpeg_hes[@]}" )); then
	for hes in "${lst_ffmpeg_hes[@]}"; do
		# Tags
		tag_hes_extract
		tag_machine="PC-Engine"
		tag_questions
		tag_album

		# Get total track
		local total_sub_track="256"

		# Wav loop
		for sub_track in `seq -w 0 $total_sub_track`; do
			# Tag
			hes_track=$((10#"$sub_track"))
			tag_hes

			# Extract WAV
			(
			ffmpeg $ffmpeg_log_lvl -track_index "$sub_track" -y -i "$hes" -t $hes_duration_second -acodec pcm_s16le -ar 44100 -f wav "$sub_track - $tag_song".wav
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

		# Remove empty wav
		list_wav_files
		wav_remove_empty

		for sub_track in `seq -w 0 $total_sub_track`; do
			# Tag
			hes_track=$((10#"$sub_track"))
			tag_hes
			# File variable for next function
			files="$sub_track - $tag_song.wav"
			# Peak normalisation to 0, false stereo detection 
			wav_normalization_channel_test
			# Fade out
			imported_sox_fade_out="$hes_fading_second"
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
loop_midi() {				# PC midi
if (( "${#lst_midi[@]}" )); then
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
			local midi_bin="$fluidsynth_bin"
			tag_pc_sound_module="Soundfont"
		;;
		"1")
			munt_bin
			local midi_bin="$munt_bin"
			tag_pc_sound_module="Roland MT-32"
		;;
		*)
			fluidsynth_bin
			local midi_bin="$fluidsynth_bin"
			local midi_choice="0"
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
				local fluidsynth_loop_nb="1"
			;;
			"2")
				local fluidsynth_loop_nb="2"
			;;
			*)
				local fluidsynth_loop_nb="1"
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
				-o "${files%.*}".wav "$files"
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
			"$sc68_bin" -l "$sc68_loops" -c -t "$sub_track" "$files" > "$sub_track".raw
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
if (( "${#lst_all_files[@]}" )); then
	# Bin check & set
	uade123_bin
	# Test all files
	lst_uade=()
	for files in "${lst_all_files[@]}"; do
		local uade_test_result=$("$uade123_bin" -g "$files" 2>/dev/null)
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
			local total_track=$("$uade123_bin" -g "$files" | grep "subsongs:" | awk '/^subsongs:/ { print $NF }')
			local current_track=$("$uade123_bin" -g "$files" | grep "subsongs:" | awk '/^subsongs:/ { print $3 }')
			local diff_track=$(( current_track - total_track ))
			# Wav loop
			for sub_track in `seq -w $current_track $total_track`; do
				# Filename construction
				if [ "$diff_track" -eq "0" ]; then
					local file_name="$files"
				else
					local file_name="${files}-$sub_track"
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

	for files in "${lst_all_files[@]}"; do
		if ! [[ "${files##*.}" = "wav" || "${files##*.}" = "flac" ]]; then
			local vgmstream_test_result=$("$vgmstream_cli_bin" -m "$files" 2>/dev/null)
			if [ "${#vgmstream_test_result}" -gt "0" ] && ! [[ "${files[@]##*.,,}" = "txth" ]]; then	# If vgmstream ok add to array
				if ! compgen -G "$files*.wav" > /dev/null; then											# If no wav already output ok add to array
					lst_vgmstream+=("$files")
				fi
			fi
		fi
	done

	for files in "${lst_vgmstream[@]}"; do
		# Tag
		tag_questions
		tag_album
		# Get total track
		local total_sub_track=$("$vgmstream_cli_bin" -m "$files" | grep -i -a "stream count" | sed 's/^.*: //')
		# Record output name
		if [[ -z "$total_sub_track" ]] || [[ "$total_sub_track" = "1" ]]; then
			lst_wav+=("${files%.*}".wav)
		else
			lst_wav+=("${files%.*}"-"$sub_track".wav)
		fi
		# Extract WAV
		(
			if [[ -z "$total_sub_track" ]] || [[ "$total_sub_track" = "1" ]]; then
				"$vgmstream_cli_bin" -o "${files%.*}".wav "$files"
			else
				# Multi track loop
				for sub_track in `seq -w 1 $total_sub_track`; do
					"$vgmstream_cli_bin" -s "$sub_track" -o "${files%.*}"-"$sub_track".wav "$files"
				done
			fi
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Generate wav array
	#list_wav_files

	# Flac loop
	for files in "${lst_wav[@]}"; do
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
		for sub_track in `seq -w 1 99`; do
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
loop_zxtune_nsf() {			# NES
if (( "${#lst_zxtune_nsf[@]}" )); then
	# Bin check & set
	zxtune123_bin

	for nsf in "${lst_zxtune_nsf[@]}"; do
		# Tag extract
		tag_nsf_extract
		tag_machine="NES"
		tag_questions
		tag_album

		# Get total track
		local file_total_track=$(xxd -ps -s 0x006 -l 1 "$nsf" | awk -Wposix '{printf("%d\n","0x" $1)}')	# Hex to decimal
		local total_sub_track="$file_total_track"

		# Wav loop
		for sub_track in `seq -w 1 $total_sub_track`; do
			# Extract WAV
			"$zxtune123_bin" --wav filename="$sub_track".wav "$nsf"?#"$sub_track"

			# Tag
			nsf_track=$((10#"$sub_track"))
			tag_nsf

			# Duration change if different to 180s
			if [[ "$nsf_duration_second" != "180" ]]; then
				ffmpeg $ffmpeg_log_lvl -y -i "$sub_track".wav -t $nsf_duration_second -acodec pcm_s16le -ar 44100 -f wav "$sub_track - $tag_song".wav
				rm "$sub_track".wav &>/dev/null
			else
				# no duration modification, rename
				mv "$sub_track".wav "$sub_track - $tag_song".wav
			fi

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
		stty igncr									# Disable the enter key

		# Wav loop by track
		for sub_track in `seq -w 1 99`; do
			# Extract WAV
			"$zxtune123_bin" --wav filename="$sub_track - $tag_song"0.wav "$files"?#"$sub_track"

			# 2 loops contruction
			local test_duration=$(ffprobe -i "$sub_track - $tag_song"0.wav -show_format -v quiet | grep duration | sed 's/.*=//' | cut -f1 -d".")
			if [[ "$test_duration" -gt "$zxtune_duration_without_loop" ]] ; then
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

			# 2 loops contruction
			local test_duration=$(ffprobe -i "$tag_song"0.wav -show_format -v quiet | grep duration | sed 's/.*=//' | cut -f1 -d".")
			if [[ "$test_duration" -gt "$zxtune_duration_without_loop" ]] ; then
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
			# Generate wav array
			list_wav_files
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
	stty -igncr									# Enable the enter key
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
		local file_name_random=$(( RANDOM % 10000 ))
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
	tag_track_count=()
	count=()
	for files in "${lst_flac[@]}"; do
		tag_track_count=$(($count+1))
		count=$tag_track_count
		if [[ "${#tag_track_count}" -eq "1" ]] ; then						# if integer in one digit add 0
			tag_track_count="0$tag_track_count" 
		fi
		ffmpeg $ffmpeg_log_lvl -i "$files" -c:v copy -c:a copy -metadata TRACKNUMBER="$tag_track_count" -metadata TRACK="$tag_track_count" "${files%.*}"-temp.flac
		# If temp-file exist remove source and rename
		if [[ -f "${files%.*}-temp.flac" && -s "${files%.*}-temp.flac" ]]; then
			rm "$files" &>/dev/null
			mv "${files%.*}"-temp.flac "$files" &>/dev/null
		fi
	done
fi
}
tag_questions() {
if test -z "$tag_game"; then
	echo "Please indicate the game title"
	read -e -p " -> " tag_game
	echo
	if test -z "$tag_game"; then
		tag_game="[unknown game]"
	fi
fi
if test -z "$tag_artist"; then
	echo "Please indicate the artist (leave empty for [unknown])"
	read -e -p " -> " tag_artist
	echo
	if test -z "$tag_artist"; then
		tag_artist="[unknown]"
	fi
fi
if test -z "$tag_date"; then
	echo "Please indicate the release date"
	read -e -p " -> " tag_date
	echo
	if test -z "$tag_date"; then
		tag_date="[unknown date]"
	fi
fi
if test -z "$tag_machine"; then
	echo "Please indicate the release platform"
	read -e -p " -> " tag_machine
	echo
	if test -z "$tag_machine"; then
		tag_machine="[unknown machine]"
	fi
fi
}
tag_album() {
if [[ -z "$tag_pc_sound_module" ]]; then
	tag_album="$tag_game ($tag_machine)"
else
	tag_album="$tag_game ($tag_machine) ($tag_pc_sound_module)"
fi
}
tag_song() {
tag_song=$(basename "${files%.*}")
}

# Tag by files type
tag_ay() {					# Amstrad CPC, ZX Spectrum
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
tag_gbs_extract() {			# GB/GBC
if [ "${#lst_m3u[@]}" -gt "0" ]; then
	m3u_track_hex_test=$(cat "${gbs%.*}".m3u |  awk -F"," '{ print $2 }' | grep -F -e "$")
	tag_game=$(xxd -ps -s 0x10 -l 32 "$gbs" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
	tag_artist=$(xxd -ps -s 0x30 -l 32 "$gbs" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
	tag_date=$(cat "${gbs%.*}".m3u | grep "@DATE" | awk -v n=3 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' | tr -d "\n\r")
	if [[ -z "$m3u_track_hex_test" ]]; then													# Decimal track
		cat "${gbs%.*}".m3u | sed '/^#/d' | uniq | sed -r '/^\s*$/d' | sort -t, -k2,2 -n \
		| sed 's/.*::/GAME::/' | sed -e 's/\\,/ -/g' > "$vgm2flac_cache_tag"
	else																					# Hexadecimal track
		cat "${gbs%.*}".m3u | sed '/^#/d' | uniq | sed -r '/^\s*$/d' \
		| tr -d '$' | awk --non-decimal-data -F ',' -v OFS=',' '$1 {$2=("0x"$2)+0; print}' \
		| sort -t, -k2,2 -n | sed 's/.*::/GAME::/' | sed -e 's/\\,/ -/g' > "$vgm2flac_cache_tag"
	fi
fi
}
tag_gbs() {					# GB/GBC
if [ "${#lst_m3u[@]}" -gt "0" ]; then
	# Prevent track start at 0 in m3u
	local tag_track_test=$(cat "$vgm2flac_cache_tag" | head -1 | awk -F"," '{ print $2 }')

	tag_song=$(cat "$vgm2flac_cache_tag" | awk -v var=$gbs_track -F',' '$2 == var { print $0 }' | awk -F"," '{ print $3 }')
	if [[ -z "$tag_song" ]]; then
		tag_song="[untitled]"
	fi

	# Get fade out and duration
	gbs_duration=$(cat "$vgm2flac_cache_tag" | grep ",$gbs_track," \
					| awk -F"," '{ print $4 }' | tr -d '[:space:]' \
					| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')				# Total duration in ?:m:s
	if [[ -n "$gbs_duration" ]]; then
		local gbs_duration_format=$(echo "$gbs_duration"| grep -o ":" | wc -l)
		if [[ "$gbs_duration_format" = "2" ]]; then										# IF duration is in this format = h:m:s
			local gbs_duration=$(echo "$gbs_duration" | awk -F":" '{ print ($2":"$3) }')
		elif [[ "$gbs_duration_format" = "0" && -n "$gbs_duration" ]]; then				# IF duration is in this format = s
			local gbs_duration=$(echo "$gbs_duration" | sed 's/^/00:/')
		fi
		gbs_duration_second=$(echo $gbs_duration | awk -F":" '{ print ($1 * 60) + $2 }' | tr -d '[:space:]')	# Total duration in s
	else
		gbs_duration_second="$gbs_default_max_duration"
	fi

	# Fade out
	local gbs_fading=$(cat "$vgm2flac_cache_tag" | grep ",$gbs_track," \
				| awk -F"," '{ print $(NF) }' | tr -d '[:space:]' \
				| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')					# Fade out duration in ?:m:s
	if [[ -n "$gbs_fading" ]]; then
		local gbs_fading_format=$(echo "$gbs_fading"| grep -o ":" | wc -l)
		if [[ "$gbs_fading_format" = "2" ]]; then										# IF duration is in this format = h:m:s
			local gbs_fading=$(echo "$gbs_fading" | awk -F":" '{ print ($2":"$3) }')
		elif [[ "$gbs_fading_format" = "0" && -n "$gbs_fading" ]]; then					# IF duration is in this format = s
			local gbs_fading=$(echo "$gbs_fading" | sed 's/^/00:/')
		fi
		gbs_fading_second=$(echo "$gbs_fading" | awk -F":" '{ print ($1 * 60) + $2 }' | tr -d '[:space:]')			# Fade out duration in s
		if [[ "$gbs_fading_second" -ge "gbs_duration_second" ]] ; then												# Prevent incoherence duration between fade out and total duration
			unset gbs_fading_second
		fi
	fi

else
	tag_song="[untitled]"
	gbs_duration_second="$gbs_default_max_duration"
fi
}
tag_hes_extract() {			# PC Engine
if [ "${#lst_m3u[@]}" -gt "0" ]; then
	m3u_track_hex_test=$(cat "${hes%.*}".m3u |  awk -F"," '{ print $2 }' | grep -F -e "$")
	tag_game=$(cat "${hes%.*}".m3u | grep "@TITLE" | awk -v n=3 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' | tr -d "\n\r")
	tag_artist=$(cat "${hes%.*}".m3u | grep "@COMPOSER" | awk -v n=3 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' | tr -d "\n\r")
	tag_date=$(cat "${hes%.*}".m3u | grep "@DATE" | awk -v n=3 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' | tr -d "\n\r")
	if [[ -z "$m3u_track_hex_test" ]]; then													# Decimal track
		cat "${hes%.*}".m3u | sed '/^#/d' | uniq | sed -r '/^\s*$/d' | sort -t, -k2,2 -n \
		| sed 's/.*::/GAME::/' | sed -e 's/\\,/ -/g' > "$vgm2flac_cache_tag"
	else																					# Hexadecimal track
		cat "${hes%.*}".m3u | sed '/^#/d' | uniq | sed -r '/^\s*$/d' \
		| tr -d '$' | awk --non-decimal-data -F ',' -v OFS=',' '$1 {$2=("0x"$2)+0; print}' \
		| sort -t, -k2,2 -n | sed 's/.*::/GAME::/' | sed -e 's/\\,/ -/g' > "$vgm2flac_cache_tag"
	fi
fi
}
tag_hes() {					# PC Engine
if [ "${#lst_m3u[@]}" -gt "0" ]; then
	# Prevent track start at 0 in m3u
	local tag_track_test=$(cat "$vgm2flac_cache_tag" | head -1 | awk -F"," '{ print $2 }')

	tag_song=$(cat "$vgm2flac_cache_tag" | awk -v var=$hes_track -F',' '$2 == var { print $0 }' | awk -F"," '{ print $3 }')
	if [[ -z "$tag_song" ]]; then
		tag_song="[untitled]"
	fi

	# Get duration
	local hes_duration=$(cat "$vgm2flac_cache_tag" | grep ",$hes_track," \
					| awk -F"," '{ print $4 }' | tr -d '[:space:]' \
					| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')				# Total duration in ?:m:s
	if [[ -n "$hes_duration" ]]; then
		local hes_duration_format=$(echo "$hes_duration"| grep -o ":" | wc -l)
		if [[ "$hes_duration_format" = "2" ]]; then										# IF duration is in this format = h:m:s
			local hes_duration=$(echo "$hes_duration" | awk -F":" '{ print ($2":"$3) }')
		elif [[ "$hes_duration_format" = "0" && -n "$hes_duration" ]]; then				# IF duration is in this format = s
			local hes_duration=$(echo "$hes_duration" | sed 's/^/00:/')
		fi
		hes_duration_second=$(echo $hes_duration | awk -F":" '{ print ($1 * 60) + $2 }' | tr -d '[:space:]')		# Total duration in s
	else
		hes_duration_second="$hes_default_max_duration"
	fi

	# Fade out
	local hes_fading=$(cat "$vgm2flac_cache_tag" | grep ",$hes_track," \
				| awk -F"," '{ print $(NF) }' | tr -d '[:space:]' \
				| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')					# Fade out duration in ?:m:s
	if [[ -n "$hes_fading" ]]; then
		local hes_fading_format=$(echo "$hes_fading"| grep -o ":" | wc -l)
		if [[ "$hes_fading_format" = "2" ]]; then										# IF duration is in this format = h:m:s
			local hes_fading=$(echo "$hes_fading" | awk -F":" '{ print ($2":"$3) }')
		elif [[ "$hes_fading_format" = "0" && -n "$hes_fading" ]]; then					# IF duration is in this format = s
			local hes_fading=$(echo "$hes_fading" | sed 's/^/00:/')
		fi
		hes_fading_second=$(echo "$hes_fading" | awk -F":" '{ print ($1 * 60) + $2 }' | tr -d '[:space:]')		# Fade out duration in s
		if [[ "$hes_fading_second" -ge "$hes_duration_second" ]] ; then											# Prevent incoherence duration between fade out and total duration
			unset hes_fading_second
		fi
	fi

else
	tag_song="[untitled]"
	hes_duration_second="$hes_default_max_duration"
fi
}
tag_nsf_extract() {			# NES
if [ "${#lst_m3u[@]}" -gt "0" ]; then
	m3u_track_hex_test=$(cat "${nsf%.*}".m3u |  awk -F"," '{ print $2 }' | grep -F -e "$")
	tag_game=$(xxd -ps -s 0x00E -l 32 "$nsf" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
	tag_artist=$(xxd -ps -s 0x02E -l 32 "$nsf" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
	if [[ -z "$m3u_track_hex_test" ]]; then													# Decimal track
		cat "${nsf%.*}".m3u | sed '/^#/d' | uniq | sed -r '/^\s*$/d' | sort -t, -k2,2 -n \
		| sed 's/.*::/GAME::/' | sed -e 's/\\,/ -/g' > "$vgm2flac_cache_tag"
	else																					# Hexadecimal track
		cat "${nsf%.*}".m3u | sed '/^#/d' | uniq | sed -r '/^\s*$/d' \
		| tr -d '$' | awk --non-decimal-data -F ',' -v OFS=',' '$1 {$2=("0x"$2)+0; print}' \
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

	tag_song=$(cat "$vgm2flac_cache_tag" | grep ",$nsf_track," | awk -F"," '{ print $3 }')
	if [[ -z "$tag_song" ]]; then
		tag_song="[untitled]"
	fi

	# Get duration
	local nsf_duration=$(cat "$vgm2flac_cache_tag" | grep ",$nsf_track," \
					| awk -F"," '{ print $4 }' | tr -d '[:space:]' \
					| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')				# Total duration in ?:m:s
	if [[ -n "$nsf_duration" ]]; then
		local nfs_duration_format=$(echo "$nsf_duration"| grep -o ":" | wc -l)
		if [[ "$nfs_duration_format" = "2" ]]; then										# IF duration is in this format = h:m:s
			local nsf_duration=$(echo "$nsf_duration" | awk -F":" '{ print ($2":"$3) }')
		elif [[ "$nfs_duration_format" = "0" && -n "$nsf_duration" ]]; then				# IF duration is in this format = s
			local nsf_duration=$(echo "$nsf_duration" | sed 's/^/00:/')
		fi
		nsf_duration_second=$(echo $nsf_duration | awk -F":" '{ print ($1 * 60) + $2 }' | tr -d '[:space:]')	# Total duration in s
	else
		nsf_duration_second="$nsf_default_max_duration"
	fi

	# Fade out
	local nsf_fading=$(cat "$vgm2flac_cache_tag" | grep ",$nsf_track," \
				| awk -F"," '{ print $(NF) }' | tr -d '[:space:]' \
				| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')					# Fade out duration in ?:m:s
	if [[ -n "$nsf_fading" ]]; then
		local nsf_fading_format=$(echo "$nsf_fading"| grep -o ":" | wc -l)
		if [[ "$nsf_fading_format" = "2" ]]; then										# IF duration is in this format = h:m:s
			local nsf_fading=$(echo "$nsf_fading" | awk -F":" '{ print ($2":"$3) }')
		elif [[ "$nsf_fading_format" = "0" && -n "$nsf_fading" ]]; then					# IF duration is in this format = s
			local nsf_fading=$(echo "$nsf_fading" | sed 's/^/00:/')
		fi
		nsf_fading_second=$(echo "$nsf_fading" | awk -F":" '{ print ($1 * 60) + $2 }' | tr -d '[:space:]')		# Fade out duration in s
		if [[ "$nsf_fading_second" -ge "$nsf_duration_second" ]] ; then											# Prevent incoherence duration between fade out and total duration
			unset nsf_fading_second
		fi
	fi

else
	tag_song="[untitled]"
	nsf_duration_second="$nsf_default_max_duration"
fi
}
tag_s98() {					# NEC PC-6001, PC-6601, PC-8801,PC-9801, Sharp X1, Fujitsu FM-7 & FM TownsSharp X1
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
strings "$files" | awk '/TAG/{y=1;next}y' > "$vgm2flac_cache_tag"

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
# Populate wav array
list_wav_files
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
flac_corrupted_remove() {
if [ "${#lst_flac_in_error[@]}" -gt "0" ]; then											# If number of flac corrupted > 0
	for files in "${lst_flac_in_error[@]}"; do
		rm -f "$files" 2>/dev/null
	done
fi
}
mk_target_directory() {
if [ "${#lst_flac[@]}" -gt "0" ] && [ "${#lst_wav[@]}" -gt "0" ]; then		# If number of flac > 0
	local tag_game=$(echo $tag_game | sed s#/#-#g | sed s#:#-#g)					# Replace eventualy "/" & ":" in string
	local tag_machine=$(echo $tag_machine | sed s#/#-#g | sed s#:#-#g)				# Replace eventualy "/" & ":" in string
	local tag_date=$(echo $tag_date | sed s#/#-#g | sed s#:#-#g)					# Replace eventualy "/" & ":" in string
	if [[ -z "$tag_pc_sound_module" ]]; then
		local target_directory="$tag_game ($tag_date) ($tag_machine)"
	else
		local target_directory="$tag_game ($tag_date) ($tag_machine) ($tag_pc_sound_module)"
	fi
	if [ ! -d "$VGM_DIR" ]; then
		mkdir "$PWD/$target_directory"
	fi
	for files in "${lst_flac[@]}"; do
		mv "$files" "$PWD/$target_directory"
	done
fi
}
end_functions() {
list_wav_files
list_flac_files
list_flac_validation
tag_track
mk_target_directory
clean_cache_directory
display_flac_in_error
wav_remove
flac_corrupted_remove
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
loop_ffmpeg_gbs
loop_ffmpeg_hes
loop_midi
loop_sc68
loop_sox
loop_vgm2wav
loop_zxtune_ay
loop_zxtune_nsf
loop_zxtune_sid
loop_zxtune_xfs
loop_zxtune_ym
loop_zxtune_zx_spectrum
loop_uade
loop_vgmstream
end_functions

exit
