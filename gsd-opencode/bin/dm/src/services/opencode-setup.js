import fs from 'fs/promises';
import path from 'path';

const GSD_AGENT_NAMES = [
  'gsd-code-reviewer',
  'gsd-codebase-mapper',
  'gsd-database-reviewer',
  'gsd-debugger',
  'gsd-executor',
  'gsd-go-reviewer',
  'gsd-integration-checker',
  'gsd-nyquist-auditor',
  'gsd-phase-researcher',
  'gsd-plan-checker',
  'gsd-planner',
  'gsd-project-researcher',
  'gsd-python-reviewer',
  'gsd-research-synthesizer',
  'gsd-roadmapper',
  'gsd-security-reviewer',
  'gsd-verifier'
];

const DEFAULT_STANDARD_MODEL = 'openai/gpt-5.3-codex-spark';

function toPosix(value) {
  return value.split(path.sep).join('/');
}

function buildPermissionPattern(targetDir) {
  return `${toPosix(path.join(targetDir, 'get-shit-done'))}/**`;
}

function buildDefaultAgentMappings() {
  return Object.fromEntries(GSD_AGENT_NAMES.map((name) => [name, { model: DEFAULT_STANDARD_MODEL }]));
}

export async function setupOpencodeDefaults(targetDir, options = {}) {
  const overwriteAgents = options.overwriteAgents === true;
  const opencodePath = path.join(targetDir, 'opencode.json');
  const permissionPattern = buildPermissionPattern(targetDir);

  let existing = {};
  try {
    existing = JSON.parse(await fs.readFile(opencodePath, 'utf-8'));
  } catch (error) {
    if (error.code !== 'ENOENT') {
      throw new Error(`Failed to read ${opencodePath}: ${error.message}`);
    }
  }

  const next = {
    ...existing,
    $schema: existing.$schema || 'https://opencode.ai/config.json',
    agent: { ...(existing.agent || {}) },
    permission: {
      ...(existing.permission || {}),
      external_directory: {
        ...((existing.permission && existing.permission.external_directory) || {})
      }
    }
  };

  for (const [name, config] of Object.entries(buildDefaultAgentMappings())) {
    if (overwriteAgents || !next.agent[name]) {
      next.agent[name] = config;
    }
  }

  next.permission.external_directory[permissionPattern] = 'allow';

  const before = JSON.stringify(existing);
  const after = JSON.stringify(next, null, 2) + '\n';
  const changed = before !== JSON.stringify(next);

  if (changed) {
    await fs.mkdir(targetDir, { recursive: true });
    await fs.writeFile(opencodePath, after, 'utf-8');
  }

  return {
    changed,
    opencodePath,
    permissionPattern,
    configuredAgents: GSD_AGENT_NAMES.length
  };
}

export { GSD_AGENT_NAMES, buildDefaultAgentMappings, buildPermissionPattern };
