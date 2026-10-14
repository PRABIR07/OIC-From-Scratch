"""OIC from Scratch · Phase 3.3 · JWT practice tool (by @devwithprabir)

Usage:
  python3 jwt_practice.py decode  <token-file>
  python3 jwt_practice.py verify  <token-file> <secret>
  python3 jwt_practice.py tamper  <token-file> <claim> <new-value>   (writes tampered-jwt.txt)

Only for learning: real systems use a proper JWT library.
"""
import base64, hashlib, hmac, json, sys, datetime

def b64d(part):
    return base64.urlsafe_b64decode(part + "=" * (-len(part) % 4))

def b64e(raw):
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()

def load(path):
    return open(path).read().strip()

def decode(token):
    header, payload, _ = token.split(".")
    h, p = json.loads(b64d(header)), json.loads(b64d(payload))
    print("HEADER :", json.dumps(h))
    print("PAYLOAD:", json.dumps(p, indent=2))
    for k in ("iat", "exp"):
        if k in p:
            t = datetime.datetime.fromtimestamp(p[k], datetime.timezone.utc)
            print(f"{k} = {p[k]} = {t:%d %b %Y %H:%M} UTC")

def verify(token, secret):
    header, payload, sig = token.split(".")
    expected = b64e(hmac.new(secret.encode(), f"{header}.{payload}".encode(), hashlib.sha256).digest())
    if hmac.compare_digest(expected, sig):
        print("Signature VALID: nothing was changed, and it was signed with this secret.")
    else:
        print("Signature INVALID: the token was changed, or signed with a different secret.")

def tamper(token, claim, value):
    header, payload, sig = token.split(".")
    p = json.loads(b64d(payload))
    p[claim] = value
    new = f"{header}.{b64e(json.dumps(p, separators=(',', ':')).encode())}.{sig}"
    open("tampered-jwt.txt", "w").write(new)
    print(f'Changed "{claim}" to "{value}" and kept the old signature -> tampered-jwt.txt')

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(1)
    cmd, tok = sys.argv[1], load(sys.argv[2])
    if cmd == "decode": decode(tok)
    elif cmd == "verify": verify(tok, sys.argv[3])
    elif cmd == "tamper": tamper(tok, sys.argv[3], sys.argv[4])
    else: print(__doc__)
