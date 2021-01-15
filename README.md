# vgm2flac - Bash tool for vgm encoding to flac

Currently work in progress, not all files type below supported and script is instable.

--------------------------------------------------------------------------------------------------
## Files supported :
* 3DO : aif
* Amiga/Atari: mod, snd, sndh
* Fujitsu FM-7, FM Towns: s98
* Microsoft Xbox: aix, mus, sfd, xwav
* Microsoft Xbox 360: wem
* NEC PC-6001, PC-6601, PC-8801, PC-9801: s98
* NEC PC-Engine/TurboGrafx-16: hes
* Nintendo 3DS: mus, bcstm, wem, bcwav, fsb
* Nintendo DS: adx, mini2sf, sad
* Nintendo GB & GBC: gbs
* Nintendo GBA: minigsf
* Nintendo GameCube: adx, cfn, dsp, hps, adp, thp, mus
* Nintendo N64: miniusf
* Nintendo NES: nsf
* Nintendo SNES: spc
* Nintendo Switch: bfstm, bfwav, ktss
* Nintendo Wii: ads, mus
* Sega Mark III/Master System: vgm, vgz
* Sega Mega Drive/Genesis: vgm, vgz
* Sega Saturn: minissf, ssf
* Sega Dreamcast: dsf, spsd
* Sharp X1 : s98
* Sony Playstation: psf, minipsf, xa, vag
* Sony Playstation 2: ads, adpcm, adx, genh, psf2, int, mib, minipsf2, ss2, vag, vpk, sng, vgs
* Sony Playstation 3: aa3, adx, at3, genh, laac, msf, mtaf, sgd, ss2, vag, xvag, wem
* Sony Playstation 4: wem
* Sony PSP: at3
* Panasonic 3DO: aifc, str
* PC: fsb, his, imc, mod
* Various machines: vgm, vgz, adx, rak, tak, eam, at3, raw, wem, pcm
* Various machines CD-DA: bin, bin/cue, iso/cue

--------------------------------------------------------------------------------------------------
## Common dependencies
`ffmpeg sox bc bchunk xxd`

## VGM decode dependencies
`info68 sc68 vgm2wav vgmstream_cli vgmtag zxtune`

* gbsplay - https://github.com/mmitch/gbsplay
* info68 - https://sourceforge.net/projects/sc68/
* sc68 - https://sourceforge.net/projects/sc68/
* vgm2wav - https://github.com/ValleyBell/libvgm
* vgmstream_cli - https://github.com/losnoco/vgmstream
* vgmtag - https://github.com/vgmrips/vgmtools
* zxtune - https://zxtune.bitbucket.io/

These dependencies must install properly on the system, or the binaries present in a directory named bin in the vgm2flac directory.

--------------------------------------------------------------------------------------------------
## Holy reading
* Game Boy
	* https://ocremix.org/info/GBS_Format_Specification
* Super Nintendo
	* https://ocremix.org/info/SPC_Format_Specification
