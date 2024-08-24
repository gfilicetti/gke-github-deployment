# Copyright 2024 Google LLC All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# FROM python:3.11-slim
FROM intel/intel-optimized-ffmpeg:avx2

ENV MEDIA=media.mp4

RUN apt update \ 
    && apt install -y --no-install-recommends util-linux curl mediainfo python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /app

WORKDIR /app

# Allow statements and log messages to immediately appear in the Knative logs
ENV PYTHONUNBUFFERED True

# ENV vars should be passed in when starting container
ENV INPUT_BUCKET=""


COPY src /app/

# Install production dependencies.
RUN pip install --no-cache-dir -r requirements.txt

COPY ./src/entrypoint-api.sh /app/entrypoint-api.sh

EXPOSE 8080

# Start the application with Uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]