# WebArena-Pro

Welcome to WebArena-Pro's project repository!

## Contributing to WebArena Pro

Since all contributors currently have **read-only access** to the main repository, all code contributions must follow the standard **Fork and Pull Request** workflow.

Follow these essential steps to set up your environment and submit your code:

**1. Fork & Clone** Fork the main repository to your personal GitHub account using the GitHub UI, then clone your personal fork to your local machine:

```bash
git clone https://github.com/YOUR-USERNAME/webarena-pro.git
cd webarena-pro

```

**2. Add Upstream** Link the main McGill-NLP repository so you can easily pull future updates and keep your local environment synced:

```bash
git remote add upstream https://github.com/McGill-NLP/webarena-pro.git

```

**3. Create a Branch** Never commit directly to your `main` branch. Always create a new feature branch for your environment or bug fix:

```bash
git checkout -b feature/your-feature-name

```

**4. Push & Submit PR** Commit your changes locally, push them to your fork, and then open a Pull Request on the main McGill-NLP repository for the Integration team to review:

```bash
git push origin feature/your-feature-name

```

**5. Stay Synced** Regularly fetch and merge changes from the main repository's `main` branch before starting any new work to avoid merge conflicts:

```bash
git fetch upstream
git merge upstream/main

```

## 🌳 Recommended Workflow: Git Worktrees

If you frequently find yourself switching between branches, stashing half-finished work, or needing to test the `main` branch while in the middle of a complex feature, we highly recommend using **Git Worktrees**. 

A Git worktree allows you to check out multiple branches of this repository into entirely separate directories on your local machine. This means you can:
- **Multitask effortlessly:** Keep your local dev server running on one branch while you quickly review a PR or fix a bug in another folder.
- **Avoid context switching:** Stop relying on `git stash` and avoid the risk of losing uncommitted work when pulling updates.
- **Compare side-by-side:** Open two different branches in separate editor windows to easily compare code or run them concurrently.

**Using Worktrees in VS Code:**
Visual Studio Code has excellent built-in support for worktrees. You can create and manage them directly from the UI:
1. Go to the **Source Control** view.
2. Expand the **Source Control Repositories** section.
3. Click the **More Actions (...)** menu > **Worktrees** > **Create Worktree**.

For a full guide on how to create, open, and manage worktrees, check out the official documentation:
👉 [Working with Git Worktrees in VS Code](https://code.visualstudio.com/docs/sourcecontrol/branches-worktrees#_working-with-git-worktrees)
