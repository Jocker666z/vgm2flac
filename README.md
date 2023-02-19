# vgm2flac

Bash tool for encoding various video game music files to FLAC.

## Install & update
`curl https://raw.githubusercontent.com/Jocker666z/vgm2flac/main/vgm2flac.sh > /home/$USER/.local/bin/vgm2flac && chmod +rx /home/$USER/.local/bin/vgm2flac`

### Dependencies
`adplay asapconv bc bchunk ffmpeg ffprobe fluidsynth find info68 mednafen munt nsfplay sc68 sidplayfp sox vgm2wav vgmstream_cli vgm_tag uade xmp xxd zxtune123`

You will be able to run vgm2flac even if some dependencies are missing. The script will warn you if a dependency is not met depending on the file format to convert.

* ffmpeg must be compiled with: `--enable-libgme`
* adplay: https://github.com/adplug/adplay-unix
* asapconv: https://asap.sourceforge.net/
* fluidsynth: https://www.fluidsynth.org/
* mednafen: https://mednafen.github.io/
* munt: https://github.com/munt/munt
* nsfplay: https://github.com/bbbradsmith/nsfplay
* sc68 & info68:
	* original source: https://sourceforge.net/projects/sc68/
	* prefered version: https://github.com/Jocker666z/sc68
* sidplayfp: https://github.com/libsidplayfp/sidplayfp
* portable mdx: https://github.com/yosshin4004/portable_mdx
* uade: https://gitlab.com/uade-music-player/uade
* vgm2wav: https://github.com/ValleyBell/libvgm
* vgmstream-cli: https://github.com/losnoco/vgmstream
* vgmtag: https://github.com/vgmrips/vgmtools
* xmp: https://xmp.sourceforge.net/
* zxtune: https://zxtune.bitbucket.io/

Help is available at the bottom of the page for the installation of dependencies that are generally not present on the official repositories of the largest GNU/Linux distributions.

## Use & description
Simply launch vgm2flac command in directory with vgm files supported.

* If possible, encoding is done in parallel.
* If available, the tags are always implemented in the final file.
* FLAC default quality is: 16 bits with compression level `--best -e`
* Default decoding/encoding loop:
	* vgm encoding in WAV
	* false stereo detection (md5 channel + noise db compare)
	* apply fade out (if necessary or forced), remove audio silence (optional), peak normalisation to -1db
	* WAV encoding in FLAC
	* optional: compress to Monkes's Audio at level `-c5000`
	* optional: encoding to Opus at 256kb
	* optional: compress to WAVPACK at level `-hhx3`
	* remove duplicate files (diff)

### Arguments options
```
  --add_ape               Compress also in Monkey's Audio.
  --add_opus              Compress also in Opus at 256k.
  --add_wavpack           Compress also in WAVPACK.
  -d|--dependencies       Display dependencies status.
  -h|--help               Display this help.
  --force_fade_out        Force default fade out.
  --force_stereo          Force stereo output.
  -j|--job                Set the number of parallel jobs.
  --no_fade_out           Force no fade out.
  --no_normalization      Force no peak db normalization.
  --no_remove_duplicate   Force no remove duplicate files.
  -o|--output <dirname>   Force output directory name.
  --only_wav              Force output wav files only.
  -s|--summary_conf       Display config before begining.
  --remove_silence        Remove silence at start & end of track (85db).
  --remove_silence_more   Remove silence agressive mode (58db).
  -v|--verbose            Verbose mode
```

## Files tested
* 3DO : aif, aifc, str
* Amiga: 8svx, aam, abk, ahx, bd, bp, core, cust, dw, fc13, fc14, gmc, mcr, mdat, mod, np3, rjp, sa, sb, scumm, sfx, xm
* Amstrad CPC: ay, ym
* Atari ST: sc68, snd, sndh, ym
* Atari XL/XE: sap
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
* Nintendo SNES: spc, minisnsf, snsf
* Nintendo Switch: acb/awb, adx, bgm, bfstm, bfwav, bwav, hca, kno, ktss, lopus, wem
* Nintendo Wii: ads, adx, brstm, lwav, mus
* Sharp X68000: mdx
* Sharp X1, Turbo, Turbo Z: s98
* Sega Game Gear: vgm, vgz
* Sega Mark III/Master System: vgm, vgz
* Sega Mega Drive/Genesis: vgm, vgz
* Sega Saturn: minissf, ssf
* Sega Dreamcast: adx, dsf, spsd, str
* Sony Playstation: psf, minipsf, pona, xa, vag
* Sony Playstation 2: ads, adpcm, adx, genh, psf2, int, mib, minipsf2, ss2, sps, svag, vag, vpk, sng, vgs
* Sony Playstation 3: aa3, adx, at3, cps, genh, hca, laac, idmsf, msf, msadpcm, mtaf, sgd, ss2, vag, xvag, txtp, wem
* Sony Playstation 4: at9, sab, wem
* Sony Playstation Vita: at9, sab
* Sony PSP: at3, txtp
* Panasonic 3DO: aifc, pona, str
* Philips CD-i: grn
* PC: apc, bik, bnk, fsb, his, hvl, imc, logg, mab, mid, mod, sab, sdb, snds, smk, txtp, v2m, wem, xwb
* PC AdLib: adl, amd, bam, cff, cmf, d00, ddt, dtm, got, hsc, hsq, imf, ksm, laa, mdi, rad, rol, sdb, sqx, wlf, xms
* Various machines: vgm, vgz
* Various machines CD-DA: bin, bin/cue, img/cue, iso/cue
* ZX Spectrum: asc, ay, psc, pt2, pt3, sqt, stc, stp

## Midi files
### fluidsynth
If you want to use a specific soundfont the parameter `fluidsynth_soundfont=""` has to be filled in at the beginning of the script.

Recommended soundfonts:
* Arachno SoundFont - https://www.arachnosoft.com/main/soundfont.php
* Roland MT-32 - https://www.hedsound.com/2019/06/mt32-cm64l-sf2-for-everyone.html
* Roland SC-55 (EmperorGrieferus version) - https://drive.google.com/file/d/1G53wKnIBMONgOVx0gCOWrBlJaXsyaKml/view
* Sound Blaster 16 - https://github.com/Mindwerks/opl3-soundfont
* SGM-V2.01 (Shan's GM soundfont) - https://archive.org/details/SGM-V2.01
* Tyroland (Yamaha Tyros 4 + the JV-1010 Soundfont) - https://musical-artifacts.com/artifacts/1305
* WeedsGM3 (Rich ¥Weeds¥ Nagel's soundfont) - https://github.com/octylFractal/MidiEditor/raw/master/WeedsGM3.sf2
### munt
If you want to use munt Roland MT-32 emulator as decoder, you must filled parameter `munt_rom_path=""` with the ROM path of MT-32.

## Commodore 64 files
For use correct track duration, you have 2 solutions:
* In vgm2flac script file, filled parameter `hvsc_directory=""` with the C64Music path (https://hvsc.c64.org/downloads).
* In sidplayfp config file `/home/$USER/.config/sidplayfp/sidplayfp.ini` filled parameter `Songlength Database =`, with Songlengths text file.

In most cases the music is converted without problems, but you may need to add the Kernal, BASIC, and Chargen ROM files to the configuration file of sidplayfp.
These files are available here https://github.com/Jocker666z/vgm2flac-dep/raw/main/C64-ROM.tar.bz2

## snsf files
Here the conversion is highly experimental, it is done while reading the file, this is the only way I found to do it. So you will have to be patient.

## Known error
* unrepeatable usf/miniusf decoding stuck = zxtune123 bug

## Notable sites, source of audio files
* Atari ST: http://sndh.atari.org/
* Atari XL/XE: https://asma.atari.org/
* Commodore 64: https://hvsc.c64.org/
* Music from keygens, cracks, trainers, intros: http://www.keygenmusic.net/
* Various VGM: https://vgmrips.net/

## Holy reading
* https://wiki.archlinux.org/index.php/FluidSynth
* http://loveemu.hatenablog.com/entry/Conversion_Tools_for_Video_Game_Music
* http://www.vgmpf.com/
* https://vgmrips.net/wiki/Main_Page
* https://github.com/Sembiance/dexvert/blob/master/SUPPORTED.md

## Files specification
* GBS  https://ocremix.org/info/GBS_Format_Specification
* GSF  https://www.caitsith2.com/gsf/gsf%20spec.txt
* HES  http://www.purose.net/befis/download/nezplug/hesspec.txt
* KSS  https://ocremix.org/info/KSS_Format_Specification
* MDX  https://github.com/vampirefrog/mdxtools/blob/master/docs/MDX.md
* NSF  https://wiki.nesdev.org/w/index.php/NSF
* NSFe https://wiki.nesdev.org/w/index.php/NSFe
* SGC  https://ocremix.org/info/SGC_Format_Specification
* SAP  https://asap.sourceforge.net/sap-format.html
* SID  https://ocremix.org/info/SID_Format_Specification
* SC68 http://sc68.atari.org/developers_fileformat.html
* SNSF https://snsf.caitsith2.net/snsf%20spec.txt
* SPC  https://ocremix.org/info/SPC_Format_Specification
* PSF  https://gist.githubusercontent.com/SaxxonPike/a0b47f8579aad703b842001b24d40c00/raw/a6fa28b44fb598b8874923dbffe932459f6a61b9/psf_format.txt

## Dependencies installation:
### asap
Build dependencies: `wget build-essential`
```
wget https://sourceforge.net/projects/asap/files/asap/5.2.0/asap-5.2.0.tar.gz/download -O asap-5.2.0.tar.gz
tar -xf asap-5.2.0.tar.gz
cd asap-5.2.0
make -j"$(nproc)"
su -c "make install" -m "root"
```

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

### mednafen
Build dependencies: `git build-essential pkg-config libasound2-dev libcdio-dev libsdl1.2-dev libsndfile1-dev zlib1g-dev`
```
git clone https://github.com/libretro-mirrors/mednafen-git && cd mednafen-git
./configure && make -j"$(nproc)"
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

### Portable mdx
Build dependencies: `git build-essential`
```
git clone https://github.com/yosshin4004/portable_mdx
bash -c 'cd portable_mdx/examples/simple_mdx2wav && bash build.sh'
cp portable_mdx/examples/simple_mdx2wav/simple_mdx2wav /home/$USER/.local/bin/
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

### vgmstream-cli
Build dependencies: `git build-essential cmake audacious-dev libsvtav1enc1 libao-dev libopus-dev libmpg123-dev libgtk-3-dev`
```
git clone https://github.com/vgmstream/vgmstream && cd vgmstream
mkdir build && cd build && cmake .. 
make -j"$(nproc)"
su -c "make install" -m "root"
```

### uade
Build dependencies: `git build-essential sparse audacious-dev libao-dev libvorbis-dev libmpg123-dev`
```
git clone https://gitlab.com/heikkiorsila/bencodetools && cd bencodetools
./configure && make -j"$(nproc)"
su -c "make install" -m "root"
cd ..
git clone https://gitlab.com/hors/libzakalwe && cd libzakalwe
./configure && make -j"$(nproc)"
su -c "make install" -m "root"
cd ..
git clone https://gitlab.com/uade-music-player/uade && cd uade
./configure && make -j"$(nproc)"
su -c "make install" -m "root"
```

### zxtune123

```
cd /home/$USER/.local/bin/
wget https://github.com/Jocker666z/vgm2flac-dep/raw/main/zxtune123_r5020_x86_64.tar.bz2
tar -xf zxtune123_r5020_x86_64.tar.bz2 && rm zxtune123_r5020_x86_64.tar.bz2
```

## TODO
* .eup .fmb .pmb : EUPHONY Module https://github.com/gzaffin/eupmini
* .uni : MikMod Module https://github.com/Sembiance/mikmod2wav https://github.com/sezero/mikmod
