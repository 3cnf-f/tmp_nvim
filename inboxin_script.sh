mkdir -p ./inbox
cp /storage/emulated/0/Alpie/INBOX/* ./inbox/
ls

cd inbox
scp *.jpg "$F_PBR_USER_IP:./silverbullet/space/tmp_dump/"
 /bin/ls *.jpg |sed 's|.*|![[tmp_dump/&]]|' > test.md
scp test.md "$F_PBR_USER_IP:./silverbullet/space/tmp_dump/"


