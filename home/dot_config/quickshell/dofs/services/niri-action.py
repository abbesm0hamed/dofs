"""Focus a stable workspace id, independently of the currently focused output."""
import json
import os
import socket
import sys


def main():
    with socket.socket(socket.AF_UNIX) as client:
        client.settimeout(2)
        client.connect(os.environ["NIRI_SOCKET"])
        request = {"Action": {"FocusWorkspace": {"reference": {"Id": int(sys.argv[1])}}}}
        client.sendall(json.dumps(request).encode() + b"\n")
        with client.makefile("rb") as stream:
            reply = json.loads(stream.readline(65536))
        if "Err" in reply:
            raise RuntimeError(reply["Err"])


if __name__ == "__main__":
    main()
