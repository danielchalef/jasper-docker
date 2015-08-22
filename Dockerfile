FROM ubuntu:15.04
MAINTAINER Daniel Chalef <daniel.chalef@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV JASPER_HOME /opt/jasper
RUN export JASPER_HOME=$JASPER_HOME 

ENV CCFLAGS "-mtune=native"
#ENV CCFLAGS "-mtune=cortex-a7 -mfpu=neon-vfpv4"
RUN export CCFLAGS=$CCFLAGS 
RUN export CPPFLAGS=$CCFLAGS 

#COPY compile-sirius-servers.sh.patch /tmp/

RUN apt-get update; apt-get upgrade -y

RUN apt-get install -y \
	wget vim git-core python-dev python-pip \
	bison libasound2-dev libportaudio-dev python-pyaudio \
	apt-utils alsa-base alsa-utils alsa-oss pulseaudio \
	subversion autoconf libtool automake gfortran g++

RUN echo "options snd-usb-audio index=0" >> /etc/modprobe.d/alsa-base.conf

RUN git clone https://github.com/jasperproject/jasper-client.git $JASPER_HOME

RUN pip install --upgrade setuptools
RUN CCFLAGS="$CCFLAGS" CPPFLAGS="$CCFLAGS" pip install -r $JASPER_HOME/client/requirements.txt
RUN chmod +x $JASPER_HOME/jasper.py

# Install PocketSphinx and Deps
RUN apt-get install -y pocketsphinx-utils

WORKDIR $JASPER_HOME

RUN svn co https://svn.code.sf.net/p/cmusphinx/code/trunk/cmuclmtk/
RUN cd cmuclmtk; sh ./autogen.sh && make -j4 && make install

RUN wget http://distfiles.macports.org/openfst/openfst-1.3.3.tar.gz
RUN wget https://mitlm.googlecode.com/files/mitlm-0.4.1.tar.gz
RUN wget https://m2m-aligner.googlecode.com/files/m2m-aligner-1.2.tar.gz
RUN wget https://github.com/danielchalef/Phonetisaurus/archive/04242015.tar.gz # rescued from github repo prior to code disappearing?!?

RUN tar -xvf m2m-aligner-1.2.tar.gz
RUN tar -xvf openfst-1.3.3.tar.gz
RUN tar -xvf 04242015.tar.gz
RUN tar -xvf mitlm-0.4.1.tar.gz

WORKDIR $JASPER_HOME/openfst-1.3.3/
RUN sudo ./configure --enable-compact-fsts --enable-const-fsts --enable-far --enable-lookahead-fsts --enable-pdt
RUN make install

WORKDIR $JASPER_HOME/m2m-aligner-1.2/
RUN make 

WORKDIR $JASPER_HOME/mitlm-0.4.1/
RUN ./configure
RUN make

WORKDIR $JASPER_HOME/04242015/src/
RUN make

WORKDIR $JASPER_HOME
RUN cp m2m-aligner-1.2/m2m-aligner /usr/local/bin/m2m-aligner
RUN cp 04242015/phonetisaurus-g2p /usr/local/bin/phonetisaurus-g2p

RUN wget http://phonetisaurus.googlecode.com/files/g014b2b.tgz
RUN tar -xvf g014b2b.tgz
RUN cd g014b2b/ && ./compile-fst.sh
RUN mv g014b2b phonetisaurus

# Install deps for SVOX Pico TTS engine
RUN apt-get install libttspico-utils
