// The one-time database setup. Invoked once by the postgres module when the database
// is made: it signs in as the master user, with the password the platform keeps, and
// makes the app's own database and the user the app signs in as with its own identity
// (IAM database authentication). It is the only thing that ever reads the master
// password. Running it again changes nothing: everything it makes is checked first.
//
// Input (from the module, as JSON): { secret_arn, host, port, database, user }.
// Output: { database, user, made: [what was made this time] }.
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const { Client } = require("pg");

// The platform's own certificate bundle, packaged with this function by build.sh, so
// the connection is checked and never just encrypted.
const CA = fs.readFileSync(path.join(__dirname, "rds-ca.pem"));

const wait = ms => new Promise(resolve => setTimeout(resolve, ms));

// The role's permission to read the secret is granted moments before the first call,
// and can take a few seconds to be seen.
async function masterPassword(secretArn) {
  const secrets = new SecretsManagerClient({});
  let lastError;
  for (let attempt = 1; attempt <= 6; attempt++) {
    try {
      const { SecretString } = await secrets.send(new GetSecretValueCommand({ SecretId: secretArn }));
      const { username, password } = JSON.parse(SecretString);
      return { username, password };
    } catch (error) {
      lastError = error;
      if (error.name !== "AccessDeniedException") throw error;
      await wait(5000);
    }
  }
  throw lastError;
}

// A name the module made: lowercase letters, digits and underscores only, so it can be
// quoted as an identifier and read back from the catalog.
function identifier(name) {
  if (!/^[a-z][a-z0-9_]{0,62}$/.test(name)) throw new Error(`not a name this setup makes: ${JSON.stringify(name)}`);
  return `"${name}"`;
}

exports.handler = async event => {
  const { secret_arn: secretArn, host, port, database, user } = event;
  for (const [name, value] of Object.entries({ secret_arn: secretArn, host, port, database, user })) {
    if (value === undefined || value === null || value === "") throw new Error(`the input has no ${name}`);
  }
  const db = identifier(database);
  const role = identifier(user);
  const master = await masterPassword(secretArn);
  const client = new Client({
    host,
    port,
    database: "postgres",
    user: master.username,
    password: master.password,
    ssl: { ca: CA, rejectUnauthorized: true },
    connectionTimeoutMillis: 20000
  });
  await client.connect();
  const made = [];
  try {
    const roles = await client.query("select 1 from pg_roles where rolname = $1", [user]);
    if (roles.rowCount === 0) {
      await client.query(`create role ${role} with login`);
      made.push("user");
    }
    // Signing in with the app's own identity needs this role; it is given in any case.
    await client.query(`grant rds_iam to ${role}`);
    // The master user makes the database on the app's behalf, so the app's user owns it:
    // to do that it has to be a member of that user.
    await client.query(`grant ${role} to ${identifier(master.username)}`);
    const databases = await client.query("select 1 from pg_database where datname = $1", [database]);
    if (databases.rowCount === 0) {
      await client.query(`create database ${db} owner ${role}`);
      made.push("database");
    } else {
      await client.query(`alter database ${db} owner to ${role}`);
    }
    return { database, user, made };
  } finally {
    await client.end();
  }
};
