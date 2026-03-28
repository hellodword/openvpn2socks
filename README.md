# openvpn2socks

Ported from:

- https://github.com/ValdikSS/openvpn-tunpipe
- https://github.com/bendlas/openvpn-tuna

## Usage

```shell
nix run .#tunsocks -- /path/to/foo.ovpn

curl --proxy socks5h://127.0.0.1:10080 https://cloudflare.com/cdn-cgi/trace -v
```
