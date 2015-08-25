# jasper-docker
##### An armhf Docker image for Jasper, the open source platform for developing always-on, voice-controlled applications

> **NOTE** This Dockerfile builds an Ubuntu 15.04 armhf image optimized for the Raspberry Pi 2

> **IMPORTANT** Please read the configuration instructions carefully, and view the Jasper website for further information: http://jasperproject.github.io/documentation/installation/

##### How to use this Dockerfile

Compile your own image as follows:
```bash
$ git clone https://github.com/danielchalef/jasper-docker.git
$ cd jasper-docker
$ docker build -t jasper-docker .
```
and then run the image:
```bash
$ docker run -ti jasper-docker /bin/bash
```
You will need to configure Jasper per the Jasper website. This includes running `client/populate.py` and setting your TTS and STT configurations (see below).

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

##### Text to Speech, and Speech to Text
Dependencies for Google TTS and STT have been installed. If you'd like to use other services / apps, please see the Jasper website for required dependencies and configuration. Importantly, since you're using Ubuntu, you 

