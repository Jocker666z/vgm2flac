# vgm2flac - Bash tool for vgm encoding to flac

## Install & update

`curl https://raw.githubusercontent.com/Jocker666z/vgm2flac/main/vgm2flac.sh > /home/$USER/.local/bin/vgm2flac && chmod +rx /home/$USER/.local/bin/vgm2flac`

### Dependencies
`ffmpeg sox bc bchunk xxd info68 sc68 uade vgm2wav vgmstream_cli vgm_tag zxtune123`

All these dependencies must installed properly on the system.

* ffmpeg must be compiled with: --enable-libgme --enable-libopenmpt --enable-nonfree
* sc68 & info68:
	* https://sourceforge.net/projects/sc68/
	* Prefered version: https://github.com/Jocker666z/sc68
* vgm2wav: https://github.com/ValleyBell/libvgm
* vgmstream_cli: https://github.com/losnoco/vgmstream
* vgmtag: https://github.com/vgmrips/vgmtools
* zxtune:
	* https://zxtune.bitbucket.io/
	* Prefered version: zxtune_r4880 https://github.com/Jocker666z/vgm2flac-dep
* uade: https://gitlab.com/uade-music-player/uade

Help is available at the bottom of the page for the installation of dependencies that are generally not present on the official repositories of the largest GNU/Linux distributions.

## Use & description
Simply launch vgm2flac command in directory with vgm files supported.

* If possible, encoding is done in parallel.
* If available, the tags are always implemented in the final file.
* Final flac is always in 16bits with best compression level (ffmpeg option: -compression_level 12 -sample_fmt s16)
* Encoding loop order:
	* vgm encoding in wav file
	* peak normalisation to 0db & false stereo detection
	* apply fade out if necessary
	* remove audio silence at start & end
	* wav encoding in flac file

## Files supported :
* 3DO : aif
* Amiga: aam, cust, dw, gmc, mdat, mod, sa, sb
* Atari: snd, sndh
* Fujitsu FM-7, FM Towns: s98
* Microsoft Xbox: aix, mus, sfd, xwav
* Microsoft Xbox 360: wem
* NEC PC-6001, PC-6601, PC-8801, PC-9801: s98
* ~~NEC PC-Engine/TurboGrafx-16: hes~~
* Nintendo 3DS: mus, bcstm, wem, bcwav, fsb
* Nintendo DS: 2sf, adx, mini2sf, sad
* Nintendo GB & GBC: gbs
* Nintendo GBA: gsf, minigsf
* Nintendo GameCube: adx, cfn, dsp, hps, adp, thp, mus
* Nintendo N64: usf, miniusf
* Nintendo NES: nsf, ~~nsfe~~
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
* Sony Playstation 3: aa3, adx, at3, genh, laac, msf, mtaf, sgd, ss2, vag, xvag, txtp wem
* Sony Playstation 4: wem
* Sony PSP: at3
* Panasonic 3DO: aifc, str
* PC: fsb, his, imc
* Various machines: vgm, vgz, adx, rak, tak, eam, at3, raw, wem, pcm
* Various machines CD-DA: bin, bin/cue, iso/cue

The crossed out files are not available for the moment.

## Known error
* zxtune123 in version higher than r4880 do a backend error
* usf/miniusf decoding stuck = zxtune123 bug

## Holy reading
* GBS spec: https://ocremix.org/info/GBS_Format_Specification
* NSF spec: https://wiki.nesdev.com/w/index.php/NSF
* SPC spec: https://ocremix.org/info/SPC_Format_Specification
* PSF spec: https://gist.githubusercontent.com/SaxxonPike/a0b47f8579aad703b842001b24d40c00/raw/a6fa28b44fb598b8874923dbffe932459f6a61b9/psf_format.txt
* http://loveemu.hatenablog.com/entry/Conversion_Tools_for_Video_Game_Music

## Help for dependencies installation:
### sc68 & info68
Build dependencies: `git build-essential autoconf libtool libtool-bin automake pkg-config libao-dev zlib1g-dev`
```
cd
git clone https://github.com/Jocker666z/sc68 && cd sc68
tools/svn-bootstrap.sh && ./configure LDFLAGS="-static"
make -j"$(nproc)"
su -c "make install" -m "root"
```

### vgm2wav
Build dependencies: `git build-essential cmake zlib1g-dev libao-dev libdbus-1-dev`
```
git clone https://github.com/ValleyBell/libvgm && cd libvgm
mkdir build && cd build && cmake .. 
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
wget https://github.com/Jocker666z/vgm2flac-dep/raw/main/zxtune123_r4880.tar.bz2
tar -xf zxtune123_r4880.tar.bz2 && rm zxtune123_r4880.tar.bz2
```
