#Tefutefu for LINE
Tefutefu is a LINE bot with LINE BOT API.  
  
#Requirements
* dmd(latest)
* dub(latest)
  
#Installation
##1. Clone this repository

```zsh
$ git clone https://github.com/alphakai/tefutefu4line
```

##2. Configure your keys

You must configure your keys in source/app.d at first:

```d
botkeys keys = botkeys(
                  "your channel id",
                  "your channel secret",
                  "your mid"
                );
```

##3. Place ssl certifications
You can use `Let's Encrypt`'s certifications.  
Please place these files with named as:  

* fullchain: fullchain.pem  
* chain: chain.pem  
* private key: privkey.pem  

##4. Port Opening
Tefutefu for LINE use `4567` port for listening a connection from LINE.  
If you want to run on Linux you can open the port by:

```zsh
$ sudo iptables -A INPUT -p tcp -m tcp --dport 4567 -j ACCEPT
```

Installation has been finished.  

##5. Make directory for resource files
```zsh
$ mkdir resource
```

##Run
```d
$ dub
```

#License
MIT License. See the `LICENSE` file for details.
