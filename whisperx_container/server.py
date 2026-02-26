import os
import signal
import warnings
warnings.filterwarnings('ignore')
os.environ['PYTHONWARNINGS'] = 'ignore'

import torch
import whisperx
from fastapi import FastAPI, UploadFile, HTTPException
import uvicorn

torch.backends.cuda.matmul.allow_tf32 = True
torch.backends.cudnn.allow_tf32 = True

app = FastAPI()

ai_engine = None

print('API Server is UP. Engine is COLD. Listening on Port 11400.')

@app.post('/start')
def start_engine():
    global ai_engine
    if ai_engine is not None:
        return {'status': 'success', 'message': 'Engine is already hot.'}
    
    print('Command received: Booting AI Engine to VRAM...')
    ai_engine = whisperx.load_model('medium', 'cuda', compute_type='float16')
    print('Engine is HOT and ready.')
    return {'status': 'success', 'message': 'Engine is hot and ready.'}

@app.post('/stop')
def stop_engine():
    print('Command received: Hard stopping engine. Restarting container...')
    # Send a polite SIGTERM to the current Uvicorn process
    os.kill(os.getpid(), signal.SIGTERM)
    return {'status': 'success', 'message': 'Server rebooting. VRAM flushing.'}

@app.post('/transcribe')
async def transcribe_api(file: UploadFile):
    global ai_engine
    if ai_engine is None:
        raise HTTPException(status_code=400, detail='Engine is cold. Send POST to /start first.')
        
    temp_path = f'/tmp/{file.filename}'
    with open(temp_path, 'wb') as f:
        f.write(await file.read())
        
    audio = whisperx.load_audio(temp_path)
    result = ai_engine.transcribe(audio, batch_size=8, language='en')
    
    os.remove(temp_path)
    return result

if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=11400)
