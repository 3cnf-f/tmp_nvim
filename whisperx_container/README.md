~$ podman exec -d pt_official python /workspace/server.py

~$ curl -X POST http://localhost:11400/start
{"status":"success","message":"Engine is hot and ready."}

~$ curl -X POST -F "file=@aa.m4a" http://localhost:11400/transcribe
{"segments":[{"text":" All right, so this is my first notes I'm taking. Just to try the transcription of the Whisper X. The idea is to be able to do a lot of work like this, maybe even write patient journals this way. I don't know.","start":1.128,"end":21.8}],"language":"en"}

~$ curl -X POST http://localhost:11400/stop
{"status":"success","message":"Server rebooting. VRAM flushing."}

also don forget to run ./host_monitor on host to view cpu/gou usage/temps
