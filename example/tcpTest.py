# tcp_server.py
import socket

HOST = "0.0.0.0"   # listen on all interfaces
PORT = 8888        # match this on iPhone

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((HOST, PORT))
    s.listen(1)
    print(f"[Server] Listening on {HOST}:{PORT}")
    conn, addr = s.accept()
    print(f"[Server] Connected by {addr}")
    with conn:
        while True:
            data = conn.recv(4096)
            if not data:
                print("[Server] Client closed connection")
                break
            print("[Server] Received:", data.decode(errors="ignore"))
            # (optional) echo back
            conn.sendall(b"OK\n")

