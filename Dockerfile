FROM danielchalef/armhf-ubuntu-core:15.04
MAINTAINER Daniel Chalef <daniel.chalef@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV JASPER_HOME /opt/jasper
RUN export JASPER_HOME=$JASPER_HOME 

RUN export THREADS=`getconf _NPROCESSORS_ONLN`

RUN export CCFLAGS="-mtune=cortex-a7 -mfpu=neon-vfpv4"; export CPPFLAGS="-mtune=cortex-a7 -mfpu=neon-vfpv4"

RUN apt-get install software-properties-common
# multiverse is needed for libttspico
RUN apt-add-repository -y multiverse && apt-get update

RUN apt-get update; apt-get upgrade -y

RUN apt-get install -y \
	build-essential wget vim git-core python-dev \
	bison libasound2-dev libportaudio-dev python-pyaudio \
	apt-utils alsa-base alsa-utils alsa-oss pulseaudio \
	subversion autoconf libtool automake gfortran

RUN git clone https://github.com/jasperproject/jasper-client.git $JASPER_HOME

# Optimised apt-build config which we'll use to compile OpenBLAS
#RUN echo \
#$'build-dir = /var/cache/apt-build/build \n\
#repository-dir = /var/cache/apt-build/repository \n\
#Olevel = -O3 \n\
#mtune = -mtune=cortex-a7 \n\
#options = " " \n\
#make_options = " -j8 -mfpu=neon-vfpv4"' \
#> /etc/apt/apt-build.conf

#RUN TARGET=ARMV7 apt-build install openblas

# Build optimized OpenBLAS from source. Ensure we use armv7 target. 
# Unfortunately OpenBLAS does not yet use the cortex-a5's neon-vfpv4 instructions
RUN git clone https://github.com/xianyi/OpenBLAS.git $JASPER_HOME/OpenBLAS 
WORKDIR $JASPER_HOME/OpenBLAS
RUN git checkout v0.2.14
RUN make -j $THREADS TARGET=ARMV7 && make install
RUN echo "/opt/OpenBLAS/lib" > /etc/ld.so.conf.d/openblas.conf && ldconfig
RUN ln -s /opt/OpenBLAS/lib/libopenblas.so /usr/local/lib/libopenblas.so

WORKDIR $JASPER_HOME
# Build Python numpy. It will find OpenBLAS in /usr/local/lib and use for BLAS operations
RUN wget https://bootstrap.pypa.io/get-pip.py && /usr/bin/python get-pip.py
RUN pip install numpy

RUN echo "options snd-usb-audio index=0" >> /etc/modprobe.d/alsa-base.conf


RUN pip install -r $JASPER_HOME/client/requirements.txt
RUN chmod +x $JASPER_HOME/jasper.py

# Install PocketSphinx and Deps
RUN apt-get install -y pocketsphinx-utils

WORKDIR $JASPER_HOME

RUN svn co https://svn.code.sf.net/p/cmusphinx/code/trunk/cmuclmtk/
RUN cd cmuclmtk; sh ./autogen.sh && make -j $THREADS && make install

RUN wget http://www.openfst.org/twiki/pub/FST/FstDownload/openfst-1.5.0.tar.gz
RUN wget https://mitlm.googlecode.com/files/mitlm-0.4.1.tar.gz
RUN wget https://m2m-aligner.googlecode.com/files/m2m-aligner-1.2.tar.gz

RUN tar -xvf m2m-aligner-1.2.tar.gz
RUN tar -xvf openfst-1.5.0.tar.gz
RUN tar -xvf mitlm-0.4.1.tar.gz

WORKDIR $JASPER_HOME/openfst-1.5.0/
RUN ./configure --enable-compact-fsts --enable-const-fsts --enable-far --enable-lookahead-fsts --enable-pdt
RUN make -j $THREADS 
RUN make install && ldconfig

WORKDIR $JASPER_HOME/m2m-aligner-1.2/
RUN make -j $THREADS 

WORKDIR $JASPER_HOME/mitlm-0.4.1/
RUN ./configure
RUN make -j $THREADS

WORKDIR $JASPER_HOME
RUN wget https://github.com/danielchalef/Phonetisaurus/archive/04242015.tar.gz # rescued from github repo prior to code disappearing?!?
RUN tar -xvf 04242015.tar.gz
WORKDIR $JASPER_HOME/Phonetisaurus-04242015/src/
RUN make -j $THREADS
RUN make install && ldconfig

WORKDIR $JASPER_HOME
RUN cp m2m-aligner-1.2/m2m-aligner /usr/local/bin/m2m-aligner
#RUN cp 04242015/phonetisaurus-g2p /usr/local/bin/phonetisaurus-g2p

WORKDIR $JASPER_HOME
RUN wget https://www.dropbox.com/s/kfht75czdwucni1/g014b2b.tgz?dl=0
RUN tar -xvf g014b2b.tgz\?dl\=0 
RUN cd g014b2b/ && ./compile-fst.sh
RUN mv g014b2b phonetisaurus

# Install deps for SVOX Pico TTS engine
RUN apt-get install -y libttspico-utils
