// MongoDB first-boot initialisation for the single-VM production deployment.
//
// This file is a TEMPLATE and contains no secret. scripts/app-vm-deploy.sh
// substitutes __MONGO_PASSWORD__ and __MONGO_DB__ with the SOPS-decrypted
// password and the configured database name, then writes the rendered file to
// the VM, where Compose mounts it into /docker-entrypoint-initdb.d/.
//
// The database name must match DB_NAME, which the API uses — a mismatch leaves
// the user authenticated but unauthorized on the database the API actually
// writes to ("not authorized on <db> to execute command").
//
// Runs once, on first boot of an empty data directory.

db = db.getSiblingDB('admin');

db.createUser({
  user: 'readtracker',
  pwd: '__MONGO_PASSWORD__',
  roles: [{ role: 'readWrite', db: '__MONGO_DB__' }],
});