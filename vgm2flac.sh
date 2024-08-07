#!/usr/bin/env bash
# shellcheck disable=SC2001,SC2015,SC2026,SC2046,SC2076,SC2086,SC2185
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

# Core
core_dependency=(
	'awk'
	'bash'
	'bc'
	'ffmpeg'
	'ffprobe'
	'find'
	'grep'
	'sed'
	'sox'
	'soxi'
	'xxd')
ffmpeg_log_lvl="-hide_banner -loglevel quiet"												# ffmpeg log level
nprocessor=$(grep -cE 'processor' /proc/cpuinfo)											# Set number of processor

# Output
encoder_dependency=(
	'flac'
	'metaflac'
	'mac'
	'mutagen-inspect'
	'opusenc'
	'rsgain'
	'wavpack'
	'wvtag'
)
## WAV
default_wav_bit_depth="pcm_s16le"															# Wav bit depth must be pcm_s16le, pcm_s24le or pcm_s32le
default_wav_fade_out="6"																	# Fade out value in second, apply to all file during more than 10s
default_peakdb_norm="1"																		# Peak db normalization option, this value is written as positive but is used as negative, e.g. 4 = -4
default_silent_db_cut="85"																	# Silence db value for cut file
default_agressive_silent_db_cut="58"														# Agressive silence db value for cut file
## FLAC with ffmpeg
default_ffmpeg_flac_bit_depth="s16"															# ffmpeg FLAC bit depth, must be s16 or s32
default_ffmpeg_flac_lvl="12"																# ffmpeg FLAC compression level, 0 to 12
## FLAC with flac bin
default_flac_lvl="-8"																# FLAC bin compression level
## WAVPACK
default_wavpack_lvl="-hhx4"
## Monkey's Audio
default_mac_lvl="-c5000"
## Opus
default_opus_bitrate="192"

# Input
decoder_dependency=(
	'adplay'
	'asapconv'
	'bchunk'
	'gsf2wav'
	'fluidsynth'
	'info68'
	'mednafen'
	'mt32emu-smf2wav'
	'nsf2wav'
	'sc68'
	'sidplayfp'
	'simple_mdx2wav'
	'vgm2wav'
	'vgm_tag'
	'vgmstream-cli'
	'uade123'
	'wildmidi'
	'xmp'
	'zxtune123'
)
## Atari ST
sc68_loops="1"
## Commodore 64/128
hvsc_directory=""																			# Directory containing extracted archive of https://hvsc.c64.org/downloads
sid_default_max_duration="360"																# Max track duration in second
## Game Boy, NES, PC-Engine
xxs_default_max_duration="360"																# Max track duration in second
## Midi
fluidsynth_soundfont=""																		# Set soundfont file that fluidsynth will use for the conversion, leave empty it will use the default soundfont
munt_rom_path=""																			# Set munt ROM dir (Roland MT-32 ROM)
## SNES
spc_default_duration="180"																	# In second
## vgm2wav
vgm2wav_samplerate="44100"																	# Sample rate in Hz
vgm2wav_bit_depth="16"																		# Bit depth must be 16 or 24
vgm2wav_loops="2"
## vgmstream
vgmstream_loops="1"																			# Number of loop made by vgmstream

# Extensions
ext_adplay="adl|amd|bam|cff|cmf|d00|dfm|ddt|dtm|got|hsc|hsq|imf|laa|ksm|mdi|mtk|rad|rol|sdb|sqx|wlf|xms|xsm"
ext_asapconv="sap"
ext_bchunk_cue="cue"
ext_bchunk_iso="bin|img|iso"
ext_ffmpeg_gbs="gbs"
ext_ffmpeg_hes="hes"
ext_ffmpeg_spc="spc"
ext_gsf="gsf|minigsf"
ext_mdx2wav="mdx"
ext_mednafen_snsf="minisnsf|snsf"
ext_midi="mid"
ext_nsfplay_nsf="nsf"
ext_nsfplay_nsfe="nsfe"
ext_sc68="sc68|snd|sndh"
ext_sidplayfp_sid="sid|prg"
ext_sox="bin|pcm|raw"
ext_playlist="m3u"
ext_vgm2wav="s98|vgm|vgz"
ext_wildmidi="hmi|hmp|xmi"
ext_zxtune_ay="ay"
ext_zxtune_xsf="2sf|dsf|psf|psf2|mini2sf|minidsf|minipsf|minipsf2|minissf|miniusf|minincsf|ncsf|ssf|usf"
ext_zxtune_ym="ym"
ext_zxtune_zx_spectrum="asc|psc|pt2|pt3|sqt|stc|stp"
# Extensions exclude from find all files
ext_archive_exclude="7z|rar|zip"
ext_audio_exclude="ape|flac|kss|m4a|mp2|mp3|ogg|opus|wav|wv"
ext_img_exclude="gif|jpg|jpeg|png|tiff|webp"
ext_lib_exclude="2sflib|dsflib|gsflib|ssflib|psflib|txth|usflib"
ext_various_exclude="bash|cue|m3u|m3u8|pdf|py|sh|txt"
ext_video_exclude="avi|mp4|mkv"
ext_find_exclude="${ext_archive_exclude}| \
					${ext_audio_exclude}| \
					${ext_img_exclude}| \
					${ext_lib_exclude}| \
					${ext_various_exclude}| \
					${ext_video_exclude}"
ext_find_exclude=$(echo ${ext_find_exclude//[[:blank:]]/} | tr -s '|')

# Start check
common_bin() {
local bin_name 
local bin_version 

n=0;
for command in "${core_dependency[@]}"; do
	if hash "$command" &>/dev/null
	then
		bin_name=$(command -v $command)
		if [[ "$command" = "awk" ]]; then
			bin_version="-"
			core_dependency_version+=( "${bin_name}|${bin_version}" )
		elif [[ "$command" = "bash" ]]; then
			bin_version="${BASH_VERSION}"
			core_dependency_version+=( "${bin_name}|${bin_version}" )
		elif [[ "$command" = "bc" ]]; then
			bin_version=$(bc --version | head -1)
			core_dependency_version+=( "${bin_name}|${bin_version}" )
		elif [[ "$command" = "ffmpeg" ]]; then
			bin_version=$(ffmpeg -version | head -1 | sed 's/ Copyright.*//g')
			ffmpeg_libgme=$(ffmpeg -hide_banner -loglevel quiet -buildconf | grep "enable-libgme")
			if [[ -n "$ffmpeg_libgme" ]]; then
				core_dependency_version+=( "${bin_name}|${bin_version} with enable-libgme" )
			else
				core_dependency_version+=( "${bin_name}|${bin_version} without enable-libgme" )
				ffmpeg_fail="/!\ Not processing, ffmpeg must be compiled with --enable-libgme"
			fi
		elif [[ "$command" = "ffprobe" ]]; then
			bin_version=$(ffprobe -version | head -1 | sed 's/ Copyright.*//g')
			core_dependency_version+=( "${bin_name}|${bin_version}" )
		elif [[ "$command" = "find" ]]; then
			bin_version=$(find --version | head -1)
			core_dependency_version+=( "${bin_name}|${bin_version}" )
		elif [[ "$command" = "grep" ]]; then
			bin_version=$(grep --version | head -1)
			core_dependency_version+=( "${bin_name}|${bin_version}" )
		elif [[ "$command" = "sed" ]]; then
			bin_version=$(sed --version | head -1)
			core_dependency_version+=( "${bin_name}|${bin_version}" )
		elif [[ "$command" = "sox" ]]; then
			bin_version=$(sox --version)
			bin_version="${bin_version#sox:      }"
			core_dependency_version+=( "${bin_name}|${bin_version}" )
		elif [[ "$command" = "soxi" ]]; then
			bin_version=$(sox --version)
			bin_version="${bin_version#sox:      }"
			core_dependency_version+=( "${bin_name}|${bin_version}" )
		elif [[ "$command" = "xxd" ]]; then
			bin_version=$(xxd -v 2>&1)
			core_dependency_version+=( "${bin_name}|${bin_version}" )
		fi
		(( c++ )) || true
	else
		local command_fail+=( "$command" )
		(( n++ )) || true
	fi
done
if (( "${#command_fail[@]}" )); then
	echo "vgm2flac break, the following dependencies are not installed:"
	printf '  %s\n' "${command_fail[@]}"
	exit
fi
}
decoder_bin() {
local bin_name 
local bin_version 

for command in "${decoder_dependency[@]}"; do
	bin_name=$(command -v $command)

	if [[ -n "$bin_name" ]]; then

		if [[ "$command" = "adplay" ]]; then
			adplay_bin="$bin_name"
			bin_version=$($adplay_bin -V | head -1)
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "asapconv" ]]; then
			asapconv_bin="$bin_name"
			bin_version=$($asapconv_bin -v)
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "bchunk" ]]; then
			bchunk_bin="$bin_name"
			bin_version=$($bchunk_bin 2>&1 | grep binchunker | sed 's/by.*//g')
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "fluidsynth" ]]; then
			fluidsynth_bin="$bin_name"
			bin_version=$($fluidsynth_bin -V | head -1)
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "gsf2wav" ]]; then
			gsf2wav_bin="$bin_name"
			bin_version="-"
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "info68" ]]; then
			info68_bin="$bin_name"
			bin_version=$($info68_bin --version | head -1)
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "mednafen" ]]; then
			mednafen_bin="$bin_name"
			bin_version=$($mednafen_bin --help | head -1)
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "mt32emu-smf2wav" ]]; then
			munt_bin="$bin_name"
			bin_version=$($munt_bin 2>&1 | grep Version | head -1)
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "nsf2wav" ]]; then
			nsfplay_bin="$bin_name"
			bin_version="-"
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "sc68" ]]; then
			sc68_bin="$bin_name"
			bin_version=$($sc68_bin --version | head -1)
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "sidplayfp" ]]; then
			sidplayfp_bin="$bin_name"
			bin_version="-"
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "simple_mdx2wav" ]]; then
			mdx2wav_bin="$bin_name"
			bin_version="-"
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "vgm2wav" ]]; then
			vgm2wav_bin="$bin_name"
			bin_version="-"
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "vgm_tag" ]]; then
			vgm_tag_bin="$bin_name"
			bin_version="-"
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "vgmstream-cli" ]]; then
			vgmstream_cli_bin="$bin_name"
			bin_version=$($vgmstream_cli_bin -h | head -1)
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "uade123" ]]; then
			uade123_bin="$bin_name"
			bin_version=$($uade123_bin -h | head -1)
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "wildmidi" ]]; then
			wildmidi_bin="$bin_name"
			bin_version=$($wildmidi_bin -v | grep WildMidi | head -1 | sed 's/Op.*//g')
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "xmp" ]]; then
			xmp_bin="$bin_name"
			bin_version=$($xmp_bin -V)
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "zxtune123" ]]; then
			zxtune123_bin="$bin_name"
			bin_version=$($zxtune123_bin --version)
			decoder_dependency_version+=( "${bin_name}|${bin_version}" )

		fi

	else

		decoder_dependency_version+=( "${command}|[not installed]" )

		if [[ "$command" = "adplay" ]]; then
			adplay_fail="/!\ Not processing, $command not installed"

		elif [[ "$command" = "asapconv" ]]; then
			asapconv_fail="/!\ Not processing, $command not installed"

		elif [[ "$command" = "bchunk" ]]; then
			bchunk_fail="/!\ Not processing, $command not installed"

		elif [[ "$command" = "fluidsynth" ]]; then
			fluidsynth_fail="/!\ Not processing, $command not installed"

		elif [[ "$command" = "mednafen" ]]; then
			mednafen_fail="/!\ Not processing, $command not installed"

		elif [[ "$command" = "mt32emu-smf2wav" ]]; then
			munt_fail="/!\ Not processing, $command not installed"

		elif [[ "$command" = "nsf2wav" ]]; then
			nsfplay_fail="/!\ Not processing, $command not installed"

		elif [[ "$command" = "sidplayfp" ]]; then
			sidplayfp_fail="/!\ Not processing, $command not installed"

		elif [[ "$command" = "simple_mdx2wav" ]]; then
			mdx2wav_fail="/!\ Not processing, $command not installed"

		elif [[ "$command" = "vgmstream-cli" ]]; then
			vgmstream_fail="/!\ Not processing, $command not installed"

		elif [[ "$command" = "uade123" ]]; then
			uade123_fail="/!\ Not processing, $command not installed"

		elif [[ "$command" = "wildmidi" ]]; then
			wildmidi_fail="/!\ Not processing, $command not installed"

		elif [[ "$command" = "xmp" ]]; then
			xmp_fail="/!\ Not processing, $command not installed"

		elif [[ "$command" = "zxtune123" ]]; then
			zxtune123_fail="/!\ Not processing, $command not installed"
		fi
	fi
done

# gbs fail case
if [[ -z "$gsf2wav_bin" ]] && [[ -z "$zxtune123_bin" ]]; then
	gsf_fail="/!\ Not processing, gsf2wav or zxtune123 not installed"
fi
# midi fail case
if [[ -z "$fluidsynth_bin" ]] && [[ -z "$munt_bin" ]]; then
	midi_fail="/!\ Not processing, fluidsynth or munt not installed"
fi
# sc68 fail case
if [[ -z "$info68_bin" ]] || [[ -z "$sc68_bin" ]]; then
	sc68_fail="/!\ Not processing, info68 & sc68 not installed"
fi
# vgm2wav fail case
if [[ -z "$vgm2wav_bin" ]] || [[ -z "$vgm_tag_bin" ]]; then
	vgm2wav_fail="/!\ Not processing, vgm2wav & vgm_tag not installed"
fi
}
encoder_bin() {
local bin_name 
local bin_version 

for command in "${encoder_dependency[@]}"; do
	bin_name=$(command -v $command)

	if [[ -n "$bin_name" ]]; then

		if [[ "$command" = "flac" ]]; then
			flac_bin="$bin_name"
			bin_version=$($flac_bin --version)
			flac_version="$bin_version $default_flac_lvl"
			encoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "metaflac" ]]; then
			metaflac_bin="$bin_name"
			bin_version=$($metaflac_bin --version)
			encoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "mac" ]]; then
			mac_bin="$bin_name"
			bin_version="Monkey's Audio $($mac_bin 2>&1 | head -1 \
							| awk -F"[()]" '{print $2}' | tr -d ' ')"
			mac_version="$bin_version $default_mac_lvl"
			encoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "mutagen-inspect" ]]; then
			mutagen_inspect_bin="$bin_name"
			bin_version="-"
			encoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "opusenc" ]]; then
			opusenc_bin="$bin_name"
			bin_version=$($opusenc_bin --version | head -1)
			encoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "rsgain" ]]; then
			rsgain_bin="$bin_name"
			bin_version=$($rsgain_bin -v \
							| sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" \
							| head -1 | cut -d'-' -f-1)
			encoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "wavpack" ]]; then
			wavpack_bin="$bin_name"
			bin_version=$($wavpack_bin --version | head -1)
			wavpack_version="$bin_version $default_wavpack_lvl"
			encoder_dependency_version+=( "${bin_name}|${bin_version}" )

		elif [[ "$command" = "wvtag" ]]; then
			wvtag_bin="$bin_name"
			bin_version=$($wvtag_bin --version | head -1)
			encoder_dependency_version+=( "${bin_name}|${bin_version}" )

		fi
	fi
done
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
  --add_ape               Compress also in Monkey's Audio.
  --add_opus              Compress also in Opus.
  --add_wavpack           Compress also in WAVPACK.
  -d|--dependencies       Display dependencies status.
  -h|--help               Display this help.
  --force_fade_out        Force default fade out.
  --force_stereo          Force stereo output.
  -j|--job                Set the number of parallel jobs.
  --no_fade_out           Force no fade out.
  --no_remove_duplicate   Force no remove duplicate files.
  --normalization         Force peak db normalization.
  -o|--output <dirname>   Force output directory name.
  --only_wav              Force output wav files only.
  -s|--summary_more       Display more infos at start & end.
  --remove_silence        Remove silence at start & end of track (85db).
  --remove_silence_more   Remove silence agressive mode (58db).
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
}
display_loop_title() {
local command
local machine

command="$1"
machine="$2"

display_separator
echo_pre_space "working directory: $PWD"
echo_pre_space "$command loop - $machine"
display_separator
}
display_convert_title() {
local extract_label
local label

extract_label="$1"

if ! [[ "$only_wav" = "1" ]]; then
	# Label construction
	if [[ "$extract_label" = "FLAC" ]]; then
		if [[ -n "$opus_compress" ]] \
		&& [[ -n "$ape_compress" ]] \
		&& [[ -n "$wavpack_compress" ]]; then
			label="FLAC, APE, WAVPACK & OPUS"
		elif [[ -z "$opus_compress" ]] \
		  && [[ -n "$ape_compress" ]] \
		  && [[ -n "$wavpack_compress" ]]; then
			label="FLAC, APE & WAVPACK"
		elif [[ -z "$opus_compress" ]] \
		  && [[ -z "$ape_compress" ]] \
		  && [[ -n "$wavpack_compress" ]]; then
			label="FLAC & WAVPACK"
		elif [[ -z "$opus_compress" ]] \
		  && [[ -n "$ape_compress" ]] \
		  && [[ -z "$wavpack_compress" ]]; then
			label="FLAC & APE"
		elif [[ -n "$opus_compress" ]] \
		  && [[ -z "$ape_compress" ]] \
		  && [[ -z "$wavpack_compress" ]]; then
			label="FLAC & OPUS"
		elif [[ -z "$opus_compress" ]] \
		  && [[ -z "$ape_compress" ]] \
		  && [[ -z "$wavpack_compress" ]]; then
			label="FLAC"
		fi
		display_separator
	fi
	# Display
	if [[ "$extract_label" = "FLAC" ]]; then
		echo_pre_space "$label conversion"
	elif [[ "$extract_label" = "WAV" ]]; then
		echo_pre_space "WAV conversion"
	elif [[ "$extract_label" = "LINE" ]]; then
		echo_pre_space "Conversion"
	fi
	display_separator
fi
}
display_remove_previous_line() {
printf '\e[A\e[K'
}
display_size_mb() {
local files
local size
local size_in_mb
files=("$@")

if (( "${#files[@]}" )); then
	# Get size in bytes
	size=$(wc -c "${files[@]}" | tail -1 | awk '{print $1;}')
	# MB convert
	size_in_mb=$(bc <<< "scale=3; $size / 1024 / 1024" | sed 's!\.0*$!!')
else
	size_in_mb="0"
fi

# If string start by "." add lead 0
if [[ "${size_in_mb:0:1}" == "." ]]; then
	echo "0$size_in_mb"
else
	echo "$size_in_mb"
fi
}
display_conf_summary() {
echo_pre_space "/ vgm2flac /"

if [[ "$summary_more" = "1" ]]; then
	# Script
	if [[ -n "$force_output_dir" ]]; then
		script_conf+=( "Output directory = $force_output_dir" )
	fi
	script_conf+=( "Parallel job = $nprocessor" )
	if [[ "$no_remove_duplicate" = "1" ]]; then
		script_conf+=( "Remove duplicate = OFF" )
	else
		script_conf+=( "Remove duplicate = ON" )
	fi
	if [[ "$verbose" = "1" ]]; then
		script_conf+=( "Verbose = ON" )
	else
		script_conf+=( "Verbose = OFF" )
	fi

	# Encoder
	if [[ "$only_wav" != "1" ]]; then
		encoder_conf+=( "FLAC" )
	fi
	if [[ "$ape_compress" = "1" ]]; then
		encoder_conf+=( "APE" )
	fi
	if [[ "$wavpack_compress" = "1" ]]; then
		encoder_conf+=( "WAVPACK" )
	fi
	if [[ "$opus_compress" = "1" ]]; then
		encoder_conf+=( "OPUS" )
	fi

	# Audio processing
	if [[ "$force_fade_out" = "1" ]]; then
		audio_process_conf+=( "Force fade out = ON" )
	else
		audio_process_conf+=( "Force fade out = OFF" )
	fi
	if [[ "$force_stereo" = "1" ]]; then
		audio_process_conf+=( "Force Stereo = ON" )
	else
		audio_process_conf+=( "Force Stereo = OFF" )
	fi
	if [[ "$normalization" = "1" ]]; then
		audio_process_conf+=( "Normalization = ON" )
	else
		audio_process_conf+=( "Normalization = OFF" )
	fi
	if [[ "$remove_silence" = "1" ]]; then
		audio_process_conf+=( "Remove silence = ON" )
	else
		audio_process_conf+=( "Remove silence = OFF" )
	fi
	if [[ "$agressive_silence" = "1" ]]; then
		audio_process_conf+=( "Remove silence agressive = ON" )
	else
		audio_process_conf+=( "Remove silence agressive = OFF" )
	fi

	display_separator
	echo_pre_space "Current config"
	printf ' ~ %s\n' "${script_conf[@]}"
	echo_pre_space "~ Encoder : WAV ${encoder_conf[*]}"
	echo_pre_space "~ Audio processing :"
	printf '   - %s\n' "${audio_process_conf[@]}"

	# Reset
	unset script_conf
	unset encoder_conf
	unset audio_process_conf
fi
}
display_start_summary() {
if (( "${#lst_all_files_pass[@]}" )); then
	fetched_stat() {
		local label
		local files
		label0="$1"
		label1="$2"
		shift 2
		files=("$@")

		if (( "${#files[@]}" )); then
			if [[ "$label0" = "Uade" ]] || [[ "$label0" = "XMP" ]]; then
				echo_pre_space "${label0} files: ${#files[@]} ($(display_size_mb "${files[@]}") MB) ${label1}"
			else
				echo_pre_space "${label0}; $(echo "${files[@]##*.}" \
								| awk -v RS="[ \n]+" '!n[$0]++' \
								| awk -v RS="" '{gsub (/\n/,"|")}1') files : ${#files[@]} ($(display_size_mb "${files[@]}") MB) ${label1}"
			fi
		fi
	}

	display_separator
	echo_pre_space "${#lst_all_files_pass[@]} Fetched files ($(display_size_mb "${lst_all_files_pass[@]}") MB)"
	display_separator
	fetched_stat "Atari ST" "$sc68_fail" "${lst_sc68[@]}"
	fetched_stat "Atari XL/XE" "$asapconv_fail" "${lst_asapconv[@]}"
	fetched_stat "Amstrad CPC" "$zxtune123_fail" "${lst_zxtune_ay[@]}"
	fetched_stat "Amstrad CPC, Atari ST" "$zxtune123_fail" "${lst_zxtune_ym[@]}"
	fetched_stat "Commodore C64/128" "$sidplayfp_fail" "${lst_sidplayfp_sid[@]}"
	fetched_stat "Game Boy Advance" "$gsf_fail" "${lst_gsf[@]}"
	fetched_stat "Game Boy, Game Boy Color" "$ffmpeg_fail" "${lst_ffmpeg_gbs[@]}"
	fetched_stat "NES NSF" "$nsfplay_fail" "${lst_nsfplay_nsf[@]}"
	fetched_stat "NES NSFE" "$nsfplay_fail" "${lst_nsfplay_nsfe[@]}"
	fetched_stat "Sharp X68000" "$mdx2wav_fail" "${lst_mdx2wav[@]}"
	fetched_stat "SNES SPC" "$ffmpeg_fail" "${lst_ffmpeg_spc[@]}"
	fetched_stat "SNES SNSF" "$mednafen_fail" "${lst_mednafen_snsf[@]}"
	fetched_stat "PC AdLib" "$adplay_fail" "${lst_adplay[@]}"
	fetched_stat "PC Engine, TurboGrafx-16" "$ffmpeg_fail" "${lst_ffmpeg_hes[@]}"
	fetched_stat "PC HMI/XMI" "$wildmidi_fail" "${lst_wildmidi[@]}"
	fetched_stat "PC midi" "$midi_fail" "${lst_midi[@]}"
	fetched_stat "Uade" "$uade123_fail" "${lst_uade[@]}"
	fetched_stat "Various machines" "$vgmstream_fail" "${lst_vgmstream[@]}"
	fetched_stat "Various machines ISO" "$bchunk_fail" "${lst_bchunk_iso[@]}"
	fetched_stat "Various machines RAW" "" "${lst_sox_pass[@]}"
	fetched_stat "Various machines SF" "$zxtune123_fail" "${lst_zxtune_xsf[@]}"
	fetched_stat "Various machines VGM" "$vgm2wav_fail" "${lst_vgm2wav[@]}"
	fetched_stat "XMP" "$xmp_fail" "${lst_xmp[@]}"
	fetched_stat "ZX Spectrum" "$zxtune123_fail" "${lst_zxtune_zx_spectrum[@]}"
	fetched_stat "ZXTune Various Music" "$zxtune123_fail" "${lst_zxtune_various[@]}"

else
	display_separator
	if (( "${#lst_all_files_pass[@]}" )); then
		echo_pre_space "${#lst_all_files_pass[@]} files compatible"
	else
		echo_pre_space "No extra compatible files"
	fi

fi
}
display_end_summary() {
if (( "${#lst_all_files_pass[@]}" )); then
	local source_size_in_mb
	local wav_size_in_mb
	local flac_size_in_mb
	local wavpack_size_in_mb
	local ape_size_in_mb
	local opus_size_in_mb
	local diff_in_s
	local elapsed_time_formated
	# Get source size in mb
	if (( "${#lst_all_files_pass[@]}" )); then
		source_size_in_mb=$(display_size_mb "${lst_all_files_pass[@]}")
	fi
	# Get wav size in mb
	if (( "${#lst_wav[@]}" )); then
		wav_size_in_mb=$(display_size_mb "${lst_wav[@]}")
	fi
	# Get flac size in mb
	if [[ "$only_wav" != "1" ]] && (( "${#lst_flac[@]}" )); then
		flac_size_in_mb=$(display_size_mb "${lst_flac[@]}")
	fi
	# Get wavpack size in mb
	if [[ "$only_wav" != "1" ]] && [[ "$wavpack_compress" = "1" ]] && (( "${#lst_wavpack[@]}" )); then
		wavpack_size_in_mb=$(display_size_mb "${lst_wavpack[@]}")
	fi
	# Get ape size in mb
	if [[ "$only_wav" != "1" ]] && [[ "$ape_compress" = "1" ]] && (( "${#lst_ape[@]}" )); then
		ape_size_in_mb=$(display_size_mb "${lst_ape[@]}")
	fi
	# Get opus size in mb
	if [[ "$only_wav" != "1" ]] && [[ "$opus_compress" = "1" ]] && (( "${#lst_opus[@]}" )); then
		opus_size_in_mb=$(display_size_mb "${lst_opus[@]}")
	fi

	# Timer
	diff_in_s=$(( timer_stop - timer_start ))
	elapsed_time_formated="$((diff_in_s/3600))h$((diff_in_s%3600/60))m$((diff_in_s%60))s"

	# Print
	display_separator
	if [[ "$only_wav" != "1" ]];then
		echo_pre_space "Summary for $tag_album"
	else
		echo_pre_space "Summary"
	fi
	display_separator
	echo_pre_space "SOURCE    <- ${#lst_all_files_pass[@]} file(s) - $source_size_in_mb MB"
	echo_pre_space "WAV       <- ${#lst_wav[@]} file(s) - $wav_size_in_mb MB"
	if [[ "$only_wav" != "1" ]]; then
		echo_pre_space "FLAC      <- ${#lst_flac[@]} file(s) - $flac_size_in_mb MB"
		if [[ "$wavpack_compress" = "1" ]]; then
			echo_pre_space "WAVPACK   <- ${#lst_wavpack[@]} file(s) - $wavpack_size_in_mb MB"
		fi
		if [[ "$ape_compress" = "1" ]]; then
			echo_pre_space "APE       <- ${#lst_ape[@]} file(s) - $ape_size_in_mb MB"
		fi
		if [[ "$opus_compress" = "1" ]]; then
			echo_pre_space "OPUS      <- ${#lst_opus[@]} file(s) - $opus_size_in_mb MB"
		fi
	fi
	if [[ "$force_stereo" != "1" ]]; then
		echo_pre_space "Mono      <- ${#lst_wav_in_mono[@]} file(s)"
		if [[ "$summary_more" = "1" ]] \
		&& (( "${#lst_wav_in_mono[@]}" )); then
			printf '   %s\n' "${lst_wav_in_mono[@]}" | column -s $'|' -t -o '  ->  '
		fi
	fi
	if [[ "$normalization" = "1" ]]; then
		echo_pre_space "Normalized to -${default_peakdb_norm}dB - ${#lst_wav_normalized[@]} file(s)"
		if [[ "$summary_more" = "1" ]] \
		&& (( "${#lst_wav_normalized[@]}" )); then
			printf '   %s\n' "${lst_wav_normalized[@]}" | column -s $'|' -t -o '  ->  '
		fi
	fi
	if [[ "$normalization" != "1" ]] \
	&& [[ -n "$rsgain_bin" || -n "$metaflac_bin" ]] \
	&& [[ -n "$mutagen_inspect_bin" ]] \
	&& (( "${#lst_replaygain[@]}" )) \
	&& [[ "$summary_more" = "1" ]]; then
		echo_pre_space "ReplayGain applied:"
		printf '   %s\n' "${lst_replaygain[@]}" | column -s $'|' -t -o '  ->  '
	fi
	echo_pre_space "Encoding duration  - $elapsed_time_formated"
fi
}
display_dependencies() {
echo "vgm2flac dependencies status"
display_separator
echo_pre_space "Core:"
printf '  %s\n' "${core_dependency_version[@]}" | column -s $'|' -t
display_separator
echo_pre_space "Decoder:"
printf '  %s\n' "${decoder_dependency_version[@]}" | column -s $'|' -t
display_separator
echo_pre_space "Optional Encoder:"
printf '  %s\n' "${encoder_dependency_version[@]}" | column -s $'|' -t
display_separator
}
progress_bar() {
# Local variables
local TotalFilesNB
local CurrentFilesNB
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
if [[ ! -d "$vgm2flac_cache" ]]; then
	mkdir "$vgm2flac_cache"
fi
}
clean_cache_directory() {
find "$vgm2flac_cache/" -type f -mtime +3 -exec /bin/rm -f {} \;			# if file exist in cache directory after 3 days, delete it
rm "$vgm2flac_cache_tag" &>/dev/null
}

# Files array
list_source_files() {
# Local variables
local vgmstream_test_result
local uade_test_result
local xmp_test_result
local zxtune_test_result
local progress_counter
local sox_delta

mapfile -t lst_all_files < <(find "$PWD" -maxdepth 1 -type f 2>/dev/null | grep -E -i -v '.*\.('$ext_find_exclude')$' | sort -V)
mapfile -t lst_adplay < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_adplay')$' 2>/dev/null | sort -V)
mapfile -t lst_asapconv < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_asapconv')$' 2>/dev/null | sort -V)
mapfile -t lst_bchunk_cue < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_bchunk_cue')$' 2>/dev/null | sort -V)
mapfile -t lst_bchunk_iso < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_bchunk_iso')$' 2>/dev/null | sort -V)
mapfile -t lst_ffmpeg_gbs < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_ffmpeg_gbs')$' 2>/dev/null | sort -V)
mapfile -t lst_ffmpeg_hes < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_ffmpeg_hes')$' 2>/dev/null | sort -V)
mapfile -t lst_ffmpeg_spc < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_ffmpeg_spc')$' 2>/dev/null | sort -V)
mapfile -t lst_gsf < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_gsf')$' 2>/dev/null | sort -V)
mapfile -t lst_mdx2wav < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_mdx2wav')$' 2>/dev/null | sort -V)
mapfile -t lst_mednafen_snsf < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_mednafen_snsf')$' 2>/dev/null | sort -V)
mapfile -t lst_midi < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_midi')$' 2>/dev/null | sort -V)
mapfile -t lst_m3u < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_playlist')$' 2>/dev/null | sort -V)
mapfile -t lst_nsfplay_nsf < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_nsfplay_nsf')$' 2>/dev/null | sort -V)
mapfile -t lst_nsfplay_nsfe < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_nsfplay_nsfe')$' 2>/dev/null | sort -V)
mapfile -t lst_sc68 < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_sc68')$' 2>/dev/null | sort -V)
mapfile -t lst_sidplayfp_sid < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_sidplayfp_sid')$' 2>/dev/null | sort -V)
mapfile -t lst_sox < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_sox')$' 2>/dev/null | sort -V)
mapfile -t lst_vgm2wav < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_vgm2wav')$' 2>/dev/null | sort -V)
mapfile -t lst_wildmidi < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_wildmidi')$' 2>/dev/null | sort -V)
mapfile -t lst_zxtune_ay < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_zxtune_ay')$' 2>/dev/null | sort -V)
mapfile -t lst_zxtune_xsf < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_zxtune_xsf')$' 2>/dev/null | sort -V)
mapfile -t lst_zxtune_ym < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_zxtune_ym')$' 2>/dev/null | sort -V)
mapfile -t lst_zxtune_zx_spectrum < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('$ext_zxtune_zx_spectrum')$' 2>/dev/null | sort -V)

# bin/cue clean
# If bin/iso + cue = 1 + 1 - bchunk use
if [[ "${#lst_bchunk_iso[@]}" = "1" && "${#lst_bchunk_cue[@]}" = "1" ]]; then
	unset lst_sox
	bchunk="1"
# If bin > 1 or cue > 1 - sox use
elif [[ "${#lst_bchunk_iso[@]}" -gt "1" || "${#lst_bchunk_cue[@]}" -gt "1" ]] \
  || [[ "${#lst_bchunk_iso[@]}" -ge "1" || "${#lst_bchunk_cue[@]}" -eq "0" ]]; then
	unset lst_bchunk_cue
	unset lst_bchunk_iso
fi

# Combine pass array for test
lst_all_files_pass+=( "${lst_adplay[@]}" \
				"${lst_asapconv[@]}" \
				"${lst_bchunk_iso[@]}" \
				"${lst_ffmpeg_gbs[@]}" \
				"${lst_ffmpeg_hes[@]}" \
				"${lst_ffmpeg_spc[@]}" \
				"${lst_gsf[@]}" \
				"${lst_mdx2wav[@]}" \
				"${lst_midi[@]}" \
				"${lst_mednafen_snsf[@]}" \
				"${lst_nsfplay_nsf[@]}" \
				"${lst_nsfplay_nsfe[@]}" \
				"${lst_sc68[@]}" \
				"${lst_sidplayfp_sid[@]}" \
				"${lst_sox[@]}" \
				"${lst_uade[@]}" \
				"${lst_vgm2wav[@]}" \
				"${lst_vgmstream[@]}" \
				"${lst_wildmidi[@]}" \
				"${lst_xmp[@]}" \
				"${lst_zxtune_ay[@]}" \
				"${lst_zxtune_xsf[@]}" \
				"${lst_zxtune_ym[@]}" \
				"${lst_zxtune_various[@]}" \
				"${lst_zxtune_zx_spectrum[@]}" )
# Detect file not in lst_all_files_pass array
for files in "${lst_all_files[@]}"; do
	if [[ ! " ${lst_all_files_pass[*]} " =~ " ${files} " ]]; then
		files_2_test+=("$files")
	fi
done

# Test files
if (( "${#files_2_test[@]}" )); then

	if (( "${#uade123_bin}" )) || (( "${#vgmstream_cli_bin}" )) \
	|| (( "${#xmp_bin}" )) || (( "${#zxtune123_bin}" )); then

		display_separator
		echo_pre_space "Files test:"
		for files in "${files_2_test[@]}"; do

			# Test file
			if (( "${#uade123_bin}" )); then
				uade_test_result=$("$uade123_bin" -g "$files" 2>/dev/null)
					if [[ "${#uade_test_result}" -gt "0" ]]; then
						lst_uade+=("$files")
					fi
			fi

			if (( "${#xmp_bin}" )) \
			&& [[ "${#uade_test_result}" -eq "0" ]]; then
				xmp_test_result=$("$xmp_bin" --load-only -q "$files" 2>&1)
					if [[ "${#xmp_test_result}" -eq "0" ]]; then
						lst_xmp+=("$files")
					fi
			fi

			if (( "${#vgmstream_cli_bin}" )) \
			&& [[ "${#uade_test_result}" -eq "0" ]] \
			&& [[ "${#xmp_test_result}" -gt "0" ]]; then
				vgmstream_test_result=$("$vgmstream_cli_bin" -m "$files" 2>/dev/null)
					if [[ "${#vgmstream_test_result}" -gt "0" ]]; then
						lst_vgmstream+=("$files")
					fi
			fi

			if (( "${#zxtune123_bin}" )) \
			&& [[ "${#uade_test_result}" -eq "0" ]] \
			&& [[ "${#vgmstream_test_result}" -eq "0" ]] \
			&& [[ "${#xmp_test_result}" -gt "0" ]]; then
				zxtune_test_result=$("$zxtune123_bin" "$files" --null 2>&1)
					if [[ "${#zxtune_test_result}" -gt "0" ]]; then
						lst_zxtune_various+=("$files")
					fi
			fi

			# Progress bar
			if [[ "$verbose" != "1" ]]; then
				progress_counter=$(( progress_counter + 1 ))
				progress_bar "$progress_counter" "${#files_2_test[@]}"
			fi

			# Reset
			unset ext_test_result_off
		done
	fi

fi

# Sox validation
if (( "${#lst_sox[@]}" )); then
	display_separator
	echo_pre_space "Sox files test:"

	unset progress_counter
	for files in "${lst_sox[@]}"; do
		# Test if data by measuring maximum difference between two successive samples
		sox_delta=$(sox -t raw -r 44100 -b 16 -c 2 -L -e signed-integer "$files" -n stat 2>&1 \
					| grep "Maximum delta:" \
					| awk '{print $3}')
		# If Maximum delta < 1.97 - raw -> wav
		if (( $(echo "$sox_delta 1.97" | awk '{print ($1 < $2)}') )); then
			lst_sox_pass+=("$files")
		fi

		# Progress bar
		if [[ "$verbose" != "1" ]]; then
			progress_counter=$(( progress_counter + 1 ))
			progress_bar "$progress_counter" "${#lst_sox[@]}"
		fi

	done
	wait
fi

# Conctruct new all pass array if detection add new files
# Reset pass array
unset lst_all_files_pass
# Combine pass array
lst_all_files_pass+=( "${lst_adplay[@]}" \
				"${lst_asapconv[@]}" \
				"${lst_bchunk_iso[@]}" \
				"${lst_ffmpeg_gbs[@]}" \
				"${lst_ffmpeg_hes[@]}" \
				"${lst_ffmpeg_spc[@]}" \
				"${lst_gsf[@]}" \
				"${lst_mdx2wav[@]}" \
				"${lst_midi[@]}" \
				"${lst_mednafen_snsf[@]}" \
				"${lst_nsfplay_nsf[@]}" \
				"${lst_nsfplay_nsfe[@]}" \
				"${lst_sc68[@]}" \
				"${lst_sidplayfp_sid[@]}" \
				"${lst_sox_pass[@]}" \
				"${lst_uade[@]}" \
				"${lst_vgm2wav[@]}" \
				"${lst_vgmstream[@]}" \
				"${lst_wildmidi[@]}" \
				"${lst_xmp[@]}" \
				"${lst_zxtune_ay[@]}" \
				"${lst_zxtune_xsf[@]}" \
				"${lst_zxtune_ym[@]}" \
				"${lst_zxtune_various[@]}" \
				"${lst_zxtune_zx_spectrum[@]}" )
}
list_wav_files() {
mapfile -t lst_wav < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('wav')$' 2>/dev/null | sort -V)
}
list_flac_files() {
mapfile -t lst_flac < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('flac')$' 2>/dev/null | sort -V)
}
list_wavpack_files() {
mapfile -t lst_wavpack < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('wv')$' 2>/dev/null | sort -V)
}
list_ape_files() {
mapfile -t lst_ape < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('ape')$' 2>/dev/null | sort -V)
}
list_opus_files() {
mapfile -t lst_opus < <(find "$PWD" -maxdepth 1 -type f -regextype posix-egrep -iregex '.*\.('opus')$' 2>/dev/null | sort -V)
}

# Files cleaning
clean_target_validation() {
# Regenerate array
list_wav_files

# WAV test
# Consider if wav not valid compressed file also
if (( "${#lst_wav[@]}" )); then
	# Local variable
	local wav_error_test
	local wav_empty_test

	for files in "${lst_wav[@]}"; do
		wav_error_test=$(soxi "$files" 2>/dev/null)
		wav_empty_test=$(sox "$files" -n stat 2>&1 | grep "Maximum amplitude:" | awk '{print $3}')
		if [ -z "$wav_error_test" ] || [[ "$wav_empty_test" = "0.000000" ]]; then
			lst_wav_in_error+=( "${files##*/}" )
			rm "${files%.*}".wav &>/dev/null
			if [[ "$flac_loop_activated" = "1" ]]; then
				rm "${files%.*}".flac &>/dev/null
			fi
			if [[ "$wavpack_compress" = "1" ]]; then
				rm "${files%.*}".wv &>/dev/null
			fi
			if [[ "$ape_compress" = "1" ]]; then
				rm "${files%.*}".ape &>/dev/null
			fi
			if [[ "$opus_compress" = "1" ]]; then
				rm "${files%.*}".opus &>/dev/null
			fi
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
						if [[ "$flac_loop_activated" = "1" ]]; then
							rm "${file2%.*}".flac &>/dev/null
						fi
						if [[ "$wavpack_compress" = "1" ]]; then
							rm "${file2%.*}".wv &>/dev/null
						fi
						if [[ "$ape_compress" = "1" ]]; then
							rm "${file2%.*}".ape &>/dev/null
						fi
						if [[ "$opus_compress" = "1" ]]; then
							rm "${file2%.*}".opus &>/dev/null
						fi
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
	list_wavpack_files
	list_ape_files
	list_opus_files
fi
}

# Audio treatment
wav_remove_silent() {
if [[ -f "${files%.*}".wav ]]; then
	if [[ "$remove_silence" = "1" ]]; then

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
		test_duration=$(ffprobe -i "${files%.*}".wav \
						-show_format -v quiet | grep duration \
						| sed 's/.*=//' | cut -f1 -d".")
		if ! [[ "$test_duration" = "N/A" ]]; then			 # If not a bad file
			if [[ "$test_duration" -gt 10 ]]; then
				# Remove silence at start & end
				if [[ "$verbose" = "1" ]]; then
					sox -V3 "${files%.*}".wav temp-out.wav \
						silence 1 0.2 -"$silent_db_cut"d \
						reverse \
						silence 1 0.2 -"$silent_db_cut"d \
						reverse
					rm "${files%.*}".wav &>/dev/null
					mv temp-out.wav "${files%.*}".wav
				else
					sox "${files%.*}".wav temp-out.wav \
						silence 1 0.2 -"$silent_db_cut"d \
						reverse \
						silence 1 0.2 -"$silent_db_cut"d \
						reverse
					rm "${files%.*}".wav &>/dev/null
					mv temp-out.wav "${files%.*}".wav &>/dev/null
				fi
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
		local sox_fade_out

		# Out fade, if audio during more than 10s
		test_duration=$(ffprobe -i "${files%.*}".wav \
						-show_format -v quiet | grep duration \
						| sed 's/.*=//' | cut -f1 -d".")

		# If file have duration
		if ! [[ "$test_duration" = "N/A" ]]; then

			# If file have more than 10s
			if [[ "$test_duration" -gt 10 ]]; then
				duration=$(soxi -d "${files%.*}".wav)
				sox_fade_in="0:0.0"
				if [[ -z "$imported_sox_fade_out" ]]; then
					sox_fade_out="0:$default_wav_fade_out"
				else
					sox_fade_out="0:$imported_sox_fade_out"
				fi

				# Apply fade out
				if [[ "$verbose" = "1" ]]; then
					sox -V3 "${files%.*}".wav temp-out.wav \
						fade t "$sox_fade_in" "$duration" "$sox_fade_out"
				else
					sox "${files%.*}".wav temp-out.wav \
						fade t "$sox_fade_in" "$duration" "$sox_fade_out" &>/dev/null
				fi

				# Clean
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
	local testdb_diff
	local db
	local channel_nb
	local left_md5
	local right_md5
	local testdb_stereo
	local afilter

	# Test of channel number
	channel_nb=$(ffprobe -show_entries stream=channels -of compact=p=0:nk=1 -v 0 "${files%.*}".wav)

	# If force stereo
	if [[ "$force_stereo" = "1" ]] \
	&& [[ "$channel_nb" != "2" ]]; then

		# Encoding Wav
		ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav \
			-channel_layout stereo \
			-acodec "$default_wav_bit_depth" \
			-f wav temp-out.wav
		rm "${files%.*}".wav &>/dev/null
		mv temp-out.wav "${files%.*}".wav &>/dev/null

	# If stereo = test false mono
	elif [[ "$channel_nb" = "2" ]]; then

		# md5 test
		left_md5=$(ffmpeg -i "${files%.*}".wav \
					-map_channel 0.0.0 -f md5 - 2>&1 \
					| grep "MD5=")
		right_md5=$(ffmpeg -i "${files%.*}".wav \
					-map_channel 0.0.1 -f md5 - 2>&1 \
					| grep "MD5=")

		# Get db difference between channel
		if [[ "$left_md5" != "$right_md5" ]]; then
			testdb_stereo=$(ffmpeg -i "${files%.*}".wav \
							-filter:a "pan=1c|c0=c0-c1,astats=measure_perchannel=none:measure_overall=RMS_level" \
							-f null /dev/null 2>&1 \
							| grep "RMS level dB" | awk '{print $NF;}')
			testdb_stereo="${testdb_stereo%.*}"
			testdb_stereo="${testdb_stereo#-}"
		fi

		# If left_md5=right_md5
		# If difference between channel is lower than -85db = noise db diff
		if [[ "$testdb_stereo" -gt "85" ]] \
		|| [[ "$testdb_stereo" = "inf" ]] \
		|| [[ "$left_md5" = "$right_md5" ]]; then
			# Encoding Wav
			ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav \
				-channel_layout mono \
				-acodec "$default_wav_bit_depth" \
				-f wav temp-out.wav
			rm "${files%.*}".wav &>/dev/null
			mv temp-out.wav "${files%.*}".wav &>/dev/null

			# Record for summary
			if [[ "$left_md5" = "$right_md5" ]]; then
				lst_wav_in_mono+=( "True false stereo|$(basename "${files%.*}").wav" )
			else
				lst_wav_in_mono+=( "Decibel false stereo|$(basename "${files%.*}").wav" )
			fi
		fi

	fi

	# Volume normalization
	if [[ "$normalization" = "1" ]]; then

		testdb=$(ffmpeg -i "${files%.*}".wav \
				-af "volumedetect" -vn -sn -dn -f null /dev/null 2>&1 \
				| grep "max_volume" | awk '{print $5;}')
		testdb_diff=$(echo "${testdb/-/} > $default_peakdb_norm" \
					| bc -l 2>/dev/null)

		# Apply if db detected < default peak db variable
		if [[ "${testdb:0:1}" == "-" ]] && [[ "$testdb_diff" = "1" ]]; then
			db="$(echo "${testdb/-/}" \
				| awk -v var="$default_peakdb_norm" '{print $1-var}')dB"
			afilter="-af volume=$db"

			# Encoding Wav
			ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav \
				$afilter \
				-acodec "$default_wav_bit_depth" \
				-f wav temp-out.wav
			rm "${files%.*}".wav &>/dev/null
			mv temp-out.wav "${files%.*}".wav &>/dev/null

			# Record for summary
			lst_wav_normalized+=( "+${db}|$(basename "${files%.*}").wav" )
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
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_asapconv() {
if [[ "$verbose" = "1" ]]; then
	"$asapconv_bin" -o "%s - $file_name" "$files"
else
	"$asapconv_bin" -o "%s - $file_name" "$files" &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_bchunk() {
if [[ "$verbose" = "1" ]]; then
	"$bchunk_bin" -v -w "${lst_bchunk_iso[0]}" "${lst_bchunk_cue[0]}" "$track_name"-Track-
else
	"$bchunk_bin" -w "${lst_bchunk_iso[0]}" "${lst_bchunk_cue[0]}" "$track_name"-Track- &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${lst_bchunk_iso##*/}" \
		|| echo_pre_space "x WAV     <- ${lst_bchunk_iso##*/}"
fi
}
cmd_ffmpeg_gbs() {
if [[ "$verbose" = "1" ]]; then
	ffmpeg $ffmpeg_log_lvl -track_index "$sub_track" -y -i "$gbs" \
		-t $xxs_duration_second \
		-channel_layout mono \
		-acodec "$default_wav_bit_depth" \
		-ar 44100 \
		-f wav "$sub_track - $tag_song".wav
else
	ffmpeg $ffmpeg_log_lvl -track_index "$sub_track" -y -i "$gbs" \
		-t $xxs_duration_second \
		-channel_layout mono \
		-acodec "$default_wav_bit_depth" \
		-ar 44100 \
		-f wav "$sub_track - $tag_song".wav \
		&& echo_pre_space "✓ WAV     <- $sub_track - $tag_song" \
		|| echo_pre_space "x WAV     <- $sub_track - $tag_song"
fi
}
cmd_ffmpeg_hes() {
if [[ "$verbose" = "1" ]]; then
	ffmpeg $ffmpeg_log_lvl -track_index "$sub_track" -y -i "$hes" \
		-t $xxs_duration_second \
		-acodec "$default_wav_bit_depth" \
		-map_metadata -1 \
		-f wav "$sub_track - $tag_song".wav
else
	ffmpeg $ffmpeg_log_lvl -track_index "$sub_track" -y -i "$hes" \
		-t $xxs_duration_second \
		-acodec "$default_wav_bit_depth" \
		-map_metadata -1 \
		-f wav "$sub_track - $tag_song".wav \
		&& echo_pre_space "✓ WAV     <- $sub_track - $tag_song" \
		|| echo_pre_space "x WAV     <- $sub_track - $tag_song"
fi
}
cmd_ffmpeg_spc() {
if [[ "$verbose" = "1" ]]; then
	ffmpeg $ffmpeg_log_lvl -y -i "$files" \
		-t $spc_duration_total \
		-acodec "$default_wav_bit_depth" \
		-ar 32000 \
		-fflags +bitexact -flags:v +bitexact -flags:a +bitexact \
		-f wav "${files%.*}".wav
else
	ffmpeg $ffmpeg_log_lvl -fflags +bitexact -flags:v +bitexact -flags:a +bitexact -y -i "$files" \
		-t $spc_duration_total \
		-acodec "$default_wav_bit_depth" \
		-ar 32000 \
		-f wav "${files%.*}".wav \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_fluidsynth_loop1() {
if [[ "$verbose" = "1" ]]; then
	"$fluidsynth_bin" -v -F "${files%.*}".wav "$fluidsynth_soundfont" "$files"
else
	"$fluidsynth_bin" -F "${files%.*}".wav "$fluidsynth_soundfont" "$files" &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_fluidsynth_loop2() {
if [[ "$verbose" = "1" ]]; then
	"$fluidsynth_bin" -v -F "${files%.*}".wav "$fluidsynth_soundfont" "$files" "$files"
else
	"$fluidsynth_bin" -F "${files%.*}".wav "$fluidsynth_soundfont" "$files" &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_gsf2wav() {
if [[ "$verbose" = "1" ]]; then
	"$gsf2wav_bin" "$files" "${files%.*}".wav
else
	"$gsf2wav_bin" "$files" "${files%.*}".wav &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_mdx2wav() {
if [[ "$verbose" = "1" ]]; then
	"$mdx2wav_bin" -i "$files" -o "${files%.*}".wav
else
	"$mdx2wav_bin" -i "$files" -o "${files%.*}".wav &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_mednafen_snsf() {
# Keep 48kHz for prevent audio glitch
if [[ "$verbose" = "1" ]]; then
	timeout "$snsf_duration" \
		"$mednafen_bin" \
		-sound 1 \
		-sound.device sexyal-literal-default \
		-sound.volume 100 \
		-sound.rate 48000 \
		-soundrecord "${files%.*}".wav \
		"$files"
else
	timeout "$snsf_duration" \
		"$mednafen_bin" \
		-sound 1 \
		-sound.device sexyal-literal-default \
		-sound.volume 100 \
		-sound.rate 48000 \
		-soundrecord "${files%.*}".wav \
		"$files" &>/dev/null \
		|| echo_pre_space "✓ WAV     <- ${files##*/}"
fi
}
cmd_munt() {
if [[ "$verbose" = "1" ]]; then
	"$munt_bin" -m "$munt_rom_path" \
		--renderer-type=0 \
		--output-sample-format=0 -p 44100 \
		--src-quality=3 \
		--analog-output-mode=2 -f \
		--record-max-end-silence=1000 \
		-o "${files%.*}".wav "$files"
else
	"$munt_bin" -m "$munt_rom_path" \
		--renderer-type=0 \
		--output-sample-format=0 -p 44100 \
		--src-quality=3 \
		--analog-output-mode=2 -f \
		--record-max-end-silence=1000 \
		-o "${files%.*}".wav "$files" &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_nsfplay_nsf() {
if [[ "$verbose" = "1" ]]; then
	"$nsfplay_bin" --fade_ms="$xxs_fading_msecond" \
		--length_ms="$xxs_duration_msecond" --samplerate=44100 \
		--track="$sub_track" "$nsf" "$sub_track".wav \
		&& mv "$sub_track".wav "$sub_track - $tag_song".wav
else
	"$nsfplay_bin" --fade_ms="$xxs_fading_msecond" --samplerate=44100 \
		--length_ms="$xxs_duration_msecond" --quiet \
		--track="$sub_track" "$nsf" "$sub_track".wav &>/dev/null \
		&& mv "$sub_track".wav "$sub_track - $tag_song".wav \
		&& echo_pre_space "✓ WAV     <- $sub_track - $tag_song" \
		|| echo_pre_space "x WAV     <- $sub_track - $tag_song"
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
		&& echo_pre_space "✓ WAV     <- $sub_track - $tag_song" \
		|| echo_pre_space "x WAV     <- $sub_track - $tag_song"
fi
}
cmd_sc68() {
if [[ "$verbose" = "1" ]]; then
	"$sc68_bin" -v -l "$sc68_loops" -t "$sub_track" "$sc68_files" --stdout \
		| sox -t raw -r 44100 -b 16 -c 2 -L -e signed-integer - "$final_file_name".wav
else
	"$sc68_bin" -qqq -l "$sc68_loops" -t "$sub_track" "$sc68_files" --stdout \
		| sox -t raw -r 44100 -b 16 -c 2 -L -e signed-integer - "$final_file_name".wav \
		&& echo_pre_space "✓ WAV     <- $final_file_name" \
		|| echo_pre_space "x WAV     <- $final_file_name"
fi
}
cmd_sidplayfp() {
if [[ "$verbose" = "1" ]]; then
	"$sidplayfp_bin" -v --digiboost -s -w "$files"
else
	"$sidplayfp_bin" -q --digiboost -s -w "$files" &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_sidplayfp_duration() {
if [[ "$verbose" = "1" ]]; then
	"$sidplayfp_bin" "$files" -v --digiboost -s -w -t"$sid_default_max_duration"
else
	"$sidplayfp_bin" "$files" -q --digiboost -s -w -t"$sid_default_max_duration" &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_sox() {
# Silence = ignoring noise bursts
if [[ "$verbose" = "1" ]]; then
	sox -V3  -t raw -r "$sox_sample_rate" -b 16 -c "$sox_channel" \
		-L -e signed-integer "$files" "${files%.*}".wav repeat "$sox_loop"
else
	sox -t raw -r "$sox_sample_rate" -b 16 -c "$sox_channel" \
		-L -e signed-integer "$files" "${files%.*}".wav repeat "$sox_loop" &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_uade() {
if [[ "$verbose" = "1" ]]; then
	"$uade123_bin" --filter=A1200 --force-led=0 --one \
		--silence-timeout 5 --panning 0.6 --subsong "$sub_track" "$uade_files" \
		-f "$file_name".wav
else
	"$uade123_bin" --filter=A1200 --force-led=0 --one \
		--silence-timeout 5 --panning 0.6 --subsong "$sub_track" "$uade_files" \
		-f "$file_name".wav &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${uade_files##*/}" \
		|| echo_pre_space "x WAV     <- ${uade_files##*/}"
fi
}
cmd_vgm2wav() {
if [[ "$verbose" = "1" ]]; then
	"$vgm2wav_bin" --samplerate "$vgm2wav_samplerate" --bps "$vgm2wav_bit_depth" \
		--loops "$vgm2wav_loops" "$files" "${files%.*}".wav
else
	"$vgm2wav_bin" --samplerate "$vgm2wav_samplerate" --bps "$vgm2wav_bit_depth" \
		--loops "$vgm2wav_loops" "$files" "${files%.*}".wav &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_vgmstream() {
if [[ "$verbose" = "1" ]]; then
	"$vgmstream_cli_bin" -l "$vgmstream_loops" -o "${files%.*}".wav "$files"
else
	"$vgmstream_cli_bin" -l "$vgmstream_loops" -o "${files%.*}".wav "$files" &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_vgmstream_multi_track() {
if [[ "$verbose" = "1" ]]; then
	"$vgmstream_cli_bin" -l "$vgmstream_loops" -s "$sub_track" \
		-o "${files%.*}"-"$sub_track".wav "$files"
else
	"$vgmstream_cli_bin" -l "$vgmstream_loops" -s "$sub_track" \
		-o "${files%.*}"-"$sub_track".wav "$files" &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files%.*}-$sub_track" \
		|| echo_pre_space "x WAV     <- ${files%.*}-$sub_track"
fi
}
cmd_wildmidi() {
if [[ "$verbose" = "1" ]]; then
	"$wildmidi_bin" -b -s "$files" -o "${files%.*}".wav
else
	"$wildmidi_bin" -b -s "$files" -o "${files%.*}".wav &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_xmp() {
if [[ "$verbose" = "1" ]]; then
	"$xmp_bin" "$files" -o "${files%.*}".wav
else
	"$xmp_bin" "$files" -o "${files%.*}".wav -q &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
cmd_zxtune_ay() {
if [[ "$verbose" = "1" ]]; then
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$ay" \
		&& mv output-"$file_name_random".wav "$tag_song".wav
else
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$ay" &>/dev/null \
		&& mv output-"$file_name_random".wav "$tag_song".wav &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${ay##*/}" \
		|| echo_pre_space "x WAV     <- ${ay##*/}"
fi
}
cmd_zxtune_ay_multi_track() {
if [[ "$verbose" = "1" ]]; then
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$ay"?#"$sub_track" \
		&& mv output-"$file_name_random".wav "$sub_track".wav
else
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$ay"?#"$sub_track" &>/dev/null \
		&& mv output-"$file_name_random".wav "$sub_track".wav \
		&& echo_pre_space "✓ WAV     <- $sub_track - ${ay##*/}" \
		|| echo_pre_space "x WAV     <- $sub_track - ${ay##*/}"
fi
}
cmd_zxtune_various() {
if [[ "$verbose" = "1" ]]; then
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$files" \
		|| mv output-"$file_name_random".wav "$file_name".wav &>/dev/null \
		&& mv output-"$file_name_random".wav "$file_name".wav
else
	"$zxtune123_bin" --wav filename=output-"$file_name_random".wav "$files" &>/dev/null \
		&& mv output-"$file_name_random".wav "$file_name".wav &>/dev/null \
		|| mv output-"$file_name_random".wav "$file_name".wav &>/dev/null \
		&& echo_pre_space "✓ WAV     <- ${files##*/}" \
		|| echo_pre_space "x WAV     <- ${files##*/}"
fi
}
wav2flac() {
if ! [[ "$only_wav" = "1" ]]; then
	# Encoding final flac
	if [[ "$verbose" = "1" ]]; then
			# Use official FLAC if available
			if [[ -n "$flac_bin" ]]; then
				"$flac_bin" -f --no-keep-foreign-metadata \
					$default_flac_lvl "${files%.*}".wav \
					--tag=TITLE="$tag_song" \
					--tag=ARTIST="$tag_artist" \
					--tag=ALBUM="$tag_album" \
					--tag=DATE="$tag_date_formated"
			# Or ffmpeg
			elif [[ -z "$flac_bin" ]]; then
				ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav \
					-acodec flac -compression_level "$default_ffmpeg_flac_lvl" \
					-sample_fmt "$default_ffmpeg_flac_bit_depth" \
					-metadata title="$tag_song" \
					-metadata album="$tag_album" \
					-metadata artist="$tag_artist" \
					-metadata date="$tag_date_formated" \
					"${files%.*}".flac
			fi
	else
			# Use official FLAC if available
			if [[ -n "$flac_bin" ]]; then
				"$flac_bin" --totally-silent --no-keep-foreign-metadata -f \
					$default_flac_lvl "${files%.*}".wav \
					--tag=TITLE="$tag_song" \
					--tag=ARTIST="$tag_artist" \
					--tag=ALBUM="$tag_album" \
					--tag=DATE="$tag_date_formated" \
					&& echo_pre_space "✓ FLAC    <- $(basename "${files%.*}").wav" \
					|| echo_pre_space "x FLAC    <- $(basename "${files%.*}").wav"
			# Or ffmpeg
			elif [[ -z "$flac_bin" ]]; then
				ffmpeg $ffmpeg_log_lvl -y -i "${files%.*}".wav \
					-acodec flac -compression_level "$default_ffmpeg_flac_lvl" \
					-sample_fmt "$default_ffmpeg_flac_bit_depth" \
					-metadata title="$tag_song" \
					-metadata album="$tag_album" \
					-metadata artist="$tag_artist" \
					-metadata date="$tag_date_formated" \
					"${files%.*}".flac \
					&& echo_pre_space "✓ FLAC    <- $(basename "${files%.*}").wav" \
					|| echo_pre_space "x FLAC    <- $(basename "${files%.*}").wav"
			fi
	fi

	# Proper tag artists list
	if [[ -n "$metaflac_bin" ]] \
	&& [[ "${tag_artist}" = *","* ]]; then
		unset tag_artists_list
		mapfile -t tag_artists_list < <( echo "${tag_artist}" | tr "," "\n" | awk '{$1=$1};1' )
		metaflac "${files%.*}.flac" --remove-tag=ARTIST
		for i in "${!tag_artists_list[@]}"; do
			metaflac "${files%.*}.flac" --set-tag=ARTIST="${tag_artists_list[i]}"
		done
	fi
fi
}
wav2wavpack() {
if [[ "$only_wav" != "1" ]] \
&& [[ -n "$wavpack_bin" ]] \
&& [[ "$wavpack_compress" = "1" ]]; then
	# Encoding final WAVPACK
	if [[ "$verbose" = "1" ]]; then
		"$wavpack_bin" -y "$default_wavpack_lvl" \
			-w Title="$tag_song" \
			-w Artist="$tag_artist" \
			-w Album="$tag_album" \
			-w Year="$tag_date_formated" \
			"${files%.*}".wav
	else
		"$wavpack_bin" -y -q "$default_wavpack_lvl" \
			-w Title="$tag_song" \
			-w Artist="$tag_artist" \
			-w Album="$tag_album" \
			-w Year="$tag_date_formated" \
			"${files%.*}".wav \
			&& echo_pre_space "✓ WAVPACK <- $(basename "${files%.*}").wav" \
			|| echo_pre_space "x WAVPACK <- $(basename "${files%.*}").wav"
	fi
fi
}
wav2ape() {
if [[ "$only_wav" != "1" ]] \
&& [[ -n "$mac_bin" ]] \
&& [[ "$ape_compress" = "1" ]]; then
	# Encoding final Monkey's Audio
	if [[ "$verbose" = "1" ]]; then
		"$mac_bin" "${files%.*}".wav "${files%.*}".ape \
			"$default_mac_lvl" \
			-t "Artist=${tag_artist}|Album=${tag_album}|Title=${tag_song}|Year=${tag_date_formated}"
	else
		"$mac_bin" "${files%.*}".wav "${files%.*}".ape \
			"$default_mac_lvl" \
			-t "Artist=${tag_artist}|Album=${tag_album}|Title=${tag_song}|Year=${tag_date_formated}" &>/dev/null \
			&& echo_pre_space "✓ APE     <- $(basename "${files%.*}").wav" \
			|| echo_pre_space "x APE     <- $(basename "${files%.*}").wav"
	fi
fi
}
wav2opus() {
if [[ "$only_wav" != "1" ]] \
&& [[ -n "$opusenc_bin" ]] \
&& [[ "$opus_compress" = "1" ]]; then
	# Encoding final Opus
	if [[ "$verbose" = "1" ]]; then
		"$opusenc_bin" \
		--bitrate "$default_opus_bitrate" --vbr \
			--discard-comments --discard-pictures \
			--title "${tag_song}" \
			--artist "${tag_artist}" \
			--album "${tag_album}" \
			--date "${tag_date_formated}" \
			"${files%.*}".wav "${files%.*}".opus
	else
		"$opusenc_bin" \
		--bitrate "$default_opus_bitrate" --vbr \
			--discard-comments --discard-pictures \
			--title "${tag_song}" \
			--artist "${tag_artist}" \
			--album "${tag_album}" \
			--date "${tag_date_formated}" \
			"${files%.*}".wav "${files%.*}".opus &>/dev/null \
			&& echo_pre_space "✓ OPUS    <- $(basename "${files%.*}").wav" \
			|| echo_pre_space "x OPUS    <- $(basename "${files%.*}").wav"
	fi
fi
}

# Convert loop
loop_adplay() {					# PC AdLib
if (( "${#lst_adplay[@]}" )) && [[ -z "$adplay_fail" ]]; then
	# Reset WAV array
	unset lst_wav

	# User info - Title
	display_loop_title "adplay" "PC AdLib"

	# Tag
	tag_machine="PC AdLib"
	tag_questions

	# Wav loop
	display_convert_title "LINE"
	for files in "${lst_adplay[@]}"; do
		# Tag
		tag_adlib
		tag_album
		# Extract WAV
		cmd_adplay
		# Remove silence
		wav_remove_silent
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Add fade out
		wav_fade_out
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Reset
	unset tag_tracker_music
fi
}
loop_asapconv() {				# Atari XL/XE
if (( "${#lst_asapconv[@]}" )) && [[ -z "$asapconv_fail" ]]; then
	# Reset WAV array
	unset lst_wav

	# User info - Title
	display_loop_title "asapconv" "Atari XL/XE"

	# Tag
	tag_machine="Atari XL/XE"
	tag_sap
	tag_questions
	tag_album

	# Wav loop
	display_convert_title "WAV"
	for files in "${lst_asapconv[@]}"; do
		# Filename contruction
		file_name=$(basename "${files%.*}.wav")
		# Extract WAV
		(
		cmd_asapconv
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
		# Remove silence
		wav_remove_silent
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Add fade out
		wav_fade_out
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_bchunk() {					# Various machines CDDA
if (( "${#lst_bchunk_iso[@]}" )) && [[ -z "$bchunk_fail" ]]; then
	# If bchunk="1" in list_source_files()
	if [[ -n "$bchunk" ]]; then

		# Local variable
		local track_name

		# Reset WAV array
		unset lst_wav

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
			tag_song="[unknown]"
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
			wav2flac \
			&& wav2wavpack \
			&& wav2ape
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait
	fi
fi
}
loop_ffmpeg_gbs() {				# GB/GBC
if (( "${#lst_ffmpeg_gbs[@]}" )) && [[ -z "$ffmpeg_fail" ]]; then
	# Local variables
	local file_total_track
	local total_sub_track

	# Reset WAV array
	unset lst_wav

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
			if [[ -f "$files" ]]; then
				# Fade out
				imported_sox_fade_out="$xxs_fading_second"
				wav_fade_out
				# Remove silence
				wav_remove_silent
				# Peak normalisation, false stereo detection 
				wav_normalization_channel_test
				# Flac conversion
				(
				wav2flac \
				&& wav2wavpack \
				&& wav2ape \
				&& wav2opus
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
loop_ffmpeg_hes() {				# PC-Engine (HuC6280)
if (( "${#lst_ffmpeg_hes[@]}" )) && [[ -z "$ffmpeg_fail" ]]; then
	# Local variable
	local total_sub_track

	# Reset WAV array
	unset lst_wav

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
			if [[ -f "$files" ]]; then
				# Fade out
				imported_sox_fade_out="$xxs_fading_second"
				wav_fade_out
				# Remove silence
				wav_remove_silent
				# Peak normalisation, false stereo detection 
				wav_normalization_channel_test
				# Flac conversion
				(
				wav2flac \
				&& wav2wavpack \
				&& wav2ape \
				&& wav2opus
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
loop_ffmpeg_spc() {				# SNES SPC
if (( "${#lst_ffmpeg_spc[@]}" )) && [[ -z "$ffmpeg_fail" ]]; then
	# Local variable
	local spc_fading_second
	local spc_duration_total

	# Reset WAV array
	unset lst_wav

	# User info - Title
	display_loop_title "ffmpeg" "SNES SPC"

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
		spc_fading_second=$((spc_fading/1000))
		spc_duration_total=$((spc_duration+spc_fading_second))
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
		# Fade out
		spc_fading_second=$((spc_fading/1000))
		imported_sox_fade_out="$spc_fading_second"
		wav_fade_out
		# Remove silence
		wav_remove_silent
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

fi
}
loop_gsf() {					# GBA
if (( "${#lst_gsf[@]}" )) && [[ -z "$gsf_fail" ]]; then
	# Reset WAV array
	unset lst_wav

	# Tag
	tag_machine="GBA"

	# If gsf2wav
	if [[ -n "$gsf2wav_bin" ]]; then

		# User info - Title
		display_loop_title "gfs2wav" "GBA"
		
		# Wav loop
		display_convert_title "WAV"
		for files in "${lst_gsf[@]}"; do
			# Tag (one time)
			if [[ "$files" = "${lst_gsf[0]}" ]];then
				tag_xfs
				tag_questions
				tag_album
			fi
			(
			cmd_gsf2wav
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

	# If zxtune
	else
		# User info - Title
		display_loop_title "zxtune" "GBA"

		# Wav loop
		display_convert_title "WAV"
		for files in "${lst_gsf[@]}"; do
			# Tag (one time)
			if [[ "$files" = "${lst_gsf[0]}" ]];then
				tag_xfs
				tag_questions
				tag_album
			fi
			# Filename contruction
			file_name=$(basename "${files%.*}")
			file_name_random=$(( RANDOM % 10000 ))
			# Extract WAV
			(
			cmd_zxtune_various
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait

	fi

	# Generate wav array
	list_wav_files

	# Flac/tag loop
	display_convert_title "FLAC"
	for files in "${lst_gsf[@]}"; do
		# Tag
		tag_xfs
		tag_questions
		tag_album

		# Consider fade out if N64 files not have tag_length, or force
		if [[ "${files##*.}" = "miniusf" ]] \
		|| [[ "${files##*.}" = "usf" ]] \
		|| [[ "$force_fade_out" = "1" ]]; then
			if [[ -z "$tag_length" ]]; then
				# Remove silence
				wav_remove_silent
				# Fade out
				wav_fade_out
				# Peak normalisation, false stereo detection 
				wav_normalization_channel_test
			else
				# Remove silence
				wav_remove_silent
				# Peak normalisation, false stereo detection 
				wav_normalization_channel_test
			fi
		else
			# Remove silence
			wav_remove_silent
			# Peak normalisation, false stereo detection 
			wav_normalization_channel_test
		fi
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_mdx2wav() {				# Sharp X68000
if (( "${#lst_mdx2wav[@]}" )) && [[ -z "$mdx2wav_fail" ]]; then
	# Reset WAV array
	unset lst_wav

	# Tag
	tag_machine="Sharp X68000"
	tag_questions
	tag_album

	# User info - Title
	display_loop_title "mdx2wav" "Sharp X68000"

	# Wav loop
	display_convert_title "WAV"
	for files in "${lst_mdx2wav[@]}"; do
		(
		cmd_mdx2wav
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
		# Remove silence
		wav_remove_silent
		# Fade out
		wav_fade_out
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_mednafen_snsf() {			# SNES SNSF
if (( "${#lst_mednafen_snsf[@]}" )) && [[ -z "$mednafen_fail" ]]; then
	# Local variables
	local file_name
	local file_name_random

	# Reset WAV array
	unset lst_wav

	# Force remove silence
	remove_silence="1"

	# User info - Title
	display_loop_title "mednafen" "SNES SNSF"

	# Wav loop
	display_convert_title "WAV"
	for files in "${lst_mednafen_snsf[@]}"; do
		# Tag
		tag_xfs
		if [[ "$files" = "${lst_mednafen_snsf[0]}" ]];then
			if [[ -z "$tag_machine" ]]; then
				tag_machine="SNES"
			fi
			tag_questions
			tag_album
		fi
		# Consider SNSF not have tag_length, or force 5min time out
		if [[ -z "$tag_length" ]]; then
			snsf_duration="300"
		# Add 5s, the start-up gap of mednafen
		else
			snsf_duration="$(( tag_length + 5 ))"
		fi
		# Extract WAV
		cmd_mednafen_snsf
	done

	# Flac/tag loop
	display_convert_title "FLAC"
	for files in "${lst_mednafen_snsf[@]}"; do
		# Tag
		tag_xfs
		tag_questions
		tag_album

		# Remove silence
		wav_remove_silent
		# Fade out
		if [[ -n "$tag_fade" ]]; then
			imported_sox_fade_out="$tag_fade"
			wav_fade_out
		fi
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Reset remove silence
	unset "$remove_silence"
fi
}
loop_midi() {					# midi
if (( "${#lst_midi[@]}" )) && [[ -z "$midi_fail" ]]; then
	# Local variables
	local midi_bin
	local fluidsynth_loop_nb

	# Reset WAV array
	unset lst_wav

	# User info - Title
	display_loop_title "fluidsynth/munt" "midi"

	# Soundfont label
	current_soundfount=" ${fluidsynth_soundfont##*/}"

	# Bin selection
	echo_pre_space "Select midi software synthesizer:"
	echo
	echo_pre_space " [0] > fluidsynth -> Use soundfont${current_soundfount} $fluidsynth_fail"
	echo_pre_space " [1] > munt       -> Use Roland MT-32, CM-32L, CM-64, LAPC-I emulator $munt_fail"
	read -r -e -p " -> " midi_choice
	case "$midi_choice" in
		"0")
			midi_bin="fluidsynth"
			if [[ -n "$fluidsynth_bin" ]]; then
				tag_tracker_music="Soundfont${current_soundfount}"
				if [[ -z "$fluidsynth_soundfont" ]]; then
					echo_pre_space "Warning, the variable (fluidsynth_soundfont) indicating the location"
					echo_pre_space "of the soundfont to use is not filled in, the result can be disgusting."
					echo_pre_space "Read documentation."
				elif ! [[ -f "$fluidsynth_soundfont" ]]; then
					echo_pre_space "Break, the variable (fluidsynth_soundfont) not indicating a file."
					echo_pre_space "Read documentation."
					exit
				fi
			else
				echo "Break, $midi_bin is not installed"
				exit
			fi
		;;
		"1")
			midi_bin="munt"
			if [[ -n "$munt_bin" ]]; then
				tag_tracker_music="Roland MT-32"
				if [[ -z "$munt_rom_path" ]]; then
					echo "Break, the variable (munt_rom_path) indicating the location of the Roland MT-32 ROM must be filled in. See documentation."
					exit
				elif ! [[ -d "$munt_rom_path" ]]; then
					echo "Break, the variable (munt_rom_path) not indicating a directory. See documentation."
					exit
				fi
			else
				echo "Break, $midi_bin is not installed"
				exit
			fi
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
		# Remove silence
		wav_remove_silent
		# Add fade out
		wav_fade_out
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Reset
	unset tag_tracker_music
fi
}
loop_nsfplay_nsf() {			# NES nsf
if (( "${#lst_nsfplay_nsf[@]}" )) && [[ -z "$nsfplay_fail" ]]; then

	# Local variables
	local file_total_track
	local total_sub_track

	# Reset WAV array
	unset lst_wav

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
			if [[ -f "$files" ]]; then
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
				wav2flac \
				&& wav2wavpack \
				&& wav2ape \
				&& wav2opus
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
loop_nsfplay_nsfe() {			# NES nsfe
if (( "${#lst_nsfplay_nsfe[@]}" )) && [[ -z "$nsfplay_fail" ]]; then
	# Bin check & set
	nsfplay_bin

	# Local variables
	local file_total_track
	local total_sub_track

	# Reset WAV array
	unset lst_wav

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
			if [[ -f "$files" ]]; then
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
				wav2flac \
				&& wav2wavpack \
				&& wav2ape \
				&& wav2opus
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
loop_sc68() {					# Atari ST (YM2149)
if (( "${#lst_sc68[@]}" )) && [[ -z "$sc68_fail" ]]; then
	# Local variables
	local total_sub_track
	local track_name
	local ext

	# Reset WAV array
	unset lst_wav

	# User info - Title
	display_loop_title "sc68" "Atari ST (YM2149)"

	# Tag
	tag_machine="Atari ST"

	# .snd, .sndh loop
	for sc68_files in "${lst_sc68[@]}"; do
		ext="${sc68_files##*.}"
		ext="${ext,,}"
		if [[ "$ext" = "sndh" ]]; then
			# Tag
			tag_sc68
			tag_questions
			tag_album

			# Get total track
			total_sub_track=$(< "$vgm2flac_cache_tag" grep -i -a track: | sed 's/^.*: //' | tail -1)

			# Extract WAV
			display_convert_title "WAV"
			for sub_track in $(seq -w 1 "$total_sub_track"); do
				# Filename contruction
				track_name=$(basename "${sc68_files%.*}")
				if [[ "$total_sub_track" -gt "1" ]]; then
					final_file_name="$sub_track - $track_name"
				else
					final_file_name="$track_name"
				fi
				(
				cmd_sc68
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
				tag_song="[unknown]"
				# Remove silence
				wav_remove_silent
				# Add fade out
				wav_fade_out
				# Peak normalisation, false stereo detection 
				wav_normalization_channel_test
				# Flac conversion
				(
				wav2flac \
				&& wav2wavpack \
				&& wav2ape \
				&& wav2opus
				) &
				if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
					wait -n
				fi
			done
			wait
		fi
	done

	# .sc68 loop
	for sc68_files in "${lst_sc68[@]}"; do
		ext="${sc68_files##*.}"
		ext="${ext,,}"
		if  [[ "$ext" = "snd" ]] || [[ "$ext" = "sc68" ]]; then
			# Tag
			tag_sc68
			tag_questions
			tag_album

			# Get total track
			total_sub_track=$(< "$vgm2flac_cache_tag" grep -i -a track: | sed 's/^.*: //' | tail -1)

			# Extract WAV
			display_convert_title "LINE"
			# Filename contruction
			track_name=$(basename "${sc68_files%.*}")
			final_file_name="$track_name"
			cmd_sc68

			# wav Filename
			files="${sc68_files%.*}.wav"

			# Flac loop
			if [[ -f "${files}" ]]; then
				# Remove silence
				wav_remove_silent
				# Add fade out
				wav_fade_out
				# Peak normalisation, false stereo detection 
				wav_normalization_channel_test
				# Flac conversion
				wav2flac \
				&& wav2wavpack \
				&& wav2ape \
				&& wav2opus
			fi
		fi
	done

fi
}
loop_sidplayfp_sid() {			# Commodore 64/128
if (( "${#lst_sidplayfp_sid[@]}" )) && [[ -z "$sidplayfp_fail" ]]; then

	# Local variable
	local test_duration
	local hvsc_db
	local test_ext_file

	# Reset WAV array
	unset lst_wav

	# https://hvsc.c64.org/ db test
	if [[ -n "$hvsc_directory" ]]; then
		if ! [[ -d "$hvsc_directory" ]]; then
			echo_pre_space "Break, the variable (hvsc_directory) not indicating a valid directory."
			echo_pre_space "Read documentation."
			exit
		fi
	fi
	hvsc_db_test=$(< /home/$USER/.config/sidplayfp/sidplayfp.ini grep "Songlengths")
	if [[ -n "$hvsc_directory" ]]; then
		hvsc_db="1"
		export HVSC_BASE="$hvsc_directory"
	elif [[ -n "$hvsc_db_test" ]]; then
		hvsc_db="1"
	fi

	# User info - Title
	display_loop_title "sidplayfp" "Commodore 64/128"

	for files in "${lst_sidplayfp_sid[@]}"; do
		# Tag extract
		test_ext_file="${files##*.}"
		if ! [[ "${test_ext_file^^}" =~ "PRG" ]]; then
			tag_sid
		fi
		tag_questions
		tag_album
		tag_song

		# Wav loop by track
		display_convert_title "WAV"
		if [[ -z "$hvsc_db" ]]; then
			cmd_sidplayfp_duration
		else
			cmd_sidplayfp
		fi
	done

	# Generate wav array
	list_wav_files

	# Flac loop
	if (( "${#lst_wav[@]}" )); then
		display_convert_title "FLAC"
		for files in "${lst_wav[@]}"; do
			# Tag
			tag_song="[unknown]"
			# Remove silence
			wav_remove_silent
			# Add fade out
			wav_fade_out
			# Peak normalisation, false stereo detection 
			wav_normalization_channel_test
			# Flac conversion
			(
			wav2flac \
			&& wav2wavpack \
			&& wav2ape \
			&& wav2opus
			) &
			if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
				wait -n
			fi
		done
		wait
	fi

fi
}
loop_sox() {					# Various machines
if (( "${#lst_sox_pass[@]}" )); then
	# Local variables
	local sox_sample_rate_question
	local sox_channel_question
	local sox_loop_question

	# Reset WAV array
	unset lst_wav

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
		# Remove silence
		wav_remove_silent
		# Fade out
		if [[ "$force_fade_out" = "1" ]]; then
			wav_fade_out
		fi
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

fi
}
loop_uade() {					# Amiga / Tracker
if (( "${#lst_uade[@]}" )) && [[ -z "$uade123_fail" ]]; then
	# Local variables
	local total_track
	local current_track
	local diff_track
	local file_name

	# Reset WAV array
	unset lst_wav

	# FLAC function
	make_flac() {
		# Tag
		tag_song
		tag_tracker_music "uade"
		tag_album
		# Remove silence
		wav_remove_silent
		# Fade out
		wav_fade_out
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Flac conversion
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
	}

	# User info - Title
	display_loop_title "uade" "Amiga / Tracker"

	display_convert_title "LINE"
	for uade_files in "${lst_uade[@]}"; do
		# Tag
		tag_questions
		tag_tracker_music "uade"

		# Get total track
		total_track=$("$uade123_bin" -g "$uade_files" 2>/dev/null \
						| grep "subsongs:"  | awk '/^subsongs:/ { print $NF }')
		current_track=$("$uade123_bin" -g "$uade_files" 2>/dev/null \
						| grep "subsongs:" | awk '/^subsongs:/ { print $3 }')
		diff_track=$(( total_track - current_track ))

		# Convertion
		# No sub_tracks
		if [[ "$diff_track" = "0" ]]; then
			# Filename construction
			sub_track="0"
			# For uade output
			file_name="${uade_files}"
			# For FLAC encoding
			files="${file_name}.wav"

			# WAV
			cmd_uade
			# FLAC
			make_flac

		# With sub_tracks
		else
			for sub_track in $(seq -w "$current_track" "$total_track"); do
				# Filename construction
				file_name="${uade_files}-$sub_track"
				all_sub_track+=( "${uade_files}-${sub_track}.wav" )
				# For FLAC encoding
				lst_wav+=("${file_name}".wav)

				# WAV
				cmd_uade
			done

			# Contruct one file with all subsongs
			# Filename construction
			file_name="${uade_files}"
			# For FLAC encoding
			lst_wav+=("${file_name}".wav)

			# Merge files
			if [[ "$verbose" = "1" ]]; then
				ffmpeg $ffmpeg_log_lvl -f concat -safe 0 \
					-i <(for f in "${all_sub_track[@]}"; do echo "file '$f'"; done) \
					-c copy "${file_name}.wav"
			else
				ffmpeg $ffmpeg_log_lvl -f concat -safe 0 \
					-i <(for f in "${all_sub_track[@]}"; do echo "file '$f'"; done) \
					-c copy "${file_name}.wav" &>/dev/null \
					&& echo_pre_space "✓ WAV     <- ${file_name##*/}" \
					|| echo_pre_space "x WAV     <- ${file_name##*/}"
			fi

			# FLAC
			for files in "${lst_wav[@]}"; do
				make_flac
			done

			# Reset
			unset all_sub_track
			unset lst_wav
		fi
	done

	# Reset
	unset tag_tracker_music
fi
}
loop_vgm2wav() {				# Various machines
if (( "${#lst_vgm2wav[@]}" )) && [[ -z "$vgm2wav_fail" ]]; then
	# Reset WAV array
	unset lst_wav

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

	# Flac & WAVPACK + tag loop
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

		# Remove silence
		wav_remove_silent
		# Add fade out
		if [[ "$force_fade_out" = "1" ]]; then
			wav_fade_out
		fi
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test

		# Flac & wavpack conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_vgmstream() {				# Various machines
if (( "${#lst_vgmstream[@]}" )) && [[ -z "$vgmstream_fail" ]]; then
	# Local variables
	local total_sub_track
	local test_ext_file

	# Reset WAV array
	unset lst_wav

	# User info - Title
	display_loop_title "vgmstream" "Various machines"

	# Tag
	# No prompt message during extraction if several loop launched
	if [[ "${#lst_all_files_pass[@]}" = "${#lst_vgmstream[@]}" ]]; then
		tag_questions
	else
		tag_game="Unknown"
		tag_artist="Unknown"
		tag_date="NULL"
		tag_machine="NULL"
		unset tag_tracker_music
	fi
	tag_album

	display_convert_title "WAV"
	for files in "${lst_vgmstream[@]}"; do
		# Get total track
		# Ignore txtp
		test_ext_file="${files##*.}"
		if ! [[ "${test_ext_file^^}" =~ "TXTP" ]]; then
			total_sub_track=$("$vgmstream_cli_bin" -m "$files" \
							| grep -i -a "stream count" | sed 's/^.*: //')
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
		# Remove silence
		wav_remove_silent
		# Fade out, vgmstream fade out default off, special case for files: his & argument force
		if [[ "$force_fade_out" = "1" ]]; then
			wav_fade_out
		fi
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

fi
}
loop_wildmidi() {				# HMI/XMI
if (( "${#lst_wildmidi[@]}" )) && [[ -z "$wildmidi_fail" ]]; then
	# Local variables
	local file_name
	local test_ext_file

	# Reset WAV array
	unset lst_wav

	# User info - Title
	display_loop_title "wildmidi" "HMI/XMI"

	# Tag
	tag_questions

	# Loop
	display_convert_title "LINE"
	for files in "${lst_wildmidi[@]}"; do
		# Extract WAV
		cmd_wildmidi
		# Tag extract
		test_ext_file="${files##*.}"
		if [[ "${test_ext_file^^}" = "HMI" ]] \
		|| [[ "${test_ext_file^^}" = "HMP" ]]; then
			tag_machine="PC HMI"
		elif [[ "${test_ext_file^^}" = "XMI" ]]; then
			tag_machine="PC XMI"
		fi
		# Tag
		tag_song
		tag_album
		# Remove silence
		wav_remove_silent
		# Add fade out
		wav_fade_out
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Reset
	unset tag_tracker_music
fi
}
loop_xmp() {					# XMP
if (( "${#lst_xmp[@]}" )) && [[ -z "$xmp_fail" ]]; then
	# Local variables
	local file_name

	# Reset WAV array
	unset lst_wav

	# User info - Title
	display_loop_title "xmp" "Tracker"

	# Tag
	tag_machine="Tracker"
	tag_questions

	# Loop
	display_convert_title "LINE"
	for files in "${lst_xmp[@]}"; do
		# Extract WAV
		cmd_xmp
		# Tag
		tag_song
		tag_tracker_music "xmp"
		tag_album
		# Remove silence
		wav_remove_silent
		# Add fade out
		wav_fade_out
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Reset
	unset tag_tracker_music
fi
}
loop_zxtune_ay() {				# Amstrad CPC, ZX Spectrum
if (( "${#lst_zxtune_ay[@]}" )) && [[ -z "$zxtune123_fail" ]]; then
	# Reset WAV array
	unset lst_wav

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
			wav2flac \
			&& wav2wavpack \
			&& wav2ape \
			&& wav2opus
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
				# Remove silence
				wav_remove_silent
				# Add fade out
				wav_fade_out
				# Peak normalisation, false stereo detection 
				wav_normalization_channel_test
				# Flac conversion
				(
				wav2flac \
				&& wav2wavpack \
				&& wav2ape \
				&& wav2opus
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
loop_zxtune_xfs() {				# PS1, PS2, NDS, Saturn, GBA, N64, Dreamcast
if (( "${#lst_zxtune_xsf[@]}" )) && [[ -z "$zxtune123_fail" ]]; then
	# Local variables
	local file_name
	local file_name_random

	# Reset WAV array
	unset lst_wav

	# User info - Title
	display_loop_title "zxtune" "Dreamcast, N64, NDS, Saturn, PS1, PS2"

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
		cmd_zxtune_various
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
		if [[ "${files##*.}" = "miniusf" ]] \
		|| [[ "${files##*.}" = "usf" ]] \
		|| [[ "$force_fade_out" = "1" ]]; then
			if [[ -z "$tag_length" ]]; then
				# Remove silence
				wav_remove_silent
				# Fade out
				wav_fade_out
				# Peak normalisation, false stereo detection 
				wav_normalization_channel_test
			else
				# Remove silence
				wav_remove_silent
				# Peak normalisation, false stereo detection 
				wav_normalization_channel_test
			fi
		else
			# Remove silence
			wav_remove_silent
			# Peak normalisation, false stereo detection 
			wav_normalization_channel_test
		fi
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_zxtune_ym() {				# Amstrad CPC, Atari ST (YM2149)
if (( "${#lst_zxtune_ym[@]}" )) && [[ -z "$zxtune123_fail" ]]; then
	# Bin check & set
	zxtune123_bin

	# Local variables
	local file_name

	# Reset WAV array
	unset lst_wav

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
		cmd_zxtune_various
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
		# Remove silence
		wav_remove_silent
		# Add fade out
		wav_fade_out
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait
fi
}
loop_zxtune_various_music() {	# ZXTune Tracker
if (( "${#lst_zxtune_various[@]}" )) && [[ -z "$zxtune123_fail" ]]; then
	# Local variables
	local file_name

	# Reset WAV array
	unset lst_wav

	# User info - Title
	display_loop_title "zxtune" "Various Music"

	# Tag
	tag_machine="Tracker"
	tag_questions


	# Loop
	display_convert_title "LINE"
	for files in "${lst_zxtune_various[@]}"; do
		# Filename contruction
		file_name=$(basename "${files%.*}")
		file_name_random=$(( RANDOM % 10000 ))
		# Extract WAV
		cmd_zxtune_various
		# Tag
		tag_song
		tag_tracker_music "zxtune"
		tag_album
		# Remove silence
		wav_remove_silent
		# Add fade out
		wav_fade_out
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi
	done
	wait

	# Reset
	unset tag_tracker_music
fi
}
loop_zxtune_zx_spectrum() {		# ZX Spectrum
if (( "${#lst_zxtune_zx_spectrum[@]}" )) && [[ -z "$zxtune123_fail" ]]; then
	# Local variables
	local file_name

	# Reset WAV array
	unset lst_wav

	# User info - Title
	display_loop_title "zxtune" "ZX Spectrum"

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
		cmd_zxtune_various
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
		# Remove silence
		wav_remove_silent
		# Add fade out
		wav_fade_out
		# Peak normalisation, false stereo detection 
		wav_normalization_channel_test
		# Flac conversion
		(
		wav2flac \
		&& wav2wavpack \
		&& wav2ape \
		&& wav2opus
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
if (( "${#lst_flac[@]}" )); then
	local tag_track_count
	local count

	for files in "${lst_flac[@]}"; do
		tag_track_count=$((count+1))
		count="$tag_track_count"

		# Add lead zero if necessary
		if [[ "${#lst_flac[@]}" -lt "100" ]]; then
			# if integer in one digit
			if [[ "${#tag_track_count}" -eq "1" ]] ; then
				local tag_track_count="0$tag_track_count" 
			fi
		elif [[ "${#lst_flac[@]}" -ge "100" ]]; then
			# if integer in one digit
			if [[ "${#tag_track_count}" -eq "1" ]] ; then
				local tag_track_count="00$tag_track_count"
			# if integer in two digit
			elif [[ "${#tag_track_count}" -eq "2" ]] ; then
				local tag_track_count="0$tag_track_count"
			fi
		fi

		# Add track tag with metaflac
		if [[ -n "$metaflac_bin" ]]; then
			"$metaflac_bin" \
			--remove-tag=ENCODER --set-tag=ENCODEDBY="$flac_version" \
			--remove-tag=TRACKNUMBER --set-tag=TRACKNUMBER="$tag_track_count" "$files"
		# Or add track tag with ffmpeg
		elif [[ -z "$metaflac_bin" ]]; then
			ffmpeg $ffmpeg_log_lvl -i "$files" -c:v copy -c:a copy \
				-metadata TRACKNUMBER="$tag_track_count" \
				"${files%.*}"-temp.flac
			# If temp-file exist remove source and rename
			if [[ -f "${files%.*}-temp.flac" && -s "${files%.*}-temp.flac" ]]; then
				rm "$files" &>/dev/null
				mv "${files%.*}"-temp.flac "$files" &>/dev/null
			fi
		fi

		# Monkey's Audio
		if [[ -s "${files%.*}.ape" ]]; then
			"$mac_bin" \
			"${files%.*}.ape" \
			-t "Track=${tag_track_count}|EncodedBy=${mac_version}" &>/dev/null
		fi

		# WAVPACK
		if [[ -s "${files%.*}.wv" ]]; then
			"$wvtag_bin" -q -y \
			-w Track="$tag_track_count" \
			-w EncodedBy="$wavpack_version" \
			"${files%.*}.wv"
		fi

	done
fi
}
tag_questions() {
if [[ "$only_wav" != "1" ]]; then

	# Game
	if [[ -z "$tag_game" ]]; then
		read -r -e -p " Enter the game or album title: " tag_game
		display_remove_previous_line
		if [[ -z "$tag_game" ]]; then
			tag_game="[unknown]"
		fi
	fi

	# Artist
	if [[ -z "$tag_artist" ]]; then
		read -r -e -p " Enter the audio artist: " tag_artist
		display_remove_previous_line
		if [[ -z "$tag_artist" ]]; then
			tag_artist="[unknown]"
		fi
	fi

	# Date
	if [[ -z "$tag_date" ]] && [[ "$tag_q_date_pass" != "1" ]]; then
		read -r -e -p " Enter the release date: " tag_date
		display_remove_previous_line
		tag_q_date_pass="1"
		if [[ -z "$tag_date" ]]; then
			tag_date="NULL"
			unset tag_date_formated
		elif [[ -z "$tag_date" ]] && [[ "$tag_date" != "NULL" ]]; then
			tag_date_formated="$tag_date"
		fi
	fi

	# Machine
	if [[ -z "$tag_machine" ]]; then
		read -r -e -p " Enter the release platform: " tag_machine
		display_remove_previous_line
		if [[ -z "$tag_machine" ]]; then
			tag_machine="NULL"
		fi
	fi
fi
}
tag_album() {
# Local variables
local tag_machine_album_formated
local tag_tracker_music_album_formated

# If tag exist add ()
if [[ "$tag_machine" != "NULL" ]]; then
	tag_machine_album_formated=$(echo "$tag_machine" | sed 's/\(.*\)/\(\1\)/')
fi
if [[ -n "$tag_tracker_music" ]]; then
	tag_tracker_music_album_formated=$(echo "$tag_tracker_music" | sed 's/\(.*\)/\(\1\)/')
fi

# Album tag
tag_album=$(echo "$tag_game $tag_machine_album_formated $tag_tracker_music_album_formated" | sed 's/ *$//')
}
tag_song() {
tag_song=$(basename "${files%.*}")
}
tag_replaygain() {
if (( "${#lst_flac[@]}" )) \
&& [[ -n "$rsgain_bin" || -n "$metaflac_bin" ]] \
&& [[ "$normalization" != "1" ]]; then

	local db
	local db_filename

	for files in "${lst_flac[@]}"; do

		(
		# FLAC
		if [[ -n "$rsgain_bin" ]]\
		&& [[ -s "${files%.*}.flac" ]]; then
			"$rsgain_bin" custom -q -c a -s i "${files%.*}.flac"
		elif [[ -n "$metaflac_bin" ]] \
		&& [[ -s "${files%.*}.flac" ]]; then
			"$metaflac_bin" --add-replay-gain "${files%.*}.flac"
		fi

		# OPUS
		if [[ -n "$rsgain_bin" ]]\
		&& [[ -s "${files%.*}.opus" ]]; then
			"$rsgain_bin" custom -q -c a -s i "${files%.*}.opus"
		fi

		# Monkey's Audio
		if [[ -n "$rsgain_bin" ]]\
		&& [[ -s "${files%.*}.ape" ]]; then
			"$rsgain_bin" custom -q -c a -s i "${files%.*}.ape"
		fi

		# WAVPACK
		if [[ -n "$rsgain_bin" ]]\
		&& [[ -s "${files%.*}.wv" ]]; then
			"$rsgain_bin" custom -q -c a -s i "${files%.*}.wv"
		fi
		) &
		if [[ $(jobs -r -p | wc -l) -ge $nprocessor ]]; then
			wait -n
		fi

	done
	wait

	# Record for summary
	if [[ -n "$mutagen_inspect_bin" ]]; then
		for files in "${lst_flac[@]}"; do

			# FLAC
			if [[ -n "$rsgain_bin" || -n "$metaflac_bin" ]]\
			&& [[ -s "${files%.*}.flac" ]]; then
				db_filename=$(basename "${files%.*}".flac)
				db=$("$mutagen_inspect_bin" "${files%.*}.flac" \
					| grep -Po "REPLAYGAIN_TRACK_GAIN=\K.*")
				if ! [[ "${db:0:1}" == "-" ]]; then
					db="+${db}"
				fi
				lst_replaygain+=( "${db}|${db_filename}" )
			fi

			# OPUS
			if [[ -n "$rsgain_bin" ]]\
			&& [[ -s "${files%.*}.opus" ]]; then
				db_filename=$(basename "${files%.*}".opus)
				db=$("$mutagen_inspect_bin" "${files%.*}.opus" \
					| grep -Po "REPLAYGAIN_TRACK_GAIN=\K.*")
				if ! [[ "${db:0:1}" == "-" ]]; then
					db="+${db}"
				fi
				lst_replaygain+=( "${db}|${db_filename}" )
			fi

			# Monkey's Audio
			if [[ -n "$rsgain_bin" ]]\
			&& [[ -s "${files%.*}.ape" ]]; then
				db_filename=$(basename "${files%.*}".ape)
				db=$("$mutagen_inspect_bin" "${files%.*}.ape" \
					| grep -Po "REPLAYGAIN_TRACK_GAIN=\K.*")
				if ! [[ "${db:0:1}" == "-" ]]; then
					db="+${db}"
				fi
				lst_replaygain+=( "${db}|${db_filename}" )
			fi

			# WAVPACK
			if [[ -n "$rsgain_bin" ]]\
			&& [[ -s "${files%.*}.wv" ]]; then
				db_filename=$(basename "${files%.*}".wv)
				db=$("$mutagen_inspect_bin" "${files%.*}.wv" \
					| grep -Po "REPLAYGAIN_TRACK_GAIN=\K.*")
				if ! [[ "${db:0:1}" == "-" ]]; then
					db="+${db}"
				fi
				lst_replaygain+=( "${db}|${db_filename}" )
			fi

		done
	fi

fi
}

# Tag by files type
tag_m3u_clean_extract() {
# Local variable
local m3u_track_hex_test

m3u_track_hex_test=$(< "$m3u_file" awk -F"," '{ print $2 }' | grep -F -e "$")

# Decimal track
if [[ -z "$m3u_track_hex_test" ]]; then
	< "$m3u_file" sed '/^#/d' | sed 's/\\,/ -/g' | sed 's/\\//g' | uniq | sed -r '/^\s*$/d' | sort -t, -k2,2 -n \
	| sed 's/.*::/GAME::/' > "$vgm2flac_cache_tag"

# Hexadecimal track
else
	< "$m3u_file" sed '/^#/d' | sed 's/\\,/ -/g' | sed 's/\\//g' | uniq | sed -r '/^\s*$/d' \
	| tr -d '$' | awk --non-decimal-data -F ',' -v OFS=',' '$1 {$2=("0x"$2)+0; print}' \
	| sort -t, -k2,2 -n | sed 's/.*::/GAME::/' > "$vgm2flac_cache_tag"
fi
}
tag_xxs_loop() {				# Game Boy (gbs), NES (nsf), PC-Enginge (HES)
if (( "${#lst_m3u[@]}" )) && [[ -f "$m3u_file" ]]; then

	# Local variables
	local xxs_duration
	local xxs_duration_format
	local xxs_fading
	local xxs_fading_format

	# Get song title
	tag_song=$(< "$vgm2flac_cache_tag" awk -v var=$xxs_track -F',' '$2 == var { print $0 }' \
				| awk -F"," '{ print $3 }' | sed '/^$/d')
	# Replace eventualy "/" & ":" in string
	tag_song=$(echo "$tag_song" | sed s#/#-#g | sed s#:#-#g)
	if [[ -z "$tag_song" ]]; then
		tag_song="[unknown]"
	fi

	# Get duration
	# Total duration in ?:m:s
	xxs_duration=$(< "$vgm2flac_cache_tag" grep ",$xxs_track," \
					| awk -F"," '{ print $4 }' | tr -d '[:space:]' \
					| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')
	if [[ -n "$xxs_duration" ]]; then
		xxs_duration_format=$(echo "$xxs_duration"| grep -o ":" | wc -l)
		# If duration is in this format = h:m:s
		if [[ "$xxs_duration_format" = "2" ]]; then
			xxs_duration=$(echo "$xxs_duration" | awk -F":" '{ print ($2":"$3) }')
		# If duration is in this format = s
		elif [[ "$xxs_duration_format" = "0" && -n "$xxs_duration" ]]; then
			xxs_duration=$(echo "$xxs_duration" | sed 's/^/00:/')
		fi
		# Total duration in s
		xxs_duration_second=$(echo "$xxs_duration" | awk -F":" '{ print ($1 * 60) + $2 }' \
								| tr -d '[:space:]')
		# Duration value - in s+1 & ms
		xxs_duration_second=$((xxs_duration_second+1))
		xxs_duration_msecond=$((xxs_duration_second*1000))
	else
		# Duration value - in s+1 & ms
		xxs_duration_second="$xxs_default_max_duration"
		xxs_duration_msecond=$((xxs_default_max_duration*1000))
	fi

	# Fade out
	# Fade out duration in ?:m:s
	xxs_fading=$(< "$vgm2flac_cache_tag" grep ",$xxs_track," \
				| awk -F"," '{ print $(NF) }' | tr -d '[:space:]' \
				| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')
	if [[ -n "$xxs_fading" ]]; then
		xxs_fading_format=$(echo "$xxs_fading"| grep -o ":" | wc -l)
		# If duration is in this format = h:m:s
		if [[ "$xxs_fading_format" = "2" ]]; then
			xxs_fading=$(echo "$xxs_fading" | awk -F":" '{ print ($2":"$3) }')
		# If duration is in this format = s
		elif [[ "$xxs_fading_format" = "0" && -n "$xxs_fading" ]]; then
			xxs_fading=$(echo "$xxs_fading" | sed 's/^/00:/')
		fi
		# Fading value - in s & ms
		xxs_fading_second=$(echo "$xxs_fading" | awk -F":" '{ print ($1 * 60) + $2 }' \
							| tr -d '[:space:]')
		xxs_fading_msecond=$((xxs_fading_second*1000))
	else
		# Fading value - in s & ms
		xxs_fading_second="0"
		xxs_fading_msecond="0"
	fi

	# Prevent incoherence duration between fade out and total duration
	if [[ "$xxs_fading_second" -ge "xxs_duration_second" ]]; then
		unset xxs_fading_second
		xxs_fading_msecond="0"
	fi

else
	tag_song="[unknown]"
	xxs_duration_second="$xxs_default_max_duration"

	# nsfplay duration & fading s to ms
	xxs_duration_msecond=$((xxs_default_max_duration*1000))
	xxs_fading_msecond=$((default_wav_fade_out*1000))
fi
}
tag_adlib() {					# PC AdLib
# Tag extract
timeout 0.01 "$adplay_bin" "$files" --output=null &> "$vgm2flac_cache_tag"

mapfile -t source_tag < <( cat "$vgm2flac_cache_tag" )
for line in "${source_tag[@]}"; do
	if [[ "$line" == "Title"* ]]; then
		tag_song=$(echo "$line" | sed 's/^.*: //')
	fi
	if [[ "$line" == "Author"* ]]; then
		tag_artist=$(echo "$line" | sed 's/^.*: //')
	fi
	if [[ "$line" == "Type"* ]]; then
		tag_tracker_music=$(echo "$line" | sed 's/^.*: //')
	fi
done

if [[ -z "$tag_artist" ]]; then
	tag_artist="Unknown"
fi
# If output dir set -> tag_game = filename
# Consider is chiptune no vgm
if [[ -n "$force_output_dir" ]]; then
	tag_game=$(basename "${files%.*}")
fi
}
tag_ay() {						# Amstrad CPC, ZX Spectrum
# Tag extract
if [[ "$total_sub_track" = "0" ]] || [[ -z "$total_sub_track" ]]; then
	ffprobe -hide_banner -loglevel panic \
		-select_streams a -show_streams \
		-show_format "$ay" > "$vgm2flac_cache_tag"
else
	ffprobe -track_index "$sub_track" \
		-hide_banner -loglevel panic \
		-select_streams a -show_streams \
		-show_format "$ay" > "$vgm2flac_cache_tag"
fi

tag_song=$(< "$vgm2flac_cache_tag" grep -i "song=" | awk -F'=' '{print $NF}')
tag_song=$(echo "$tag_song" | sed s#/#-#g | sed s#:#-#g)					# Replace eventualy "/" & ":" in string
if [[ -z "$tag_song" ]] || [[ "$tag_song" = "?" ]]; then
	tag_song="[unknown]"
fi

tag_artist_backup="$tag_artist"
tag_artist=$(< "$vgm2flac_cache_tag" grep -i "author=" | awk -F'=' '{print $NF}')
if [[ -z "$tag_artist" ]]; then
	tag_artist="$tag_artist_backup"
elif [[ "$tag_artist" = "?" ]]; then
	tag_artist=""
fi
}
tag_gbs_extract() {				# GB/GBC		- Tag extraction & m3u cleaning
# Tag extract by hexdump
tag_game=$(xxd -ps -s 0x10 -l 32 "$gbs" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
tag_artist=$(xxd -ps -s 0x30 -l 32 "$gbs" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')

# If m3u
if (( "${#lst_m3u[@]}" )); then
	m3u_file="${gbs%.*}.m3u"
	if [[ -f "$m3u_file" ]]; then
		m3u_track_hex_test=$(< "${gbs%.*}".m3u awk -F"," '{ print $2 }' | grep -F -e "$")
		tag_m3u_clean_extract
	fi
fi
}
tag_hes_extract() {				# PC Engine		- Tag extraction & m3u cleaning
# If m3u
if (( "${#lst_m3u[@]}" )); then
	m3u_file="${hes%.*}.m3u"
	if [[ -f "$m3u_file" ]]; then
		tag_game=$(< "${hes%.*}".m3u grep "@TITLE" \
					| awk -v n=3 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' \
					| tr -d "\n\r")
		tag_artist=$(< "${hes%.*}".m3u grep "@COMPOSER" \
					| awk -v n=3 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' \
					| tr -d "\n\r")
		tag_date=$(< "${hes%.*}".m3u grep "@DATE" \
					| awk -v n=3 '{ for (i=n; i<=NF; i++) printf "%s%s", $i, (i<NF ? OFS : ORS)}' \
					| tr -d "\n\r")
		tag_m3u_clean_extract
	fi
fi
}
tag_nsf_extract() {				# NES			- Tag extraction & m3u cleaning
# Tag extract by hexdump
tag_game=$(xxd -ps -s 0x00E -l 32 "$nsf" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')
tag_artist=$(xxd -ps -s 0x02E -l 32 "$nsf" | tr -d '[:space:]' | xxd -r -p | tr -d '\0')

# If m3u
if (( "${#lst_m3u}" )); then
	m3u_file="${nsf%.*}.m3u"
	if [[ -f "$m3u_file" ]]; then
		tag_m3u_clean_extract
	fi
fi
}
tag_nsfe() {					# NES
# Local variable
local nsfplay_sub_track

# Tag extract
"$nsfplay_bin" "$nsfe" > "$vgm2flac_cache_tag"

nsfplay_sub_track="${sub_track}:"

tag_song=$(< "$vgm2flac_cache_tag" grep "$nsfplay_sub_track" \
			| sed -n "s/$nsfplay_sub_track/&\n/;s/.*\n//p" \
			| awk '{$1=$1}1')
tag_song=$(echo "$tag_song" | sed s#/#-#g | sed s#:#-#g)					# Replace eventualy "/" & ":" in string
if [[ -z "$tag_song" ]]; then
	tag_song="[unknown]"
fi

tag_artist_backup="$tag_artist"
tag_artist=$(sed -n 's/Artist:/&\n/;s/.*\n//p' "$vgm2flac_cache_tag" \
			| awk '{$1=$1}1')
if [[ -z "$tag_artist" ]]; then
	tag_artist="$tag_artist_backup"
fi

if [[ -z "$tag_game" ]]; then
	tag_game=$(sed -n 's/Title:/&\n/;s/.*\n//p' "$vgm2flac_cache_tag" \
				| awk '{$1=$1}1')
fi

# Set max duration s to ms
nsfplay_default_max_duration=$((xxs_default_max_duration*1000))
}
tag_s98() {						# NEC PC-6001, PC-6601, PC-8801,PC-9801, Sharp X1, Fujitsu FM-7 & FM TownsSharp X1
# Tag extract
strings -e S "$files" > "$vgm2flac_cache_tag"

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
tag_sap() {						# Atari XL/XE
# Tag extract
strings -e S "$files" | head -15 > "$vgm2flac_cache_tag"

tag_artist=$(< "$vgm2flac_cache_tag" grep -i -a "AUTHOR" | awk -F'"' '$0=$2')
if [[ "$tag_artist" = "<?>" ]]; then
	unset tag_artist
fi
tag_game=$(< "$vgm2flac_cache_tag" grep -i -a "NAME" | awk -F'"' '$0=$2')
if [[ "$tag_game" = "<?>" ]]; then
	unset tag_game
fi
tag_date=$(< "$vgm2flac_cache_tag" grep -i -a "DATE" | awk -F'"' '$0=$2')
if [[ "$tag_date" = "<?>" ]]; then
	unset tag_date
fi
}
tag_sc68() {					# Atari ST
# Tag extract
"$info68_bin" -A "$sc68_files" > "$vgm2flac_cache_tag"
if [[ "${sc68_files##*.}" = "sc68" ]]; then
	tag_song=$(< "$vgm2flac_cache_tag" grep -i -a title: | sed 's/^.*: //' | head -1)
	if [[ "$tag_song" = "N/A" ]]; then
		unset tag_song
	fi
	tag_artist=$(< "$vgm2flac_cache_tag" grep -i -a artist: | sed 's/^.*: //' | head -1)
	if [[ -z "$tag_artist" ]]; then
		tag_artist="Unknown"
	elif [[ "$tag_artist" = "N/A" ]]; then
		tag_artist="Unknown"
	fi
	if [[ -z "$tag_date" ]]; then
		tag_date=$(< "$vgm2flac_cache_tag" grep -i -a year: | sed 's/^.*: //' | head -1)
	fi
	# Consider is chiptune no vgm
	tag_game=$(basename "${sc68_files%.*}")
fi
}
tag_sid() {						# Commodore 64/128
# Tag extract by hexdump
if [[ -z "$tag_artist" ]]; then
	tag_artist=$(xxd -ps -s 0x36 -l 32 "$files" \
				| tr -d '[:space:]' | xxd -r -p | tr -d '\0' \
				| iconv -f latin1 -t ascii//TRANSLIT \
				| awk '{$1=$1}1')
fi
if [[ "$tag_artist" = "<?>" ]]; then
	unset tag_artist
fi

if [[ -z "$tag_game" ]]; then
	tag_game=$(xxd -ps -s 0x16 -l 32 "$files" \
				| tr -d '[:space:]' | xxd -r -p | tr -d '\0' \
				| iconv -f latin1 -t ascii//TRANSLIT \
				| awk '{$1=$1}1')
fi
if [[ "$tag_game" = "<?>" ]]; then
	unset tag_game
fi
if [[ -z "$tag_machine" ]]; then
	tag_machine="C64"
fi
}
tag_spc() {						# SNES
# Local variable
local id666_test

# Tag extract by hexdump; test ID666 presence (1a hex = 26 dec)
id666_test=$(xxd -ps -s 0x00023h -l 1 "$files")
if [[ "$id666_test" = "1a" ]]; then

	tag_song=$(xxd -ps -s 0x0002Eh -l 32 "$files" \
				| tr -d '[:space:]' \
				| xxd -r -p \
				| tr -d '\0')
	if [[ -z "$tag_song" ]]; then
		tag_song
	fi

	tag_artist_backup="$tag_artist"
	tag_artist=$(xxd -ps -s 0x000B1h -l 32 "$files" \
				| tr -d '[:space:]' \
				| xxd -r -p \
				| tr -d '\0')
	if [[ -z "$tag_artist" ]]; then
		tag_artist="$tag_artist_backup"
	fi

	if [[ -z "$tag_game" ]]; then
		tag_game=$(xxd -ps -s 0x0004Eh -l 32 "$files" \
					| tr -d '[:space:]' \
					| xxd -r -p \
					| tr -d '\0')
	fi
	# Duration in s
	spc_duration=$(xxd -ps -s 0x000A9h -l 3 "$files" \
					| xxd -r -p \
					| tr -d '\0' \
					| sed 's/^0*//')
	# Fading in ms
	spc_fading=$(xxd -ps -s 0x000ACh -l 5 "$files" \
				| xxd -r -p \
				| tr -d '\0' \
				| sed 's/^0*//')

	# Duration correction if empty, or not an integer
	if [[ -z "$spc_duration" ]] || ! [[ "$spc_duration" =~ ^[0-9]*$ ]]; then
		spc_duration="$spc_default_duration"
	fi

	# Fading correction if empty, or not an integer
	if [[ -z "$spc_fading" ]] || ! [[ "$spc_fading" =~ ^[0-9]*$ ]]; then
		spc_fading=$((default_wav_fade_out*1000))
	fi

	# Prevent incoherence duration between fade out and total duration
	if [[ "$spc_duration" -ge "$spc_fading" ]]; then
		spc_fading="0"
	fi

fi
if [[ -z "$tag_machine" ]]; then
	tag_machine="SNES"
fi
}
tag_tracker_music() {			# Tracker music module
local loop

loop="$1"

if [[ "$loop" = "uade" ]]; then
	tag_tracker_music=$("$uade123_bin" -g "$uade_files" \
						| grep "playername:" \
						| sed 's/^.*: //')
fi
if [[ "$loop" = "xmp" ]]; then
	tag_tracker_music=$("$xmp_bin" "$files" --load-only 2>&1 \
						| grep "Module type" \
						| sed 's/^.*: //')
fi
if [[ "$loop" = "zxtune" ]]; then
	tag_tracker_music=$("$zxtune123_bin" "$files" --null 2>&1 \
						| grep Program \
						| sed 's/^.*: //')
fi
}
tag_vgm() {						# Various machines
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
tag_xfs() {						# PS1, PS2, NDS, Saturn, GBA, N64, Dreamcast
# Local variables
local tag_length_format

# Tag extract (Keep only ascii)
strings -e S "$files" \
	| tr -cd '\11\12\15\40-\176' \
	| sed -n '/TAG/,$p' > "$vgm2flac_cache_tag"

tag_song=$(< "$vgm2flac_cache_tag" grep -i -a title= | awk -F'=' '$0=$NF')
if [[ -z "$tag_song" ]]; then
	tag_song
fi

tag_artist_backup="$tag_artist"
tag_artist=$(< "$vgm2flac_cache_tag" grep -i -a artist= | awk -F'=' '$0=$NF')
if [[ -z "$tag_artist" ]]; then
	tag_artist="$tag_artist_backup"
fi

if [[ -z "$tag_game" && -z "$tag_date" ]]; then
	tag_game=$(< "$vgm2flac_cache_tag" grep -i -a game= | awk -F'=' '$0=$NF')
	tag_date=$(< "$vgm2flac_cache_tag" grep -i -a year= | awk -F'=' '$0=$NF')
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
elif [[ "${files##*.}" = "dsf" || "${files##*.}" = "minidsf" ]]; then
	tag_machine="Dreamcast"
fi

# SNSF & N64, get tag lenght for test in loop, notag=notimepoint -> fadeout
if [[ "${files##*.}" = "miniusf" ]] || [[ "${files##*.}" = "usf" ]] \
|| [[ "${files##*.}" = "minisnsf" ]] || [[ "${files##*.}" = "snsf" ]]; then
	tag_length=$(< "$vgm2flac_cache_tag" grep -i -a length= \
				| awk -F'=' '$0=$NF' \
				| awk -F '.' 'NF > 1 { printf "%s", $1; exit } 1')

	if [[ "${files##*.}" = "minisnsf" ]] || [[ "${files##*.}" = "snsf" ]]; then
		# SNSF case duration format is m:s
		tag_length_format=$(echo "$tag_length" | grep -o ":" | wc -l)
		# Total duration in s
		if [[ "$tag_length_format" = "1" ]]; then
			tag_length=$(echo "$tag_length" \
						| awk -F":" '{ print ($1 * 60) + $2 }' \
						| tr -d '[:space:]')
		fi

		# Fade out
		tag_fade=$(< "$vgm2flac_cache_tag" grep -i -a fade= \
					| awk -F'=' '$0=$NF')
	fi
fi
}

# Temp clean & target filename/directory structure
wav_remove() {
if (( "${#lst_wav}" )); then											# If number of wav > 0
	display_separator
	read -r -e -p " Remove wav files (temp. audio)? [y/N]:" qarm
	case $qarm in
		"Y"|"y")
			for files in "${lst_wav[@]}"; do
				rm -R "$wav_target_directory" &>/dev/null
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
local tag_tracker_music_dir
local target_directory
local flac_target_directory
local wavpack_target_directory
local ape_target_directory
local opus_target_directory

# If output dir set
if [[ -n "$force_output_dir" ]]; then
	tag_game="$force_output_dir"
fi

# Get tag, mkdir & mv
# If number of wav > 0
if (( "${#lst_wav[@]}" )); then
	if [[ "$only_wav" != "1" ]];then
		# If tag exist add () & replace eventualy "/" & ":" in string
		tag_game_dir=$(echo "$tag_game" \
						| sed s#/#-#g \
						| sed s#:#-#g)
		if ! [[ "$tag_machine" = "NULL" ]]; then
			tag_machine_dir=$(echo "$tag_machine" \
							| sed s#/#-#g \
							| sed s#:#-#g \
							| sed 's/\(.*\)/\(\1\)/')
		fi
		if ! [[ "$tag_date" = "NULL" ]]; then
			tag_date_dir=$(echo "$tag_date" \
							| sed s#/#-#g \
							| sed s#:#-#g \
							| sed 's/\(.*\)/\(\1\)/')
		fi
		if [[ -n "$tag_tracker_music" ]]; then
			tag_tracker_music_dir=$(echo "$tag_tracker_music" \
									| sed s#/#-#g \
									| sed s#:#-#g \
									| sed 's/\(.*\)/\(\1\)/')
		fi
		# Raw name of target directory
		target_directory=$(echo "$tag_game_dir $tag_date_dir $tag_machine_dir $tag_tracker_music_dir" \
							| tr -s ' ' \
							| awk '{$1=$1}1')
	else
		# Raw name of target directory
		target_directory="NO_TAG"
	fi

	# Final WAV target directory
	wav_target_directory="${PWD}/WAV-${target_directory}"
	if [[ ! -d "$wav_target_directory" ]]; then
		mkdir "$wav_target_directory" &>/dev/null
	# If target exist add date +%s after dir name
	else
		wav_target_directory="${wav_target_directory}-$(date +%s)"
		mkdir "$wav_target_directory" &>/dev/null
	fi
	# mv files
	for files in "${lst_wav[@]}"; do
		mv "$files" "$wav_target_directory" &>/dev/null
	done

	# Final FLAC target directory
	if (( "${#lst_flac[@]}" )); then
		flac_target_directory="${PWD}/FLAC-${target_directory}"
		if [[ ! -d "$flac_target_directory" ]]; then
			mkdir "$flac_target_directory" &>/dev/null
		# If target exist add date +%s after dir name
		else
			flac_target_directory="${flac_target_directory}-$(date +%s)"
			mkdir "$flac_target_directory" &>/dev/null
		fi
		# mv files
		for files in "${lst_flac[@]}"; do
			mv "$files" "$flac_target_directory" &>/dev/null
		done
	fi

	# Final WAVPACK target directory
	if (( "${#lst_wavpack[@]}" )); then
		wavpack_target_directory="${PWD}/WAVPACK-${target_directory}"
		if [[ ! -d "$wavpack_target_directory" ]]; then
			mkdir "$wavpack_target_directory" &>/dev/null
		# If target exist add date +%s after dir name
		else
			wavpack_target_directory="${wavpack_target_directory}-$(date +%s)"
			mkdir "$wavpack_target_directory" &>/dev/null
		fi
		# mv files
		for files in "${lst_wavpack[@]}"; do
			mv "$files" "$wavpack_target_directory" &>/dev/null
		done
	fi

	# Final Monkey's Audio target directory
	if (( "${#lst_ape[@]}" )); then
		ape_target_directory="${PWD}/APE-${target_directory}"
		if [[ ! -d "$ape_target_directory" ]]; then
			mkdir "$ape_target_directory" &>/dev/null
		# If target exist add date +%s after dir name
		else
			ape_target_directory="${ape_target_directory}-$(date +%s)"
			mkdir "$ape_target_directory" &>/dev/null
		fi
		# mv files
		for files in "${lst_ape[@]}"; do
			mv "$files" "$ape_target_directory" &>/dev/null
		done
	fi

	# Final Opus target directory
	if (( "${#lst_opus[@]}" )); then
		opus_target_directory="${PWD}/OPUS-${target_directory}"
		if [[ ! -d "$opus_target_directory" ]]; then
			mkdir "$opus_target_directory" &>/dev/null
		# If target exist add date +%s after dir name
		else
			opus_target_directory="${opus_target_directory}-$(date +%s)"
			mkdir "$opus_target_directory" &>/dev/null
		fi
		# mv files
		for files in "${lst_opus[@]}"; do
			mv "$files" "$opus_target_directory" &>/dev/null
		done
	fi

fi
}
end_functions() {
if [[ "$only_wav" = "1" ]]; then
	clean_target_validation
	display_all_in_errors
	display_end_summary
	mk_target_directory
	clean_cache_directory
else
	if [[ "$flac_loop_activated" = "1" ]]; then
		clean_target_validation
		tag_replaygain
		tag_track
		display_all_in_errors
		display_end_summary
		mk_target_directory
		clean_cache_directory
		wav_remove
	fi
fi
}

# Common Setup
test_write_access
common_bin
decoder_bin
encoder_bin

# Arguments variables
while [[ $# -gt 0 ]]; do
	vgm2flac_args="$1"
	case "$vgm2flac_args" in

	# Set Monkey's Audio compress too
	--add_ape)
		if [[ -n "$mac_bin" ]]; then
			ape_compress="1"
		else
			echo_pre_space "fail, monkeys-audio binary not installed"
			exit
		fi
	;;

	# Set Opus compress too
	--add_opus)
		if [[ -n "$opusenc_bin" ]]; then
			opus_compress="1"
		else
			echo_pre_space "fail, opusenc binary not installed"
			exit
		fi
	;;

	# Set WAVPACK compress too
	--add_wavpack)
		if [[ -n "$wavpack_bin" ]] \
		&& [[ -n "$wvtag_bin" ]]; then
			wavpack_compress="1"
		else
			echo_pre_space "fail, wavpack binary not installed"
			exit
		fi
	;;

	# Print installed dependencies
	-d|--dependencies)
		display_dependencies
		exit
	;;

	# Help
	-h|--help)
		cmd_usage
		exit
	;;

	# Set number of max concurrent job
	-j|--job)
		shift
		unset nprocessor
		nprocessor="$1"
		case "$nprocessor" in
			''|*[!0-9]*)
				echo_pre_space "fail, job number is empty or is not an positive enteger"
				exit
			;;
		esac
	;;

	# Set force default fade out
	--force_fade_out)
		force_fade_out="1"
	;;

	# Set force stereo output
	--force_stereo)
		force_stereo="1"
	;;

	# Set force no fade out
	--no_fade_out)
		no_fade_out="1"
	;;

	# Set force no remove duplicate files
	--no_remove_duplicate)
		no_remove_duplicate="1"
	;;

	# Set force peak db norm
	--normalization)
		normalization="1"
	;;

	# Set force output dir
	-o|--output)
		shift
		force_output_dir="$1"
		if [[ -z "$force_output_dir" ]]; then
			echo_pre_space "fail, output directory name is empty"
			exit
		fi
	;;

	# Set force wav temp. files only
	--only_wav)
		only_wav="1"
	;;

	# Print more summary info
	-s|--summary_more)
		summary_more="1"
	;;

	# Set remove silence
	--remove_silence)
		remove_silence="1"
	;;

	# Set agressive mode for remove silence 85db->58db
	--remove_silence_more)
		remove_silence="1"
		agressive_silence="1"
	;;

	# Set verbose mode
	-v|--verbose)
		verbose="1"
		unset ffmpeg_log_lvl
		ffmpeg_log_lvl="-loglevel info -stats"
	;;
	*)
		cmd_usage
		exit
	;;
	esac
	shift
done

# Files source check & set
check_cache_directory
display_conf_summary
list_source_files
display_start_summary

# Timer start
timer_start=$(date +%s)

# Encoding/tag loop
loop_adplay
loop_asapconv
loop_bchunk
loop_ffmpeg_gbs
loop_ffmpeg_hes
loop_ffmpeg_spc
loop_gsf
loop_mdx2wav
loop_mednafen_snsf
loop_midi
loop_nsfplay_nsf
loop_nsfplay_nsfe
loop_sc68
loop_sidplayfp_sid
loop_sox
loop_vgm2wav
loop_zxtune_ay
loop_zxtune_various_music
loop_zxtune_xfs
loop_zxtune_ym
loop_zxtune_zx_spectrum
loop_wildmidi
loop_uade
loop_xmp
loop_vgmstream

# Timer stop
timer_stop=$(date +%s)

# End
end_functions

exit
