FROM intel/intel-optimized-ffmpeg:avx2

ENV MEDIA=media.mp4

RUN apt update \ 
    && apt install -y --no-install-recommends util-linux curl mediainfo \
    && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/sh", "-c", "/entrypoint.sh"]