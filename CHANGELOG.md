# Changelog
v0.06
* support of files amiga : aam, cust, dw, gmc, mdat, mod, sa, sb
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
