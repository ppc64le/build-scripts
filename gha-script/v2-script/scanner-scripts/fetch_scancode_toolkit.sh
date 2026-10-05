#!/bin/bash -e

SCANCODE_VERSION="v32.4.0"
MAX_ATTEMPTS=3
RETRY_DELAY=10

echo "---------- Fetching scancode-toolkit $SCANCODE_VERSION ----------"

for attempt in $(seq 1 $MAX_ATTEMPTS); do
  echo "[INFO] Clone attempt $attempt of $MAX_ATTEMPTS..."
  if git clone https://github.com/nexB/scancode-toolkit.git; then
    echo "[INFO] Clone successful."
    break
  fi
  echo "[WARN] Clone attempt $attempt failed."
  if [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
    echo "[INFO] Retrying in ${RETRY_DELAY}s..."
    sleep $RETRY_DELAY
    rm -rf scancode-toolkit
  else
    echo "[ERROR] Failed to clone scancode-toolkit after $MAX_ATTEMPTS attempts."
    exit 1
  fi
done

cd scancode-toolkit
git checkout $SCANCODE_VERSION
echo "[INFO] Checked out $SCANCODE_VERSION."
cd ..

echo "---------- Archiving scancode-toolkit source ----------"
tar -czf scancode-toolkit-src.tar.gz scancode-toolkit/
echo "[INFO] Archive created: scancode-toolkit-src.tar.gz"
ls -lh scancode-toolkit-src.tar.gz
