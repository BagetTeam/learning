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