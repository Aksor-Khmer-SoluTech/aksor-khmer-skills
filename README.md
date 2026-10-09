# Aksor Khmer BI — Claude skills

Skills that teach Claude how to work with [Aksor Khmer BI](https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-bi),
the self-hosted Khmer document generator. With them installed, Claude can help you write and fix report templates
and run your Aksor server, following the project's own rules.

| Skill | Helps with |
|---|---|
| **aksor-templates** | Writing `.docx` / `.xlsx` / `.html` templates: placeholders, repeating rows (`{%tr %}`), totals, number and date formatting, Khmer digits, charts and images, fonts, Khmer words that split badly, filters and data sources, and calling the API to render reports. |
| **aksor-install** | Installing with `deployment.sh`, `.env` settings, upgrades, backups and restores, domain names and HTTPS, and fixing common errors (database password, ports, sign-in, image pulls). |

Claude uses them automatically when your question is about Aksor — you don't need to name them.

## Install

### Claude Code — as a plugin (recommended, easy to update)

```
/plugin marketplace add Aksor-Khmer-SoluTech/aksor-khmer-skills
/plugin install aksor@aksor-khmer-skills
```

Update later with `/plugin marketplace update aksor-khmer-skills`.

### Claude Code — by cloning

```bash
git clone https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-skills.git
cd aksor-khmer-skills
./install.sh            # copies the skills into ~/.claude/skills (all your projects)
```

`./install.sh --project /path/to/your/project` installs them into that project's `.claude/skills` instead. Run
`git pull && ./install.sh` again to update.

### Claude.ai (web and desktop)

Download `aksor-templates.zip` / `aksor-install.zip` from the
[Releases](https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-skills/releases) page and upload them under
**Settings → Capabilities → Skills**.

## Try it

- "My invoice.docx shows a blank row before every item and the Total disappears — how do I fix it?"
- "Format this amount as Khmer digits with two decimals."
- "The name ហ្វីលីព splits across two lines in my PDF."
- "I'm putting Aksor on reports.example.com behind nginx — what do I change?"
- "`./deployment.sh up` says the api container is unhealthy."

## Versions

The skills follow Aksor's releases. If something in a skill disagrees with the
[documentation](https://github.com/Aksor-Khmer-SoluTech/aksor-khmer-bi/tree/main/docs) for your version, the
documentation wins — please open an issue.

## License

MIT — see [LICENSE](LICENSE).
