# Changelog
v0.31:
* add - option --agressive_rm_silent, set agressive mode for remove silent 85db->58db
* fix - --pal argument
* fix - improve clean duplicate; now FLAC files removed if wav is duplicate
* fix - target directory name regression

v0.30:
* add - now validate wav is active if --no_flac option selected
* add - option --no_remove_duplicate, for force no remove duplicate files
* add - if target directory exist add date +%s after dir name
* add - in end summary, now display the number of files which are in mono and on which the normalization has been applied
* chg - better display of duplicate file, display: who is equal to whom & who is removed
* fix - various minors display fix

v0.29a:
* fix - in vgmstream multi-tracks loop, no more fail flac encoding
* fix - in vgmstream multi-tracks loop, correction of the start of the tracks

v0.29:
* fix - if --no_normalization selected, test false stereo is now done
* chg - no more ffmpeg command call, if peak db normalization & false stereo convert needed
* add - in sox loop, add loop number, sample rate & channels question
* add - in sox loop, now test file before launch loop
* add - force default fade out option --fade_out

v0.28:
* chg - improve read
* fix - replace which by command -v - Debian is deprecated which (https://salsa.debian.org/debian/debianutils/-/commit/3a8dd10b4502f7bae8fc6973c13ce23fc9da7efb)

v0.27b:
* fix - remove bash debug in spc loop
* fix - vgmstream_cli no more duplicate FLAC encoding if various extension in current directory

v0.27:
* chg - now cache folder is /tmp/vgm2flac, on systems where tmp is in tmpfs, which reduces disk writes (https://wiki.archlinux.org/title/Tmpfs)
* chg - split ffmmpeg spc/xa function
* chg - .mod files now use vgmstream for decoding
* chg - move bchunk in optional dependency
* fix - wav in error display
* fix - ffmpeg xa, spc encoding message to user
* fix - excluse .mod from uade loop, consider file extension is at end of files there is a probability that it is not an amiga file, files are left to vgmstream

v0.26:
* add - flav & wav duplicate test
* add - print at start, current PWD & loop used by script
* add - a standard view mode, print title, and a message at each conversion 
* add - -v|--verbose in argument for ffmpeg in info mode (vervose mode become old display mode)
* add - summary at end of encoding
* chg - improve final test files
* chg - ffmpeg default vervose is quiet
* chg - improve bash code
* chg - improve ay files loop
* chg - ay files, now use ffprobe for get tag
* fix - xxs_default_max_duration variable
* fix - tag date empty, if it was entered manually
* fix - flac_force_pal_tempo
* fix - ay files, if "/" in tag title, no more rename fail
* fix - ay files, now start seq by 0
* remove - vgmstream_force_looping
* remove - dead code

v0.25:
* fix regression in normalization
* chg improve of bash code
* fix vgmstream, add case insensitive for txth & txtp test
* add vgmstream, ignore multitrack with txtp files
* add vgmstream, vgmstream_loops variable, default is 1

v0.24:
* fix now if wav not valid, no more error appear in sox loop
* chg now flac validation is do with double check for prevent false positive. check 1: no soxi error, check 2: maximum amplitude must > 0
* fix redirection of various no blocking error to null
* chg now the normalization is only applied to files that have a value lower than the default

v0.23:
* add vgmstream force end-to-end looping with variable vgmstream_force_looping
* add --no_flac in cmd argument
* fix if nsf/m3u have no fading, wav extract now work

v0.22:
* fix regression, date now record in flac
* fix xfs tag, the presence of a line break does not make the title tag disappear anymore
* chg flac track tag now support until 999 tracks with lead zero
* fix if SNES spc have no timing tag (or not an integer), now default duration is set
* fix SNES spc no more use silence detection remove function
* chg still increase precision for remove silence function
* chg silence remove in middle of track desactivate for now
* add arguments variables: --no_fade_out, --no_normalization, --no_remove_silence

v0.21:
* add nsf/gb/hes with m3u, now remove "\" in m3u files
* chg merge nsf/gbs/hes tag loop
* fix now end function, activated only if final flac loop started
* add option for reduce tempo to simulate 50hz, can be activated with arguments variables -p/--pal
* add arguments variables
* chg increase precision for remove silence at end
* add nsfplay to dependency
* chg nsfplay now decode nsf files
* add support of Nintendo NES files in: nsfe

v0.20:
* chg massive bash syntax fixes
* add optimize hes & gbs loop
* add in script option for set number or loop for sid files, value must be 1 or 2
* fix gbs & nsf tag hexdump now done, even if no m3u file
* add fade out in vgmstream loop, if his files present
* chg improvement of the flac directory name
* chg improvement of the tag album
* chg xfs files now tag question before encoding

v0.19:
* fix miss target file for flac validation
* fix false positive hexa in NSF & GBS m3u
* fix multiple error in NSF/m3u & GBS/m3u loop
* add support of NEC PC-Engine/TurboGrafx-16 files in: hes (with or without m3u) (ffmpeg+libgme decode)
* chg Nintendo Game Boy files (gbs) now decode by ffmpeg+libgme

v0.18:
* add support of Nintendo DS files in minincsf, ncsf. Need zxtune r4990 for decode.
* fix zxtune loop, now filename with quote converted (random filename output trick)
* chg re-enable vgmstream parallel encoding
* add flac validation and message to user if corrupted (at end of processing)
* fix tag machine for file in minipsf & minipsf2

v0.17:
* fix vgmstream double function launch
* chg Atari ST files now loop 2 times
* add support of vgmstream files contains multi stream
* add now exit if munt rom path variable is empty
* add now exit if munt rom path variable is not a directory
* add warning if fluidsynth soundfont variable is empty
* add now exit if fluidsynth soundfont variable is not a file
* add some quality option in variable at start of script
* add sid file now have 2 loops if duration > 15s
* fix amiga subtrack counter
* fix exclude wav & flac from vgmstream loop
* fix exclude files already converted from vgmstream loop
* add peak db value in variable at start of script
* chg peak db value to -1db, to prevent audio saturation

v0.16:
* add support of PC (adlib) files in: imf, wlf (id Music Format)
* add question to user for choice number of loop made by fluidsynth, 1 ou 2
* add tag for PC sound module (example: Adlib) in album and directory name
* fix Amiga - separation of the main loop, in this loop all files are tested which can lead to a double encoding (example: mod file)
* chg get Amiga file list simplification
* fix if the amiga file names have an extension, the renaming is now correct
* chg now vgmstream loop no longer takes file extensions into account, but tests them all
* chg in documentation list of file supported become list of files tested

v0.15:
* add soundfont parameter fluidsynth_soundfont="" has to be filled in at the beginning of the script
* add support of PC, Vita, PS4 files in: sab (CRI HCA, Square-Enix SAB)
* add support of munt emulator as Roland MT-32 decoder, for midi files.
* chg fluidsynth now loop 2 times
* add vgm_tag install help in readme

v0.14:
* add support of CD-DA files in: img/cue
* add support of PlayStation Vita file in: at9 (ATRAC9, Adaptive Transform Acoustic Coding 9)
* add support of Switch file in: hca (CRI HCA), kno (Opus, Koei Tecmo KTSS), lopus (Opus, Nintendo Switch OPUS), bgm (Opus, Nintendo Switch OPUS)
* add support of Mobile file in: acb (CRI HCA)
* add support of Philips CD-i file in: grn (CD-ROM XA 8-bit ADPCM, Sony XA)
* add support of PS3 file in: idmsf, msadpcm (MPEG Layer III Audio)
* add support of Amstrad CPC and ZX Spectrum file in: ay (AY-3-8910 audio chips)
* fix ufs, miniufs, add fadout if track not timed
* fix remove ufs, miniufs unused code

v0.13:
* add support of Nintendo Switch file in: bwav (Nintendo DSP 4-bit ADPCM, Nintendo BWAV)
* add now if no tag input, default tag is "unknown"
* fix tag_song for xfs, spc, vgm, vgz, s98 files
* fix no threat inplace flac if no wav
* fix now use vgmstream_cli for decode tak (sox fail)
* fix uade123 --scan false positive, add another scan with -g option

v0.12:
* add support of GameCube file in: adp (Nintendo DTK 4-bit ADPCM, Nintendo ADP raw), rsf (CCITT G.721 4-bit ADPCM, Retro Studios RSF)
* add support of Xbox 360 file in: xwb (Xbox Media Audio 2, Microsoft XWB)
* fix env bin by add export PATH=$PATH:/home/$USER/.local/bin
* fix mkdir when tag_date contain "/"
* chg uade scan file command by uade123 --scan "$PWD"

v0.11:
* add support of PS2 files in: mpf (EALayer3, Electronic Arts SCHl) 
* add support of PC files in: mod (PC ProTracker MOD), bnk (Custom Vorbis, Audiokinetic Wwise RIFF), smk (Smacker audio, RAD Game Tools SMACKER)
* add support of Wii files in: brstm
* add support of Switch files in: lopus
* add support of Xbox 360, PC files in: bik (Bink Audio, RAD Game Tools Bink)
* fix tag_song no regen
* fix xa file type, remove fixed -ar for CD-i xa

v0.10:
* add fluidsynth in dependencies for decode midi files
* add support of PC files in: logg, mid
* fix mkdir when tag_machine contain "/"
* now check bin inside decoding loop, in order to be able to use the script even if not all dependencies are installed
* add check core dependencies at start

v0.09:
* add adplay in dependencies for decode PC adlib files
* add support of PC adlib files in: hsq, sdb, sqx

v0.08:
* add support of Amstrad CPC and Atari ST files in: ym
* add support of ZX Spectrum files in: asc, psc, pt2, pt3, sqt, stc, stp 

v0.07:
* amiga - fix find files
* support of Commodore C64/128 files: sid
* readme - various update
* flac:
	* fix remove silence at start & end
	* now remove silence in middle fo files if > 5s
* various - now impossible to launch encoding function if no files in associate array

v0.06:
* support of amiga files: aam, core, cust, dw, gmc, mdat, mod, sa, sb
* add check install of uade123 bin
* support of PS3 file = txtp

v0.05:
* amiga - implementation start
* gbs, nsf, sc68 - minor fix total_sub_track variable
* gbs - fix get title from m3u
* gbs, nfs:
	* check/convert if track number in hexa
	* extract tag from m3u one time (outside from wav loop)
	* now parallel encoding, with a modern processor the encoding time is now ridiculous
* xfs - remove double get tag in loop
* vgm, vgz, s98 - now parallel encoding, with a modern processor the encoding time is now ridiculous
* readme, add description of conversion loop

v0.04:
* gbs, nsf - multiple fix with get tag separator ","
* gbs - remove gbsplay from dependencies, now use zxtune for decoding
* add LICENCE file GNU/GPL v2
* big readme update

v0.03:
* gbs - fix get tag duration fading if "," in title
* gbs - fix false stereo detection
* support of NES files = nfs (with or without m3u)

v0.02:
* improve tags loops, especialy for artist
* support of PS1 files = pfs, minipfs
* support of PS2 files=  pfs2, minipfs2
* support of Dreamcast files= dfs
* support of GBA files = gfs, minigfs
* support of N64 files = ufs, miniufs
* support of NDS files = 2fs, mini2fs

v0.01:
* support of iso files in = bin|iso
* support of SNES files in = spc
* support of PS1 files in = xa
* support of Atari ST files in = snd|sndh
* support of RAW PCM files in = bin|pcm|raw|tak
* support of game boy files in = gbs (with or without m3u)
* support of various console files in = s98|vgm|vgz
* support of various console files in = aa3|adp|adpcm|ads|adx|aif|aifc|aix|ast|at3|bcstm|bcwav|bfstm|bfwav|cfn|dsp|eam|fsb|genh|his|hps|imc|int|laac|ktss|msf|mtaf|mib|mus|rak|raw|sad|sfd|sgd|sng|spsd|str|ss2|thp|vag|vgs|vpk|wem|xvag|xwav
