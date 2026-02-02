STEP 4.1 — INSTALL NODE.JS & NPM (PROPER METHOD)

We will use NodeSource (industry standard).

🔹 1️⃣ Update system
sudo apt update

🔹 2️⃣ Install required packages
sudo apt install -y ca-certificates curl gnupg

🔹 3️⃣ Add NodeSource repository (Node 20 LTS – recommended)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

🔹 4️⃣ Install Node.js (includes npm)
sudo apt install -y nodejs

🔹 5️⃣ Verify installation
node -v
npm -v

cd ~/sms_redesign
Run:

npm create vite@latest sms_frontend
Choose:

✔ React
✔ JavaScript
Then:

cd sms_frontend
npm install
npm run dev

npm run dev -- --host







