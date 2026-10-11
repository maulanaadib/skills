<#
.SYNOPSIS
  Dev-only: symlink every skill in this repo into the agent skill directories.

.DESCRIPTION
  Intended for maintainers iterating on skills locally. Each skill becomes a
  symlink into this repo, so an edit here is immediately visible to every
  linked agent and a `git pull` is all that's needed to stay current.

  This is NOT an installer. The supported installer is `npx skills add`.
  Use this only while you are actively editing skills.

  Safety:
    - Only ADDS symlinks for skills from this repo. It never deletes entries
      it did not create, so skills from other sources are left untouched.
    - Refuses to overwrite a real directory (only replaces existing symlinks).
    - Bails if a destination is itself a symlink into this repo, which would
      otherwise write the per-skill links back into the working copy.

.PARAMETER Unlink
  Remove only the symlinks this script created. Leaves everything else alone.

.PARAMETER Agents
  Override the default agent destinations. Defaults to the .agents/skills
  readers (opencode, codex, cursor, ...) plus Claude Code.

.EXAMPLE
  .\scripts\link-skills.ps1            # link all skills into both destinations
  .\scripts\link-skills.ps1 -Unlink    # remove the links this script made
#>

[CmdletBinding()]
param(
  [switch]$Unlink,
  [string[]]$Agents = @()
)

function Resolve-LinkTarget {
  # PowerShell 5.1 does not populate .Target on symbolic links (PS 7+ only).
  # Read the raw target from the .NET API and normalise it, which works in both.
  param([Parameter(Mandatory)][string]$Path)

  $item = Get-Item $Path -Force
  if (-not $item.LinkType) { return $null }

  # .Target is null on PS 5.1, so go through the filesystem object directly.
  $raw = $item.PSObject.Properties['Target'].Value
  if ($null -eq $raw) {
    $raw = $item.BaseObject.Target
  }
  if ($null -eq $raw) { return $null }

  # A symlink target may be relative to the link's own directory.
  if ([System.IO.Path]::IsPathRooted($raw)) {
    return [System.IO.Path]::GetFullPath($raw)
  }
  return [System.IO.Path]::GetFullPath((Join-Path (Split-Path $Path -Parent) $raw))
}

$ErrorActionPreference = 'Stop'

$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if ($Agents.Count -eq 0) {
  $Agents = @(
    @{ Dir = Join-Path $env:USERPROFILE '.agents\skills';  Label = 'opencode / codex / cursor (.agents)' }
    @{ Dir = Join-Path $env:USERPROFILE '.claude\skills';  Label = 'claude-code' }
  )
}

# Collect this repo's skills: every directory holding a SKILL.md under skills/.
$skillDirs = Get-ChildItem -Path (Join-Path $Repo 'skills') -Recurse -Filter 'SKILL.md' -File -ErrorAction SilentlyContinue |
  ForEach-Object { $_.DirectoryName } |
  Sort-Object

if ($skillDirs.Count -eq 0) {
  Write-Error "No SKILL.md found under $Repo\skills. Nothing to link."
  exit 1
}

# Guard: a destination that is itself a symlink into this repo would make us
# write the per-skill links back into the working copy. Detect and bail.
foreach ($agent in $Agents) {
  $dest = $agent.Dir
  if (Test-Path $dest) {
    $item = Get-Item $dest -Force
    if ($item.LinkType) {
      $resolved = Resolve-LinkTarget -Path $dest
      if ($resolved -and ($resolved -like "$Repo*")) {
        Write-Error "$dest is a symlink into this repo. Remove it and re-run; this script will recreate it as a real directory."
        exit 1
      }
    }
  }
}

if ($Unlink) {
  foreach ($agent in $Agents) {
    $dest = $agent.Dir
    if (-not (Test-Path $dest)) { continue }
    foreach ($dir in $skillDirs) {
      $name = Split-Path $dir -Leaf
      $target = Join-Path $dest $name
      if (Test-Path $target) {
        $entry = Get-Item $target -Force
        # Only remove links that point back into THIS repo. Never touch a real
        # directory or a link to somewhere else.
        if ($entry.LinkType) {
          $resolved = Resolve-LinkTarget -Path $target
          if ($resolved -and ($resolved -like "$Repo*")) {
            Remove-Item $target -Force
            Write-Host "unlinked $name (was -> $dir)"
          }
        }
      }
    }
  }
  Write-Host "`nDone. Only symlinks pointing into this repo were removed." -ForegroundColor Green
  exit 0
}

foreach ($agent in $Agents) {
  $dest = $agent.Dir
  $label = $agent.Label

  New-Item -ItemType Directory -Force -Path $dest | Out-Null

  foreach ($dir in $skillDirs) {
    $name = Split-Path $dir -Leaf
    $target = Join-Path $dest $name

    if (Test-Path $target) {
      $entry = Get-Item $target -Force
      if (-not $entry.LinkType) {
        # A real directory already holds this name. Refuse rather than destroy it.
        Write-Warning "skipped $name at $dest : a real directory already exists there (not a symlink). Remove it yourself if you want the link instead."
        continue
      }
      $existing = Resolve-LinkTarget -Path $target
      if ($existing -eq (Resolve-Path $dir).Path) {
        Write-Host "ok      $name (already linked)"
        continue
      }
      # A symlink to somewhere else. Replace it, but say what we replaced.
      Remove-Item $target -Force
      Write-Host "relink  $name (was -> $existing)"
    }

    New-Item -ItemType SymbolicLink -Path $target -Target $dir | Out-Null
    Write-Host "linked  $name -> $dir  [$label]"
  }
}

Write-Host "`nDone. $($skillDirs.Count) skill(s) linked." -ForegroundColor Green
Write-Host "Edits in $Repo are now live in every linked agent." -ForegroundColor Green
Write-Host "To revert: .\scripts\link-skills.ps1 -Unlink" -ForegroundColor DarkGray
