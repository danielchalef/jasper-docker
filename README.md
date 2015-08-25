# jasper-docker
##### An armhf Docker image for Jasper, the open source platform for developing always-on, voice-controlled applications

> **NOTE** This Dockerfile builds an Ubuntu 15.04 armhf image optimized for the Raspberry Pi 2

> **IMPORTANT** Please read the configuration instructions carefully, and view the Jasper website for further information: http://jasperproject.github.io/documentation/installation/

##### How to use this Dockerfile

###### Just pull the image from Docker Hub
The easiest and fastest way to get Jasper is to download a prebuilt image:
```docker pull danielchalef/armhf-ubuntu-core```

###### Or compile your own image as follows:
```bash
$ git clone https://github.com/danielchalef/jasper-docker.git
$ cd jasper-docker
$ docker build -t jasper-docker .
```
###### and then run the image:
Jasper needs access to your sound devices, which requires sharing the host's devices with your docker container. See **Gotchas** below on how to determine the correct devices for your setup.
```bash
$ docker run -ti --privileged -v /dev/snd/pcmC0D0p:/dev/snd/pcmC0D0p \
      -v /dev/snd/pcmC1D0c:/dev/snd/pcmC1D0c \
      -v /dev/snd/controlC0:/dev/snd/controlC0 \
      -v /dev/snd/controlC1:/dev/snd/controlC1 \
      danielchalef/armhf-jasper-docker /bin/bash
```
You will need to configure Jasper per the Jasper website. This includes running `client/populate.py` and setting your TTS and STT configurations (see below).

###### Using this image for your own app
If you'd like to use this image as a base for your own Jasper-based apps, make the first line of your custom Dockerfile:
```
FROM danielchalef/jasper-docker:latest
```

##### Why Ubuntu?
I favor Ubuntu over Raspian as:
- packages are typically newer 
- and many of the interesting scientific and math  tools for machine learning, computer vision, and speech to text are available as deb packages and do not require compilation from source.

If you're interested in using an Ubuntu 15.04 Core armhf docker image for your own apps, you can pull mine by:

```docker pull danielchalef/armhf-ubuntu-core```

##### Compilation
Where source code has been compiled, the `gcc` optimization flags `-mtune=cortex-a7 -mfpu=neon-vfpv4` have been used. If you intend on using this Dockerfile for armhf devices other than the Raspberry Pi 2, you will need modify these flags accordingly.

##### Text to Speech, and Speech to Text Configuration
Dependencies for Google TTS and STT have been installed. If you'd like to use other services / apps, please see the Jasper website for required dependencies and configuration. *Importantly, since you're using Ubuntu, you should be able to find many of the dependencies are already available as deb packages and will not need to manually compile them from source.*

##### Things that tripped me up, and may do the same to you
Getting Jasper using the right sound devices was a real PITA. 

To get TTS working (if Jasper is silent), you may need to change the ALSA device Jasper uses for TTS. Unfortunately this can only be done by modifying the source code:

File `client/tts.py` line number `76`

```python
cmd = ['aplay', '-D', 'plughw:0,0', str(filename)]
```

