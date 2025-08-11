# camera_server.py
import socket 
import struct
import numpy as np
import cv2

HOST, PORT = "0.0.0.0", 9999

def recvall(sock, n):
    data = bytearray()
    while len(data) < n:
        pkt = sock.recv(n - len(data))
        if not pkt:
            return None
        data.extend(pkt)
    return data

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((HOST, PORT))
    s.listen(1)
    print(f"[Video] Listening on {HOST}:{PORT}")
    conn, addr = s.accept()
    print(f"[Video] Connected by {addr}")

    with conn:
        while True:
            # 4-byte big-endian length header
            raw_len = recvall(conn, 4)
            if not raw_len:
                break
            (frame_len,) = struct.unpack(">I", raw_len)
            frame = recvall(conn, frame_len)
            if frame is None:
                break

            img = cv2.imdecode(np.frombuffer(frame, dtype=np.uint8), cv2.IMREAD_COLOR)
            if img is None:
                continue

            cv2.imshow("iPhone Camera", img)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

cv2.destroyAllWindows()

