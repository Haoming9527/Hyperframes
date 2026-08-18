# Executive Summary

**CodeBuddy** is a VS Code–integrated AI coding assistant with a layered, event-driven architecture. It runs locally (or via CodeBuddy CLI), using a central Orchestrator event bus to decouple components, and employs a LangGraph-based multi-agent system (a “Developer” agent plus specialized subagents for tasks like code review, testing, etc.). CodeBuddy emphasizes extensibility through **Model Context Protocol (MCP)**–compatible tools and “skills” definitions, allowing it to hook into external services (GitHub, Jira, AWS, databases, etc.). It supports both cloud LLM APIs and fully local models (e.g. Ollama) via a configurable `models.json`. Security is enforced via in-process permission profiles, tool blocklists, and a “credential proxy” that intercepts API keys. CodeBuddy is optimized for individual developers and small teams; it provides tools for diff-based editing with human review, “self-healing” execution (auto-correcting on build/test failures), and real-time streaming output.  

**Devin Desktop** (formerly Windsurf) is a full “agent management IDE” that orchestrates both local and cloud agents. Its core is an **Agent Command Center** (a Kanban-style dashboard) that coordinates work across multiple sessions and agents. Devin ships with a built-in **“Devin Local”** agent harness (same codebase as the standalone Devin CLI) that runs on the developer’s machine with OS-level sandboxing and fine-grained permission controls. Importantly, Devin Desktop also integrates a cloud-based agent (“Devin”) that spins up in Cognition’s infrastructure to handle long-running tasks. Devin is open to third-party agents via the **Agent Client Protocol (ACP)**: any ACP-compatible agent (e.g. Codex CLI, Claude, OpenCode, Gemini) can run inside Devin Desktop. This flexibility means teams can mix multiple agent types under one interface. Devin provides rich UX features (full IDE with syntax highlighting and debugging, context-sharing *Spaces*, Slack/Git integration, etc.), and enterprise-grade governance (SSO, RBAC, FedRAMP-ready security). However, Devin’s model integration is mostly through its cloud LLM service (with shared quota) and ACP extensions; local model support is indirect (via ACP or on-device agent). 

In summary, **CodeBuddy** is a powerful local/CLI assistant for in-IDE coding tasks, with very rich multi-agent tooling and “skills” integration. **Devin Desktop** excels in agent orchestration and governance: it unifies local and cloud agents, supports multiple agent frameworks (ACP), and offers advanced CI/PR integration and admin controls. The two differ philosophically: CodeBuddy is an *extension-driven, microservice-style toolset* for developers, whereas Devin Desktop is a *platform for managing teams of agents*, scaling tasks across local and cloud. The sections below compare them across architecture, autonomy, security, integration, and other dimensions in detail.

| **Dimension**                | **CodeBuddy**                                                                                                                                                  | **Devin Desktop**                                                                                                                                                                                                                                               |
|------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Core Architecture**        | Local VS Code extension (and CLI) with an **event-driven, layered architecture**. A singleton **Orchestrator** bus routes events between UI, agent services, and tools.  All processing happens on the developer’s machine (or via CLI). Data (chat logs, memory, embeddings) are stored under `.codebuddy/` (SQLite, JSON).  | Integrated IDE (VS Code or Electron) with a built-in **Agent Command Center**. Combines local and cloud components: a local “Devin Local” agent harness, UI features (Spaces, Kanban board), and optional cloud agents running on Cognition’s servers. State (sessions, settings) is synced with Cognition’s backend; code remains local.  |
| **Agent Orchestration**      | **Multi-agent system** via LangGraph DeepAgents. A “Developer” agent coordinates subtasks and spawns specialized subagents (Code Analyzer, Tester, Reviewer, etc.). Concurrency is managed by a priority queue limiting simultaneous agents.  Agents call built-in tools autonomously, streaming outputs to the UI. No built-in UI dashboard for multiple sessions (each session is a VS Code editor tab or CLI process).  | **Centralized agent management**. The Agent Command Center (ACC) shows all running sessions as cards on a board. Agents (local and cloud) are tracked by status (Running, Blocked, Done). Users can spawn *multiple agents* in parallel on tasks, and group them via **Spaces** which share context. Devin Local can spawn its own subagents (preview feature). The ACC lets users hand off tasks to cloud agents (spin up remote VMs for Devin) and see inter-session progress.  |
| **Agent Autonomy**           | **High autonomy with guardrails.** Agents can execute file edits, terminal commands, web searches, etc., without human prompts, but destructive actions (e.g. deletes) trigger user confirmation. On failures (build/test errors), CodeBuddy does “self-healing” by analyzing errors and retrying corrections automatically. Agents have strict limits (tokens, time, tool calls) enforced by `AgentSafetyGuard`.  There is also an “Ask Mode” (no writes) for human-guided QA.  | **Policy-driven autonomy.** Devin Local runs in sandboxed mode by default (permissions disabled until explicitly allowed). It uses a *fine-grained permission system* (Deny/Ask/Allow rules on file read/write, commands, network, MCP tools). By default, any risky action (including MCP calls) prompts the user. A “Plan” mode is provided where Devin writes a plan (persisted to a markdown file) but does no automated edits until approved. The cloud Devin agent is fully autonomous: once you `/handoff` work, it runs end-to-end (debugging, testing, deployments) on a separate VM, but you must manually review/merge its output.  |
| **Sandboxing / Isolation**   | **No OS sandbox.** CodeBuddy runs with the same privileges as the user’s VS Code process. Isolation is logical: permissions and tools filters. There is no container or OS-level sandbox; network and FS access are unrestricted unless explicitly blocked in permission profiles.  | **Built-in OS-level sandbox.** Devin Local enforces filesystem and network restrictions by default. Writable FS paths are only those granted by permission rules; other paths appear hidden to the agent. Network access is limited by domain allow/deny lists. Enterprise policies can force sandboxing for all users. Cloud Devin runs on isolated VMs managed by Cognition (no code runs on the user’s PC for cloud tasks).  |
| **Security / Permissions**   | **Configurable permission profiles.** Users define JSON-based permission profiles in `.codebuddy/permissions.json`, specifying tool blocklists and dangerous command patterns (e.g. disallowing `rm -rf`). The system enforces limit/cap on commands (max commands, loops) via `AgentSafetyGuard`. Sensitive keys and credentials go in VS Code’s SecretStorage (OS keychain). CodeBuddy also offers a credential-proxy that intercepts model API calls to inject session tokens securely. No built-in RBAC: all settings are per-user or per-project.  | **Rule-based authorization + RBAC.** Devin Local uses Deny/Ask/Allow rules on actions (file read/write, shell commands, HTTP, MCP). For example, `Deny Write(**/*.secret)` could block writes to private keys. Users can grant session-level or permanent approvals from the UI. MCP tools require user approval by default; admins may default-allow trusted tools. Devin Desktop (cloud service) supports enterprise RBAC: admins define roles (Admin, User, custom) with fine-grained rights (e.g. create service keys, manage SSO). Workspaces can be put into “Restricted Mode” (no agents allowed) if needed. All credentials in Devin (cloud API keys, tokens) can be centrally managed and encrypted by the platform.  |
| **MCP vs ACP (Tooling)**     | **MCP-native integration.** CodeBuddy has built-in support for the Model Context Protocol (MCP) – an *open standard for tool servers*. Users can run many MCP servers locally or via Docker Gateway; CodeBuddy auto-discovers tools and presents them as LangChain-compatible tools to agents. There are 17 preconfigured MCP connectors (GitHub, Slack, Postgres, Kubernetes, etc.) built-in, plus user-defined skills. MCP servers run as child processes or Docker, with circuit-breakers and retries to isolate failures.  | **ACP (Agent Client Protocol) support.** Devin Desktop uses the Agent Client Protocol to run *third-party agents* (not its own tools). Any ACP-compatible agent (e.g. OpenAI’s Codex CLI, Anthropic’s Claude CLI, etc.) can be plugged in. Users add agents via a registry (`~/.windsurf/acp/registry.json`). When active, Devin simply delegates the entire conversation turn to the external agent (no VScode-level tools). Devin also supports a form of MCP for internal skills (see *MCP Marketplace* in Devin docs), but its “tooling” is largely handled either by the local agent or by external ACP agents. In short, CodeBuddy’s strength is deep **MCP Tool integration**, whereas Devin’s is broad **ACP Agent integration**.  |
| **Agent SDKs & Extensibility** | **Highly extensible via “Skills” and plugins.** Developers can write custom *skills* as markdown (`SKILL.md`) under `.codebuddy/skills/` or `~/.codebuddy/skills/`. Skills declare new actions or domain knowledge for agents. CodeBuddy also supports custom *subagents* (users can define sub-agent profiles with JSON). In effect, one can embed new toolkits by writing MCP servers or NodeJS/Python scripts. A CLI (`codebuddy`) is available, and an API exists (the extension itself exposes commands to VS Code). CodeBuddy’s entire system is open (MIT-licensed), so it can be forked or extended.  | **Extensible via ACP and Plugins.** Devin allows third-party *ACP agents* (as above) and a plugin architecture. Devin Desktop plugins (called “agent plugins”) can bundle skills, hooks, MCP servers and subagents for the Devin agent. The docs mention a plugin marketplace and let teams share agent configurations. Users can also define new subagents by writing `agents/<name>/AGENT.md` files (similar to CodeBuddy). The built-in Devin Local agent harness has a plugin system (via `~/.devin/config.json` for MCP configs and plugins). Devin’s SDK efforts are mostly around ACP for making new agents; direct “SDK” for the local agent isn’t public, but the CLI and config files serve a similar purpose.  |
| **CLI / API**               | **Full-featured CLI.** CodeBuddy provides a `codebuddy` CLI tool. You can start an interactive REPL (`codebuddy`), send a query in one shot (`codebuddy -p "explain this code"`), continue a session (`codebuddy -c`), or attach to background jobs (`codebuddy ps/logs/attach`). The CLI can also manage MCP servers (`codebuddy mcp`), list agents (`codebuddy agents`), and configure settings. CodeBuddy has a credential proxy and can be run as a daemon service. An HTTP SDK is implicit via the CLI/extension.  | **Devin CLI (`devin`).** Devin offers a local CLI agent (Devin CLI) that behaves like a REPL and can leverage cloud handoff. The CLI understands slash-commands for agent control (e.g. `/handoff` to send work to cloud Devin, `/mode`, etc.). Devin CLI installation also provides hooks to integrate with the Agent Command Center via the local registry. For third-party agent integration, users edit a JSON registry file (ACP). For model integration, Devin uses cloud APIs (no public model API) and incorporates OIDC/SSO for enterprise. Overall, CodeBuddy’s CLI is focused on local session control, whereas Devin’s CLI emphasizes hybrid local/cloud workflows. 
| **Model Integration**        | **Multi-provider support, local and cloud.** CodeBuddy’s `models.json` allows adding any LLM that speaks the OpenAI-compatible HTTP API. It ships preconfigured with providers (OpenAI, Google, Anthropic, Groq, Zhipu, and a Docker runner) and even a local Ollama model. Users store API keys in SecretStorage and can switch models on the fly. Fallback to alternate providers is automatic on failures. Cloud models (e.g. GPT-4o, Claude, Google Gemini) and on-prem GPUs (via Docker model runner or Ollama) are both supported. The unified model factory handles batching and streaming token-by-token.  | **Cloud-centric with some local options.** Devin Local uses Cognition’s own cloud LLM (discounted rate with quotas) by default, with prompt caching to reduce token use. It does not directly support plugging in local LLM endpoints in the client. However, ACP agents could be custom-wrapped local models if someone builds an ACP agent around them. Devin Desktop also integrates with OCI/OIDC for cloud authentication of model calls. The cloud Devin sessions use Cognition’s servers for inference. In practice, all heavy inference goes to the cloud; local Devin only uses built-in models via the cloud or basic chain-of-thought. Thus, CodeBuddy gives the user explicit control over provider endpoints (even offline models), whereas Devin relies on Cognition’s backend for model serving. 
| **CI/CD & PR Workflows**     | **Integrated GitOps tools.** CodeBuddy includes Git/MCP connectors and PR reviewers. For example, it can create branches/issues from GitHub/GitLab/Jira, and a “Review Pull Request” command inspects diffs using AI. In CI/CD, one can script the CLI to auto-comment on PRs or generate tests. (Example: a GitHub Action could run `codebuddy -p "Review these changes"` on the diff.) CodeBuddy’s `auto-mode` can run continuously on commits. It can also generate commit messages and documentation, fitting into CI pipelines.  | **Git and cloud automation.** Devin Desktop tightly integrates with GitHub/GitLab via OAuth, letting agents open PRs and comment on code. A common pattern is `/handoff` from local to cloud Devin, which then creates/updates a PR on the repository (the Devin web app or GitHub UI shows results). Devin Cloud sessions appear in GitHub as pull requests that developers can review in-place. For CI, teams can invoke `devin` CLI commands in pipelines (e.g. running tests or generating reports). Slack/MS Teams integrations allow agents to triage CI failures or QA tasks. Because Devin has an enterprise API (service keys) and build logs (ACUs usage), it can be wired into Jenkins or Actions for auditing. In summary, CodeBuddy provides CLI hooks for CI scripts, while Devin offers dedicated slash-commands and Git-integrated workflows. 

<script>
// Mermaid diagrams
</script>

```mermaid
flowchart LR
    subgraph VSCode/Local Machine
      Dev[Developer]
      CBE[CodeBuddy Extension/CLI]
      Orch[Orchestrator (event bus)]
      Dev --> CBE
      CBE --> Orch
      subgraph CodeBuddy_System
        AgentDev[Developer Agent] 
        SubAgents[(CodeAnalyzer,\nDocWriter, Debugger,\nTester, etc.)]
        Tools{{Built-in Tools}}
        LLMs[LLM Providers (OpenAI,\nGemini, Ollama, etc.)]
        MCP[MCP Tool Servers]
        AgentDev --> SubAgents
        AgentDev --> Tools
        AgentDev --> LLMs
        AgentDev --> MCP
        SubAgents --> Tools
        Tools --> DevFS[(File System)]
        Tools --> Shell[(Terminal)]
        Tools --> Web[{Web / Search}]
      end
      Orch --> AgentDev
      subgraph Data & Context
        Workspace[Workspace (.codebuddy/*, VSCode)]
        OrchestratorStorage((SQLite, Keys))
        Orch --> OrchestratorStorage
        Workspace --> Orch
      end
      Tools --- Workspace
    end
```

```mermaid
flowchart TB
    subgraph Developer Machine
      User[Developer]
      DevinDesktop(Devin Desktop IDE)
      User --> DevinDesktop
    end
    subgraph LocalAgents
      DevLocal[Devin Local Agent]
      Cascade[Cascade Agent]
      ACPagents(ACP Agents)
      DevLocal --> DevinDesktop
      Cascade --> DevinDesktop
      ACPagents --> DevinDesktop
    end
    subgraph AgentCommandCenter
      ACC[Agent Command Center]
      Spaces[Spaces (context pods)]
      ACC --> Spaces
      Spaces --> ACC
      ACC --> LocalAgents
      ACC --> CloudAgent[Devin Cloud Agent\n(remote VM)]
    end
    subgraph CodeEditor
      Editor[IDE / Code Editor]
      Editor --> DevLocal
      Editor --> Cascade
      Editor --> ACPagents
      Editor --> ACC
    end
    subgraph Cloud
      CognitionCloud[Cloud Infrastructure (Devin)]
      CloudAgent --> CognitionCloud
      CognitionCloud --> CloudAgent
    end
```

## Sample CLI/Config Snippets

**CodeBuddy (MCP config & CLI):** CodeBuddy lets you define MCP tool servers in `settings.json`. For example, to add a Playwright MCP server:

```jsonc
// VSCode settings.json for CodeBuddy
"codebuddy.mcp.servers": {
  "playwright": {
    "command": "npx",
    "args": ["@playwright/mcp@latest"],
    "env": {}
  }
}
```
This makes the Playwright browser-automation tools available to agents. You can also run commands like:
```
$ codebuddy mcp           # Launch interactive MCP configuration
$ codebuddy agents --json # List all configured subagents in JSON
$ codebuddy -p "fix build errors"   # Run a query via CLI and exit
$ codebuddy -c                # Continue last conversation
```
Credential keys are stored securely (SecretStorage) and all API calls go through an optional credential proxy.

**Devin Desktop (ACP registry & CLI):** To use a custom local agent via ACP, edit `~/.windsurf/acp/registry.json`. For example, to register the Devin CLI agent:

```jsonc
{
  "version": "1.0.0",
  "agents": [
    {
      "id": "devin-cli",
      "name": "Devin Local",
      "version": "1.0.0",
      "description": "Devin AI coding agent via Devin CLI",
      "authors": ["Cognition AI"],
      "license": "proprietary",
      "distribution": {
        "binary": {
          "darwin-x86_64": { "cmd": "devin", "args": ["acp"] }
        }
      }
    }
  ]
}
```
After reloading, "Devin Local" appears in the agent selector. A key Devin CLI command is:
```
/handoff fix the flaky integration tests in CI
```
(as shown in the docs). This instructs Devin to package the current context and create a remote Devin session to handle the task. The terminal can display status or errors as needed.

## Security Threat Model & Mitigations

- **Threat:** *Malicious or errant agent actions* (e.g. deleting files, exfiltrating data, executing dangerous shell commands).  
  **Mitigations:** Both platforms employ permission rules. *CodeBuddy* uses JSON permission profiles (`toolBlocklist` and deny-patterns) to ban risky commands. It enforces strict caps via `AgentSafetyGuard` (e.g. max tools, loop detection). *Devin Local* uses a Deny/Ask/Allow system on file read/write, commands, HTTP, and MCP tool use. The default policy is “ask” for anything sensitive; users must approve or edit commands via the GUI. In both, session-wide grants prevent repetitive prompts. Additionally, *Credential injection*: CodeBuddy’s in-process HTTP proxy holds API keys off the LLM request URL, and Devin stores OAuth tokens securely with re-auth prompts. Admin-imposed “Restricted Mode” (Devin) or disabling agent extension (CodeBuddy) can completely disable automation in high-risk projects.

- **Threat:** *Data leakage of codebase or secrets.* An agent might upload code snippets or use unauthorized network calls.  
  **Mitigations:** Sandboxing and network filters help prevent leakage. *CodeBuddy* runs locally, so no code leaves your PC unless an external LLM is called; keys remain in SecretStorage. Devs can block Web/HTTP tools via permissions. *Devin Local* can be forced into read-only mode or network isolation by admins (domain allowlists). *Devin Cloud* transactions occur over TLS to Cognition’s servers; Cognition is FedRAMP-compliant (see Admin Guide). In all cases, **human review of agent outputs is recommended** (agents propose diffs that must be accepted), and CI pipelines should run tests on any AI-generated code. Additional mitigation: use local (offline) models in CodeBuddy (Ollama) to avoid sending code to external APIs.

- **Threat:** *Supply chain or remote code vulnerabilities.* Agents may load plugins or tools from untrusted sources.  
  **Mitigations:** CodeBuddy’s `.codebuddy/skills/` and MCP configs are in workspace or home directories under version control, so code reviews and audits apply. Developers should vet any new MCP servers or Skill scripts. *Devin’s plugins* (agent bundles) and ACP integrations should be installed only from trusted sources. Enterprise admins can restrict which third-party agents are enabled (ACP agents are locked behind Pro/Teams entitlements). Both platforms suggest using the latest secure versions: e.g. `codebuddy update` and `devin update`.

- **Threat:** *Unauthorized access to agent sessions or telemetry.*  
  **Mitigations:** Both use your OS login for authentication to local features. Devin Desktop supports SSO for enterprise accounts (via Cognition org admin). For telemetry, each platform can offer logs: CodeBuddy has an output channel and CLI `logs` command; Devin provides a cloud dashboard with audit logs (ACU usage, session history). Sensitive settings (API keys, secrets) are encrypted at rest.

## CI/CD and PR Integration Patterns

- **CodeBuddy in CI:** CodeBuddy can be scripted in build pipelines. For example, a GitHub Action could run `codebuddy -p "Run tests and report failures"` on merge, using the CLI to generate comments or failing status based on AI analysis. Its built-in **Git/PR commands** (via MCP connectors) allow creating branches or filing tickets. Teams might use the “Review Pull Request” command (manually or via CLI) to have AI annotate diffs. CodeBuddy’s `auto-mode` can enforce policies on each commit (it can auto-run linting, security checks). In practice, one integrates CodeBuddy by installing it on the build agent or using its Docker container to execute tasks, then using its outputs (logs or generated diff) to create PRs or statuses.  

- **Devin in CI:** Devin Desktop supports automated handoffs. A CI pipeline could invoke `devin acp` or the Devin CLI with `/handoff` (via an API key) to send failed-test diagnostics to a cloud Devin session. That session, once complete, will create or update a pull request on the repo (the Devin web interface shows the PR). Because Devin agents can interact with GitHub via OAuth, this PR appears as if an assistant opened it. Developers are notified via the Agent Command Center and their inbox. For example, after a failing build, a job could run:
  ```bash
  devin run --prompt "Debug and fix failing tests on branch $GITHUB_HEAD_REF"
  ```
  and Devin would fork that branch and apply fixes (the `/handoff` slash-command is one such integrated mechanism). Devin’s Slack/MS Teams bots can also post CI alerts to a channel, where an agent can be triggered to investigate. In summary, CodeBuddy augments existing CI scripts via CLI commands and connectors, while Devin’s model is to spin up its cloud agent to directly push PRs or comments into your VCS.  

In both cases, it’s best practice to *peer-review any AI-generated PRs*. Combine AI tools with existing linting, testing, and human code review. Both platforms can output results in machine-readable formats (JSON or markdown) that CI jobs can parse to set build statuses.

## Gaps, Risks & Workarounds

- **CodeBuddy:** Lacks a built-in **multi-session dashboard**; you must manage each session/tab individually. If large team collaboration is needed, rely on GitHub/GitLab connectors and external task boards. It also has less formal enterprise governance (no built-in RBAC admin portal), so enterprises must use version control and company-wide settings to enforce policies. **Workaround:** Use VS Code’s user/workspace settings to lock down models and profiles, and employ external CI checks. Another gap is *offline heavy computation* – CodeBuddy will use local resources, which may be slow. To address this, users can leverage CodeBuddy’s Docker Model Runner or powerful local GPUs (Ollama/DeepSeek) if available.  

- **Devin Desktop:** Because it’s cloud-focused, *fully offline use cases* are limited. The local Devin agent has limited model support (relying on Cognition’s backend), so if you need to use a private LLM, you must wrap it in an ACP agent yourself (which can be non-trivial). The ACP integration itself has some missing pieces – e.g. **terminal sessions** can’t be directly created by third-party agents, so ACP agents must run commands in their own environment and return results. Also, *session modes* in the ACP spec aren’t exposed in Devin’s UI, meaning custom agent “modes” must be emulated via configuration. **Workaround:** Use Devin CLI (with `/handoff`) for scenarios requiring offline work or new models. For the ACP gaps, teams have built helper wrappers or adjusted their agents to not depend on unsupported features (e.g. capture output as text rather than expecting a terminal widget). If enterprise compliance is a concern, DevOps teams should leverage Devin’s FedRAMP guide and role-based admin features to restrict actions.  

- **Performance & Scalability:** CodeBuddy performance depends on the developer’s machine; for very large codebases it may be slower. Its concurrency is limited by default (3 parallel agents) to avoid overload. For larger scale, consider running CodeBuddy’s CLI on a powerful build server or using Docker to offload tasks. Devin scales via Cognition’s cloud – you can run many cloud agents in parallel (bounded by your plan’s ACU quota), but this incurs cost and some latency. Plan for this by batching low-priority tasks or using lighter models in the cloud for faster turnaround.

Each platform continues evolving rapidly. Gaps in one may be filled by third-party tools or custom scripts. For example, if CodeBuddy lacks a particular enterprise feature, one could integrate a separate policy manager or use Git hooks. If Devin’s cloud agent is unavailable (e.g. disconnected network), continue work with the local agent and merge results later. In any case, always maintain human oversight and incremental adoption: start by using agents for small tasks (code review, docs generation) and expand as you gain confidence.

**Sources:** Official CodeBuddy documentation and GitHub source; Devin Desktop docs (local agent guide, ACP guide, etc.); Cognition’s Devin blog and changelogs. These sources provide detailed architecture descriptions, CLI/API references, and security controls used above.