import os
from flask import Flask, jsonify

VERSION = os.getenv("APP_VERSION", "dev")
PORT = int(os.getenv("PORT", "8080"))

app = Flask(__name__)


@app.get("/health")
def get_health():
    return jsonify(status="ok", version=VERSION)


if __name__ == "__main__":
    print(f"vmbluegreen {VERSION} escuchando en :{PORT}", flush=True)
    app.run(host="0.0.0.0", port=PORT)