# Changelog
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
