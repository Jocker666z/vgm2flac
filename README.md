# vgm2flac

Bash tool for encoding various files vgm/chiptune to FLAC.

## Install & update

`curl https://raw.githubusercontent.com/Jocker666z/vgm2flac/main/vgm2flac.sh > /home/$USER/.local/bin/vgm2flac && chmod +rx /home/$USER/.local/bin/vgm2flac`

### Dependencies
`bc adplay bc bchunk ffmpeg ffprobe fluidsynth find info68 munt nsfplay sc68 sox vgm2wav vgmstream_cli vgm_tag uade xxd zxtune123`

You will be able to run the vgm2flac even if it is missing, the script will warn you if a dependency is not met.

* ffmpeg must be compiled with: --enable-libgme --enable-libopenmpt --enable-nonfree
* adplay: https://github.com/adplug/adplay-unix
* fluidsynth: https://www.fluidsynth.org/
* munt: https://github.com/munt/munt
* nsfplay: https://github.com/bbbradsmith/nsfplay
* sc68 & info68:
	* original source: https://sourceforge.net/projects/sc68/
	* prefered version: https://github.com/Jocker666z/sc68
* vgm2wav: https://github.com/ValleyBell/libvgm
* vgmstream_cli: https://github.com/losnoco/vgmstream
* vgmtag: https://github.com/vgmrips/vgmtools
* zxtune: https://zxtune.bitbucket.io/
* uade: https://gitlab.com/uade-music-player/uade

Help is available at the bottom of the page for the installation of dependencies that are generally not present on the official repositories of the largest GNU/Linux distributions.

## Use & description
Simply launch vgm2flac command in directory with vgm files supported.

* If possible, encoding is done in parallel.
* If available, the tags are always implemented in the final file.
* Final FLAC default quality is: 16 bits with best compression level
* Encoding loop order:
	* vgm encoding in wav file
	* peak normalisation to -1db & false stereo detection (md5 channel test)
	* apply fade out if necessary
	* remove audio silence at start & end
	* wav encoding in flac file

### Arguments options
* -h|--help: Display this help.
* --no_fade_out: Force no fade out.
* --no_flac: Force output wav files only.
* --no_normalization: Force no peak db normalization.
* --no_remove_silence: Force no remove silence at start & end of track.
* --pal: Force the tempo reduction to simulate 50hz.
*   -v|--verbose: Verbose mode

## Files tested
* 3DO : aif
* Amiga: 8svx, aam, bd, core, cust, dw, gmc, mcr, mdat, mod, sa, sb, scumm, sfx, xm
* Amstrad CPC: ay, ym
* Atari ST: snd, sndh, ym
* Philips CD-i: xa
* Commodore C64/128: sid
* Fujitsu FM-7, FM Towns: s98
* Microsoft Xbox: aix, mus, sndsn, sfd, xwav
* Microsoft Xbox 360: bik, wem, xwb
* Mobile: acb/awb, fsb, txtp
* NEC PC-Engine/TurboGrafx-16: hes
* Nintendo 3DS: bcstm, wem, bcwav, fsb, mus, txtp
* Nintendo DS: 2sf, adx, mini2sf, minincsf, ncsf, sad
* Nintendo GB & GBC: gbs
* Nintendo GBA: gsf, minigsf
* Nintendo GameCube: adx, cfn, dsp, hps, adp, thp, mus
* Nintendo N64: usf, miniusf
* Nintendo NES: nsf, nsfe
* Nintendo SNES: spc
* Nintendo Switch: acb/awb, adx, bgm, bfstm, bfwav, bwav, hca, kno, ktss, lopus, wem
* Nintendo Wii: ads, adx, brstm, mus
* Sega Game Gear: vgm, vgz
* Sega Mark III/Master System: vgm, vgz
* Sega Mega Drive/Genesis: vgm, vgz
* Sega Saturn: minissf, ssf
* Sega Dreamcast: adx, dsf, spsd, str
* NEC PC-6001, PC-6601, PC-8801,PC-9801, Sharp X1, Fujitsu FM-7 & FM TownsSharp X1: s98
* Sony Playstation: psf, minipsf, pona, xa, vag
* Sony Playstation 2: ads, adpcm, adx, genh, psf2, int, mib, minipsf2, ss2, sps, svag, vag, vpk, sng, vgs
* Sony Playstation 3: aa3, adx, at3, genh, laac, idmsf, msf, msadpcm, mtaf, sgd, ss2, vag, xvag, txtp, wem
* Sony Playstation 4: at9, sab, wem
* Sony PSP: at3, txtp
* Playstation Vita: at9, sab
* Panasonic 3DO: aifc, pona, str
* Philips CD-i: grn
* PC: bik, bnk, hsq, fsb, his, imc, imf, logg, mid, mod, sab, sdb, snds, smk, sqx, txtp, wem, wlf, xwb
* Various machines: vgm, vgz
* Various machines CD-DA: bin, bin/cue, img/cue, iso/cue
* ZX Spectrum: asc, ay, psc, pt2, pt3, sqt, stc, stp

## Midi files
### fluidsynth
If you want to use a specific soundfont the parameter `fluidsynth_soundfont=""` has to be filled in at the beginning of the script.

Recommended soundfonts:
* Roland MT-32 - https://www.hedsound.com/2019/06/mt32-cm64l-sf2-for-everyone.html
* Roland SC-55 (EmperorGrieferus version) - https://drive.google.com/file/d/1G53wKnIBMONgOVx0gCOWrBlJaXsyaKml/view
* Sound Blaster 16 - https://github.com/Mindwerks/opl3-soundfont
* SGM-V2.01 (Shan's GM soundfont) - https://archive.org/details/SGM-V2.01
* Tyroland (Yamaha Tyros 4 + the JV-1010 Soundfont) - https://musical-artifacts.com/artifacts/1305
* WeedsGM3 (Rich ¥Weeds¥ Nagel's soundfont) - https://github.com/octylFractal/MidiEditor/raw/master/WeedsGM3.sf2
### munt
If you want to use munt Roland MT-32 emulator as decoder, you must filled parameter `munt_rom_path=""` with the ROM path of MT-32.

## Known error
* usf/miniusf decoding stuck = zxtune123 bug

## Holy reading
* GBS spec: https://ocremix.org/info/GBS_Format_Specification
* HES spec: http://www.purose.net/befis/download/nezplug/hesspec.txt
* KSS spec: https://ocremix.org/info/KSS_Format_Specification
* NSF spec: https://wiki.nesdev.com/w/index.php/NSF
* NSFe spec: https://wiki.nesdev.com/w/index.php/NSFe
* SGC spec: https://ocremix.org/info/SGC_Format_Specification
* SPC spec: https://ocremix.org/info/SPC_Format_Specification
* PSF spec: https://gist.githubusercontent.com/SaxxonPike/a0b47f8579aad703b842001b24d40c00/raw/a6fa28b44fb598b8874923dbffe932459f6a61b9/psf_format.txt
* http://loveemu.hatenablog.com/entry/Conversion_Tools_for_Video_Game_Music
* http://www.vgmpf.com/
* https://wiki.archlinux.org/index.php/FluidSynth

## Help for dependencies installation:
### munt
Build dependencies: `git build-essential cmake libpulse-dev libasound2-dev libjack-jackd2-dev`
```
git clone https://github.com/munt/munt && cd munt
mkdir build && cd build && cmake .. 
make -j"$(nproc)"
su -c "make install" -m "root"
```
### nsfplay 
Build dependencies: `git build-essential`
```
git clone https://github.com/bbbradsmith/nsfplay && cd nsfplay/contrib
make -j"$(nproc)"
cp nsf2wav /home/$USER/.local/bin
```

### sc68 & info68
Build dependencies: `git build-essential autoconf libtool libtool-bin automake pkg-config libao-dev zlib1g-dev`
```
cd
git clone https://github.com/Jocker666z/sc68 && cd sc68
tools/svn-bootstrap.sh && ./configure LDFLAGS="-static"
make -j"$(nproc)"
su -c "make install" -m "root"
```

### vgm_tag
Build dependencies: `git build-essential`
```
git clone https://github.com/vgmrips/vgmtools && cd vgmtools
make -j"$(nproc)"
cp vgm_tag /home/$USER/.local/bin
```

### vgm2wav
Build dependencies: `git build-essential cmake zlib1g-dev libao-dev libdbus-1-dev`
```
git clone https://github.com/ValleyBell/libvgm && cd libvgm
mkdir build && cd build && cmake .. 
make -j"$(nproc)"
su -c "make install" -m "root"
```

### vgmstream_cli
Build dependencies: `git build-essential cmake audacious-dev libao-dev libvorbis-dev libmpg123-dev`
```
git clone https://github.com/losnoco/vgmstream && cd vgmstream
mkdir build && cd build && cmake .. 
make -j"$(nproc)"
su -c "make install" -m "root"
```

### uade
Build dependencies: `git build-essential udacious-dev libao-dev libvorbis-dev libmpg123-dev`
```
cd
git clone https://gitlab.com/heikkiorsila/bencodetools && cd bencodetools
./configure
make -j"$(nproc)"
su -c "make install" -m "root"
cd
git clone https://gitlab.com/uade-music-player/uade && cd uade
./configure
make -j"$(nproc)"
su -c "make install" -m "root"
```

### zxtune123

```
cd /home/$USER/.local/bin/
wget https://github.com/Jocker666z/vgm2flac-dep/raw/main/zxtune123_r4990.tar.bz2
tar -xf zxtune123_r4990.tar.bz2 && rm zxtune123_r4990.tar.bz2
```
