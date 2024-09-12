# Copyright 2024 Google LLC All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os, sys
import logging
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.responses import StreamingResponse, JSONResponse
import io
import json
import requests
from typing import List


logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    stream=sys.stdout,
)


tags_metadata = [
    {
        "name": "ffmpeg-api",
        "description": "ffmpeg-api rest requests",
    },
    {
        "name": "ffmpeg-event",
        "description": "ffmpeg-event to receive events from eventarc + pub/sub",
    },
]


app = FastAPI(
    docs_url='/ffmpeg-api_docs',
    redoc_url=None,
    title="Rest  APIs",
    description="Core APIs for the a ffmpeg transcoding using GKE + eventarc or Rest",
    version="0.2.0",
    license_info={
        "name": "Apache 2.0",
        "url": "https://www.apache.org/licenses/LICENSE-2.0.html",
    },
    openapi_tags=tags_metadata,
)


INPUT_BUCKET    = os.environ['INPUT_BUCKET']

headers = {"Content-Type": "application/json"}

class Payload_FileTranscode(BaseModel):
    file: str
    transcode_mode: str | None = "cpu"

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "file": "sample-file.mp4",
                    "transcode_mode": "cpu",
                }
            ]
        }
    }

# Routes
@app.get("/_healthz", include_in_schema=False)
async def health_check():
    return {'status': 'ok'}

@app.post("/ffmpeg-api", tags=["ffmpeg-api"])
def ffmpeg_api(payload: Payload_FileTranscode):
    try:
        request_payload = {
            'file': payload.file,
            'transcode_mode': payload.transcode_mode,
        }
        logging.debug(f'request_payload: {request_payload}')
        return os.popen(f'export MEDIA={payload.file} && export TRANSCODE_MODE={payload.transcode_mode} && if ls -l /input/$MEDIA; then ./entrypoint-api.sh; else echo "$MEDIA not found"; fi').read() 
    
    except Exception as e:
        logging.debug(f'At /ffmpeg-api. {e}')
        return JSONResponse(
            status_code=400,
            content={ 'status': 'excepction calling endpoint'}
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=7777)
