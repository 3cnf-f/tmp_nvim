adduser creates folders and all
```
adduser podamanis
```

enable linger
```
loginctl enable-linger podamanis
```


*fail2ban*
```
apt install fail2ban -y &&\
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local &&\
systemctl enable fail2ban &&\
systemctl start fail2ban
```

*disable passwd login*
```
PasswordAuthentication no
PubkeyAuthentication yes
sudo sshd -t
sudo systemctl restart ssh
```
```
```
