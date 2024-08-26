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
        "description": "ffmeg-api",
    },
    {
        "name": "mock",
        "description": "fake ffmeg-api",
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
    # max_output_tokens: int | None = 1024
    # temperature: float | None = 0.2
    # top_p: float | None = 0.8
    # top_k: int | None = 40

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "file": "already inside the Bucket",
                    # "max_output_tokens": 1024,
                    # "temperature": 0.2,
                    # "top_p": 0.8,
                    # "top_k": 40,
                }
            ]
        }
    }

# Routes
@app.get("/_healthz", include_in_schema=False)
async def health_check():
    return {'status': 'ok'}


# @app.post("/ffmpeg-api", tags=["ffmpeg-rest"])
# def genai_text(payload: Payload_Text):
#     try:
#         request_payload = {
#             'prompt': payload.prompt,
#             'max_output_tokens': payload.max_output_tokens,
#             'temperature': payload.temperature,
#             'top_p': payload.top_p,
#             'top_k': payload.top_k,
#         }
#         response = requests.post(f'{GENAI_TEXT_ENDPOINT}', headers=headers, json=request_payload)
#         logging.debug(f'request_payload: {request_payload}')
#         return json.loads(response.content)
#     except Exception as e:
#         logging.exception(f'At /genai/text. {e}')
#         return JSONResponse(
#             status_code=400,
#             content={'status': 'exception calling endpoint'},
#         )

@app.post("/ffmpeg-api", tags=["ffmpeg-api"])
def ffmpeg_api(payload: Payload_FileTranscode):
    request_payload = {
        'file': payload.file,
        # 'from_id': payload.from_id,
        # 'to_id': payload.to_id,
        # 'debug': payload.debug
    }
    logging.debug(f'request_payload: {request_payload}')
    os.system(f'export MEDIA={payload.file} && if ls -l /input/$MEDIA; then ./entrypoint-api.sh; else echo "$MEDIA not found"; fi')
    return (f'File {request_payload} - OK')

@app.post("/ffmpeg-api-mock", tags=["mock"])
def ffmpeg_api_mock(payload: Payload_FileTranscode):
    request_payload = {
        'file': payload.file,
        # 'from_id': payload.from_id,
        # 'to_id': payload.to_id,
        # 'debug': payload.debug
    }
    logging.debug(f'request_payload: {request_payload}')
    print(request_payload)
    return (request_payload)



if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=7777)
