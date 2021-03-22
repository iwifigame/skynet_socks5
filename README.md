socks5 implement by skynet.

## 1. compile
This project is depend on skynet. First must compile skynet.
```
make linux
```

## 2. usage
1. Start socks5 server:
```bash
sh reset.sh
```
It will listen on port 8555 which is configed in reset.sh file's SERVER_PORT.

2. Start socks5 client.
chrome has built in socks5 client support.
Can change chrome's shortcut property to use it:
```
"C:\Program Files\Google\Chrome\Application\chrome.exe" --proxy-server="SOCKS5://XXX.XXX.XXX.XXX:8555"
```

When just test, can use curl command:
```
curl -x socks5h://XXX.XXX.XXX.XXX:8555 http://www.baidu.com/
```

## 3. other
1. git proxy. github can use it to speedup.
```
git config --global http.proxy 'socks5://XXX.XXX.XXX.XXX:8555'
git config --global http.proxy 'socks5://XXX.XXX.XXX.XXX:8555'
```
