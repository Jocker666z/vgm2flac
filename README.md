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
* Nintendo DS: 2sf, adx, mini2sf, sad
* Nintendo GB & GBC: gbs
* Nintendo GBA: gsf, minigsf
* Nintendo GameCube: adx, cfn, dsp, hps, adp, thp, mus
* Nintendo N64: usf, miniusf
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
`info68 sc68 vgm2wav vgmstream_cli vgmtag zxtune123`

* gbsplay - https://github.com/mmitch/gbsplay
* info68 - https://sourceforge.net/projects/sc68/
* sc68 - https://sourceforge.net/projects/sc68/
* vgm2wav - https://github.com/ValleyBell/libvgm
* vgmstream_cli - https://github.com/losnoco/vgmstream
* vgmtag - https://github.com/vgmrips/vgmtools
* zxtune - https://zxtune.bitbucket.io/ - Prefered version zxtune_r4880

All these dependencies must install properly on the system, or the binaries (of VGM decode) present in a directory named bin in the vgm2flac directory.

--------------------------------------------------------------------------------------------------
## Known error
* zxtune123 in version higher than r4880 do a backend error
* usf/miniusf decoding stuck = zxtune bug

--------------------------------------------------------------------------------------------------
## Holy reading
* GBS spec : https://ocremix.org/info/GBS_Format_Specification
* SPC spec: https://ocremix.org/info/SPC_Format_Specification
* PSF spec: https://gist.githubusercontent.com/SaxxonPike/a0b47f8579aad703b842001b24d40c00/raw/a6fa28b44fb598b8874923dbffe932459f6a61b9/psf_format.txt
