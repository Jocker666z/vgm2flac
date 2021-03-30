# vgm2flac

Bash tool for vgm/chiptune encoding to flac.

## Install & update

`curl https://raw.githubusercontent.com/Jocker666z/vgm2flac/main/vgm2flac.sh > /home/$USER/.local/bin/vgm2flac && chmod +rx /home/$USER/.local/bin/vgm2flac`

### Dependencies
`ffmpeg ffprobe sox bc bchunk xxd adplay fluidsynth info68 munt sc68 uade vgm2wav vgmstream_cli vgm_tag zxtune123`

All these dependencies must installed properly on the system.

* ffmpeg must be compiled with: --enable-libgme --enable-libopenmpt --enable-nonfree
* adplay: https://github.com/adplug/adplay-unix
* fluidsynth: https://www.fluidsynth.org/
* munt: https://github.com/munt/munt
* sc68 & info68:
	* https://sourceforge.net/projects/sc68/
	* Prefered version: https://github.com/Jocker666z/sc68
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
* Final flac is always in 16bits with best compression level (ffmpeg option: -compression_level 12 -sample_fmt s16)
* Encoding loop order:
	* vgm encoding in wav file
	* peak normalisation to 0db & false stereo detection (md5 channel test)
	* apply fade out if necessary
	* remove audio silence at start, end and middle if more than 5s
	* wav encoding in flac file

## Files supported :
* 3DO : aif
* Amiga: aam, core, cust, dw, gmc, mdat, mod, sa, sb
* Amstrad CPC: ay, ym
* Atari ST: snd, sndh, ym
* Philips CD-i: xa
* Commodore C64/128: sid
* Fujitsu FM-7, FM Towns: s98
* Microsoft Xbox: aix, mus, sfd, xwav
* Microsoft Xbox 360: bik, wem, xwb
* Mobile: acb, fsb, txtp
* ~~NEC PC-Engine/TurboGrafx-16: hes~~
* Nintendo 3DS: bcstm, wem, bcwav, fsb, mus, txtp
* Nintendo DS: 2sf, adx, mini2sf, sad
* Nintendo GB & GBC: gbs
* Nintendo GBA: gsf, minigsf
* Nintendo GameCube: adx, cfn, dsp, hps, adp, thp, mus
* Nintendo N64: usf, miniusf
* Nintendo NES: nsf
* Nintendo SNES: spc
* Nintendo Switch: bgm, bfstm, bfwav, bwav, hca, kno, ktss, lopus, wem
* Nintendo Wii: ads, adx, brstm, mus
* Sega Game Gear: vgm, vgz
* Sega Mark III/Master System: vgm, vgz
* Sega Mega Drive/Genesis: vgm, vgz
* Sega Saturn: minissf, ssf
* Sega Dreamcast: dsf, spsd
* NEC PC-6001, PC-6601, PC-8801,PC-9801, Sharp X1, Fujitsu FM-7 & FM TownsSharp X1: s98
* Sony Playstation: psf, minipsf, xa, vag
* Sony Playstation 2: ads, adpcm, adx, genh, psf2, int, mib, minipsf2, ss2, vag, vpk, sng, vgs
* Sony Playstation 3: aa3, adx, at3, genh, laac, idmsf, msf, msadpcm, mtaf, sgd, ss2, vag, xvag, txtp, wem
* Sony Playstation 4: sab, wem
* Sony PSP: at3, txtp
* Playstation Vita: at9, sab
* Panasonic 3DO: aifc, str
* Philips CD-i: grn
* PC: bik, bnk, hsq, fsb, his, imc, logg, mid, mod, sab, sdb, smk, sqx, txtp, xwb
* Various machines: vgm, vgz
* Various machines CD-DA: bin, bin/cue, img/cue, iso/cue
* ZX Spectrum: asc, ay, psc, pt2, pt3, sqt, stc, stp

The crossed out files are not available for the moment.

## Midi files
### fluidsynth
If you want to use a specific soundfont the parameter `fluidsynth_soundfont=""` has to be filled in at the beginning of the script.
Recommended soundfont:
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
* NSF spec: https://wiki.nesdev.com/w/index.php/NSF
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
wget https://github.com/Jocker666z/vgm2flac-dep/raw/main/zxtune123_r4980.tar.bz2
tar -xf zxtune123_r4980.tar.bz2 && rm zxtune123_r4980.tar.bz2
```
