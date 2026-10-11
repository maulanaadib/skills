#!/usr/bin/env node
/**
 * Dev-only: link every skill in this repo into the local skill directories used
 * by each agent harness.
 *
 * NOTE: This is not a supported installer. The supported installer is
 * `npx skills add`. Use this only while you are actively editing skills.
 *
 *   ~/.agents/skills: opencode, codex, cursor, and other Agent Skills-compatible harnesses
 *   ~/.claude/skills: Claude Code
 *
 * Each entry is a link into this repo, so a `git pull` is all that's needed to
 * keep installed skills up to date.
 *
 * Why this exists alongside link-skills.sh: on Windows, a true symlink needs an
 * elevated shell. A directory junction does not, and Node's fs.symlinkSync with
 * type 'junction' creates one. So this script is the no-elevation path on
 * Windows, and .sh is the posix path.
 */

import { symlinkSync, lstatSync, readlinkSync, mkdirSync, rmSync, existsSync, readdirSync } from 'node:fs';
import { join, dirname, resolve, basename } from 'node:path';
import { homedir } from 'node:os';
import process from 'node:process';

// fileURLToPath handles the platform quirks (drive letters on Windows, and
// percent-encoding of spaces in paths like "New folder (2)") that break a
// naive pathname slice off import.meta.url.
import { fileURLToPath } from 'node:url';

const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '..');

const UNLINK = process.argv.includes('--unlink') || process.argv.includes('-u');

const DESTS = [
  { dir: join(homedir(), '.agents', 'skills'), label: 'opencode / codex / cursor (.agents)' },
  { dir: join(homedir(), '.claude', 'skills'), label: 'claude-code' },
];

// Collect this repo's skills: every directory holding a SKILL.md under skills/.
function collectSkills() {
  const out = [];
  const root = join(REPO, 'skills');
  if (!existsSync(root)) return out;

  const walk = (dir) => {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const p = join(dir, entry.name);
      if (entry.isDirectory()) walk(p);
      else if (entry.isFile() && entry.name === 'SKILL.md') out.push(dirname(p));
    }
  };
  walk(root);
  return out.sort();
}

// Read what an existing link points at, or null if the entry is not a link.
// lstatSync does not follow the link, so this is safe on dangling targets.
function readLinkTarget(p) {
  try {
    const st = lstatSync(p);
    if (!st.isSymbolicLink()) return null;
    return resolve(dirname(p), readlinkSync(p));
  } catch {
    return null;
  }
}

const skills = collectSkills();
if (skills.length === 0) {
  console.error(`error: no SKILL.md found under ${join(REPO, 'skills')}. Nothing to link.`);
  process.exit(1);
}

// Guard: a destination that is itself a link into this repo would make us write
// the per-skill links back into the working copy. Detect and bail.
for (const d of DESTS) {
  if (existsSync(d.dir) && readLinkTarget(d.dir)?.startsWith(REPO)) {
    console.error(`error: ${d.dir} is a link into this repo.`);
    console.error(`Remove it and re-run; this script will recreate it as a real directory.`);
    process.exit(1);
  }
}

if (UNLINK) {
  for (const d of DESTS) {
    if (!existsSync(d.dir)) continue;
    for (const src of skills) {
      const name = basename(src);
      const target = join(d.dir, name);
      if (!existsSync(target)) continue;
      // Only remove links that point back into THIS repo. Never touch a real
      // directory or a link to somewhere else.
      const t = readLinkTarget(target);
      if (t && t.startsWith(REPO)) {
        rmSync(target, { force: true });
        console.log(`unlinked ${name} (was -> ${src})`);
      }
    }
  }
  console.log('\nDone. Only links pointing into this repo were removed.');
  process.exit(0);
}

for (const d of DESTS) {
  mkdirSync(d.dir, { recursive: true });

  for (const src of skills) {
    const name = basename(src);
    const target = join(d.dir, name);

    if (existsSync(target)) {
      const linked = readLinkTarget(target);
      if (!linked) {
        // A real directory already holds this name. Refuse rather than destroy it.
        console.log(`skipped  ${name} at ${d.dir}: a real directory already exists there (not a link).`);
        continue;
      }
      if (linked === resolve(src)) {
        console.log(`ok       ${name} (already linked)`);
        continue;
      }
      rmSync(target, { force: true, recursive: true });
      console.log(`relink   ${name} (was -> ${linked})`);
    }

    // 'junction' is ignored on posix and creates a no-elevation directory
    // junction on Windows. This is the whole reason this file exists.
    symlinkSync(src, target, 'junction');
    console.log(`linked   ${name} -> ${src}  [${d.label}]`);
  }
}

console.log(`\nDone. ${skills.length} skill(s) linked.`);
console.log(`Edits in ${REPO} are now live in every linked agent.`);
console.log('To revert: node scripts/link-skills.mjs --unlink');
