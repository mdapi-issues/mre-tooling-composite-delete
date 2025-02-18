#!/usr/bin/env node

import { readFileSync } from "node:fs";

const sobject = process.argv[2] || "flow";
const CHUNK_SIZE = 25;

const lines = readFileSync(process.stdin.fd, "utf8")
  .split(/\r?\n/)
  .filter(Boolean);

for (const ids of chunk(lines, CHUNK_SIZE)) {
  const payload = {
    allOrNone: true,
    compositeRequest: ids.map((id) => ({
      method: "DELETE",
      url: `/services/data/v63.0/tooling/sobjects/${sobject}/${id}`,
      referenceId: `${id}_reference_id`,
    })),
  };
  console.log(JSON.stringify(payload));
}

function chunk(input, size) {
  return input.reduce((arr, item, idx) => {
    return idx % size === 0
      ? [...arr, [item]]
      : [...arr.slice(0, -1), [...arr.slice(-1)[0], item]];
  }, []);
}
