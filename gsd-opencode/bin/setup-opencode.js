#!/usr/bin/env node

import { setupOpencodeDefaults } from './dm/src/services/opencode-setup.js';

function parseArgs(argv) {
  const args = argv.slice(2);
  let targetDir = process.cwd();
  let overwriteAgents = false;

  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg === '--target-dir') {
      targetDir = args[i + 1];
      i += 1;
    } else if (arg === '--overwrite-agents') {
      overwriteAgents = true;
    }
  }

  return { targetDir, overwriteAgents };
}

async function main() {
  const { targetDir, overwriteAgents } = parseArgs(process.argv);
  const result = await setupOpencodeDefaults(targetDir, { overwriteAgents });
  process.stdout.write(JSON.stringify(result, null, 2) + '\n');
}

main().catch((error) => {
  process.stderr.write(`${error.message}\n`);
  process.exit(1);
});
