/**
 * Skills Core Library
 *
 * Provides skill discovery, loading, and activation utilities.
 * Used by hooks and agents to work with the skills system.
 */

const fs = require('fs');
const path = require('path');

/**
 * Discovers all available skills from configured directories
 * @param {Object} settings - Global settings object
 * @returns {Array} Array of skill metadata objects
 */
function discoverSkills(settings) {
  const skills = [];
  const directories = settings?.skills?.directories || [];

  for (const dir of directories) {
    const resolvedDir = path.resolve(settings.basePath || process.cwd(), dir);
    if (fs.existsSync(resolvedDir)) {
      const files = fs.readdirSync(resolvedDir);
      for (const file of files) {
        if (file.endsWith('.md')) {
          const skillPath = path.join(resolvedDir, file);
          const metadata = parseSkillMetadata(skillPath);
          if (metadata) {
            skills.push({
              ...metadata,
              path: skillPath,
              category: path.basename(dir)
            });
          }
        }
      }
    }
  }

  return skills;
}

/**
 * Parses skill metadata from a skill markdown file
 * @param {string} skillPath - Path to the skill file
 * @returns {Object|null} Skill metadata or null if invalid
 */
function parseSkillMetadata(skillPath) {
  try {
    const content = fs.readFileSync(skillPath, 'utf-8');
    const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);

    if (frontmatterMatch) {
      // Parse YAML-like frontmatter
      const frontmatter = frontmatterMatch[1];
      const metadata = {};

      frontmatter.split('\n').forEach(line => {
        const [key, ...valueParts] = line.split(':');
        if (key && valueParts.length) {
          metadata[key.trim()] = valueParts.join(':').trim();
        }
      });

      return metadata;
    }

    // Fallback: extract from first heading
    const headingMatch = content.match(/^#\s+(.+)/m);
    if (headingMatch) {
      return {
        name: headingMatch[1],
        id: path.basename(skillPath, '.md')
      };
    }

    return null;
  } catch (error) {
    console.error(`Error parsing skill ${skillPath}:`, error.message);
    return null;
  }
}

/**
 * Loads skill rules from the configured rules file
 * @param {Object} settings - Global settings object
 * @returns {Object} Skill rules configuration
 */
function loadSkillRules(settings) {
  const rulesFile = settings?.skills?.rulesFile;
  if (!rulesFile) return { rules: [] };

  const rulesPath = path.resolve(settings.basePath || process.cwd(), rulesFile);

  try {
    const content = fs.readFileSync(rulesPath, 'utf-8');
    return JSON.parse(content);
  } catch (error) {
    console.error(`Error loading skill rules:`, error.message);
    return { rules: [] };
  }
}

/**
 * Matches a prompt against skill rules to find relevant skills
 * @param {string} prompt - User prompt text
 * @param {Object} rules - Skill rules configuration
 * @returns {Array} Matched skills sorted by priority
 */
function matchSkills(prompt, rules) {
  const promptLower = prompt.toLowerCase();
  const matches = [];

  for (const rule of rules.rules || []) {
    let matched = false;
    let matchReason = null;

    // Check keywords
    const keywords = rule.triggers?.keywords || [];
    for (const keyword of keywords) {
      if (promptLower.includes(keyword.toLowerCase())) {
        matched = true;
        matchReason = `keyword: "${keyword}"`;
        break;
      }
    }

    if (matched) {
      matches.push({
        ...rule,
        matchReason,
        priorityOrder: getPriorityOrder(rule.priority, rules.priorityLevels)
      });
    }
  }

  // Sort by priority
  matches.sort((a, b) => a.priorityOrder - b.priorityOrder);

  return matches;
}

/**
 * Gets numeric priority order from priority level name
 * @param {string} priority - Priority level name
 * @param {Object} levels - Priority levels configuration
 * @returns {number} Priority order (lower = higher priority)
 */
function getPriorityOrder(priority, levels) {
  return levels?.[priority]?.order || 999;
}

/**
 * Loads a skill file content
 * @param {string} skillPath - Path to the skill file
 * @returns {string|null} Skill content or null if not found
 */
function loadSkill(skillPath) {
  try {
    return fs.readFileSync(skillPath, 'utf-8');
  } catch (error) {
    console.error(`Error loading skill ${skillPath}:`, error.message);
    return null;
  }
}

module.exports = {
  discoverSkills,
  parseSkillMetadata,
  loadSkillRules,
  matchSkills,
  loadSkill,
  getPriorityOrder
};
