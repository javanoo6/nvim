#!/usr/bin/env python3
"""
Nvim Plugin Documentation Extractor
Extracts README and documentation from GitHub repositories into a structured knowledge base.
"""

import os
import re
import json
import subprocess
from pathlib import Path
from typing import Dict, Any, Optional
import requests
from datetime import datetime

class PluginKnowledgeExtractor:
    def __init__(self, output_dir: str = "~/.local/share/nvim-kb"):
        self.output_dir = Path(output_dir).expanduser().resolve()
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.temp_dir = self.output_dir / ".temp_repos"
        self.temp_dir.mkdir(exist_ok=True)
        
    def fetch_github_readme(self, owner: str, repo: str) -> Optional[str]:
        """Fetch README from GitHub API or clone repo."""
        api_url = f"https://api.github.com/repos/{owner}/{repo}/readme"
        
        try:
            response = requests.get(api_url, timeout=10)
            if response.status_code == 200:
                import base64
                content = base64.b64decode(response.json()['content']).decode('utf-8')
                return content
        except Exception as e:
            print(f"  API failed for {owner}/{repo}: {e}, trying clone...")
        
        # Fallback to cloning
        return self._clone_and_extract(owner, repo)
    
    def _clone_and_extract(self, owner: str, repo: str) -> Optional[str]:
        """Clone repo and extract README."""
        repo_path = self.temp_dir / f"{owner}_{repo}"
        if repo_path.exists():
            readme = repo_path / "README.md"
            if readme.exists():
                return readme.read_text()
        
        try:
            cmd = [
                "git", "clone", "--depth", "1", "--no-checkout",
                f"https://github.com/{owner}/{repo}.git",
                str(repo_path)
            ]
            subprocess.run(cmd, capture_output=True, timeout=30, check=True)
            
            readme = repo_path / "README.md"
            if readme.exists():
                return readme.read_text()
        except Exception as e:
            print(f"  Error cloning {owner}/{repo}: {e}")
        return None
    
    def extract_config_schema(self, readme: str, repo_name: str) -> Dict[str, Any]:
        """Extract configuration options from README."""
        config = {
            "setup_pattern": None,
            "config_options": [],
            "keybindings": [],
            "dependencies": []
        }
        
        # Look for setup patterns
        setup_patterns = [
            r'require\(["\']([^"\']+)\).setup\s*\(\s*\{([^}]+)\}\)',
            r'vim\.config\.plugins\["([^"]+)""]\s*=\s*\{([^}]+)\}',
            r'opts\s*=\s*\{([^}]+)\}'
        ]
        
        for pattern in setup_patterns:
            matches = re.finditer(pattern, readme, re.DOTALL | re.IGNORECASE)
            for match in matches:
                config["setup_pattern"] = match.group(0)[:200]
                break
        
        # Extract key-value pairs that look like config options
        # Look for patterns like: option = value -- comment
        option_patterns = [
            r'(\w+)\s*=\s*[\"\'][^\"\']*[\"\']\s*--\s*([^\n]+)',
            r'(\w+)\s*=\s*(true|false|\d+)\s*--\s*([^\n]+)',
            r'\b(\w+)\s*:\s*[\"\'][^\"\']*[\"\']\s*,\s*--\s*([^\n]+)',
        ]
        
        for pattern in option_patterns:
            matches = re.finditer(pattern, readme)
            for match in matches:
                if len(match.groups()) >= 2:
                    config["config_options"].append({
                        "option": match.group(1),
                        "description": match.group(-1).strip()
                    })
        
        # Extract keybindings (looks for <leader>, <C->, <S->, etc.)
        kb_pattern = r'<[^>]+>\s*:\s*([^\n]+)'
        for match in re.finditer(kb_pattern, readme):
            kb = match.group(0)
            if '<leader>' in kb or '<C-' in kb or '<S-' in kb:
                config["keybindings"].append(kb[:80])
        
        return config
    
    def extract_plugin_info(self, readme: str, owner: str, repo: str) -> Dict[str, Any]:
        """Parse README and extract structured information."""
        # Extract description (first paragraph or <p> tag)
        desc_match = re.search(r'^\s*([^.\n]{20,200}[.\n])', readme, re.MULTILINE)
        description = desc_match.group(1).strip() if desc_match else "No description found"
        
        # Extract installation info
        install_section = ""
        if "## Installation" in readme:
            install_match = re.search(r'## Installation(.*?)(?:##|$)', readme, re.DOTALL)
            if install_match:
                install_section = install_match.group(1)[:500]
        
        # Extract features
        features = []
        if "## Features" in readme or "## Usage" in readme:
            feature_sections = re.findall(r'## (Features|Usage|Configuration)(.*?)(?:##|$)', readme, re.DOTALL)
            for title, content in feature_sections[:2]:  # First 2 sections
                if title == "Features":
                    bullet_points = re.findall(r'[-*]\s*([^\n]+)', content[:800])
                    features.extend(bullet_points[:5])  # Top 5 features
        
        # Extract config
        config_info = self.extract_config_schema(readme, repo)
        
        return {
            "name": repo,
            "owner": owner,
            "url": f"https://github.com/{owner}/{repo}",
            "description": description,
            "features": features,
            "config_schema": config_info,
            "installation_hint": install_section,
            "extracted_at": datetime.now().isoformat(),
            "raw_readme_path": None  # Will be filled later
        }
    
    def process_plugin(self, owner: str, repo: str) -> Dict[str, Any]:
        """Process a single plugin and save to knowledge base."""
        print(f"Processing {owner}/{repo}...")
        
        # Fetch README
        readme = self.fetch_github_readme(owner, repo)
        if not readme:
            print(f"  Failed to fetch documentation")
            return None
        
        # Save raw README
        readme_path = self.output_dir / f"{owner}_{repo}_readme.md"
        readme_path.write_text(readme)
        
        # Extract info
        info = self.extract_plugin_info(readme, owner, repo)
        if info:
            info["raw_readme_path"] = str(readme_path)
            
            # Save structured JSON
            json_path = self.output_dir / f"{owner}_{repo}.json"
            json_path.write_text(json.dumps(info, indent=2))
            
            # Save summary markdown
            self._save_summary_markdown(info, readme_path)
            
            print(f"  ✓ Saved to {self.output_dir}")
            return info
        return None
    
    def _save_summary_markdown(self, info: Dict, readme_path: Path):
        """Save a human-readable summary."""
        summary = f"""# {info['name']} by {info['owner']}

**Description**: {info['description']}

**Source**: [{info['url']}]({info['url']})  
**Extracted**: {info['extracted_at']}

## Key Features
{chr(10).join(f"- {f}" for f in info['features'][:5])}

## Configuration Schema
- Setup pattern: `{info['config_schema'].get('setup_pattern', 'N/A')[:100]}...` if available

## Raw Documentation
Full README available at: `{readme_path}`
"""
        summary_path = self.output_dir / f"{info['owner']}_{info['name']}.md"
        summary_path.write_text(summary)
    
    def update_index(self):
        """Update the index of all processed plugins."""
        index = []
        for json_file in self.output_dir.glob("*.json"):
            if "_readme" not in json_file.name:
                try:
                    data = json.loads(json_file.read_text())
                    index.append({
                        "name": data.get("name"),
                        "owner": data.get("owner"),
                        "file": json_file.name,
                        "extracted_at": data.get("extracted_at")
                    })
                except:
                    pass
        
        index_path = self.output_dir / "index.json"
        index_path.write_text(json.dumps(index, indent=2))

# Plugin list from the nvim setup
PLUGINS = [
    # Phase 1: Core Infrastructure
    ("okuuva", "auto-save.nvim"),
    ("nvim-java", "nvim-java"),
    
    # Phase 2: LSP Core
    ("neovim", "nvim-lspconfig"),
    ("williamboman", "mason.nvim"),
    ("williamboman", "mason-lspconfig.nvim"),
    ("antosha417", "nvim-lsp-file-operations"),
    ("aznhe21", "actions-preview.nvim"),
    ("rachartier", "tiny-inline-diagnostic.nvim"),
    
    # Phase 3: Completion
    ("hrsh7th", "nvim-cmp"),
    ("L3MON4D3", "LuaSnip"),
    ("onsails", "lspkind.nvim"),
]

def main():
    extractor = PluginKnowledgeExtractor()
    
    print("Nvim Plugin Knowledge Base Extractor")
    print("=" * 50)
    print(f"Output directory: {extractor.output_dir}")
    print()
    
    success_count = 0
    for owner, repo in PLUGINS:
        try:
            result = extractor.process_plugin(owner, repo)
            if result:
                success_count += 1
        except Exception as e:
            print(f"  Error processing {owner}/{repo}: {e}")
    
    extractor.update_index()
    
    print()
    print(f"Completed: {success_count}/{len(PLUGINS)} plugins processed")
    print(f"Knowledge base location: {extractor.output_dir}")

if __name__ == "__main__":
    main()
